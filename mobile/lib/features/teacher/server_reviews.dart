import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:printing/printing.dart';

import '../../core/api/bacatepat_api.dart';
import 'server_teacher_tools.dart';

class ClassReport extends StatelessWidget {
  const ClassReport({super.key, required this.api, required this.path});
  final BacaTepatApi api;
  final String path;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Laporan perkembangan')),
    body: PdfPreview(
      build: (_) => api.download(path),
      canChangeOrientation: false,
      canChangePageFormat: false,
    ),
  );
}

class TeacherRecordings extends StatefulWidget {
  const TeacherRecordings({super.key, required this.api});
  final BacaTepatApi api;
  @override
  State<TeacherRecordings> createState() => _TeacherRecordingsState();
}

class _TeacherRecordingsState extends State<TeacherRecordings> {
  int page = 1;
  late Future<Map<String, dynamic>> recordings = load();
  final player = AudioPlayer();
  Future<Map<String, dynamic>> load() =>
      widget.api.request('guru/rekaman?page=$page');
  void refresh() => setState(() => recordings = load());
  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> listen(int id) async {
    try {
      await player.stop();
      final bytes = await widget.api.download('guru/rekaman/$id/audio');
      if (mounted) await player.play(BytesSource(bytes));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio tidak dapat diputar.')),
        );
      }
    }
  }

  Future<void> analysis(int id) async {
    try {
      final detail = await widget.api.request('guru/rekaman/$id');
      if (!mounted) return;
      final result = detail['data']['analisis'];
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Analisis bacaan'),
          content: Text(
            result == null
                ? 'Belum ada analisis untuk rekaman ini.'
                : result['status'] == 'succeeded'
                ? "Transkrip: ${result['transcript']}\nKemiripan indikatif: ${result['similarity_score']}%"
                : {
                        'failed': 'Transkripsi gagal. Evaluasi manual tetap tersedia.',
                        'queued': 'Menunggu worker.',
                        'running': 'Sedang ditranskripsi.',
                        'skipped': 'Analisis dilewati.',
                      }[result['status']] ??
                      result['status'],
          ),
          actions: [
            if (result?['status'] == 'failed')
              TextButton(
                onPressed: () async {
                  try {
                    await widget.api.request(
                      'guru/rekaman/$id/analisis-ulang',
                      body: {},
                    );
                    if (dialog.mounted) Navigator.pop(dialog);
                  } on ApiError catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
                child: const Text('Coba lagi'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> evaluate(Map<String, dynamic> row) async {
    final id = row['id'];
    final evaluation = row['evaluasi_id'];
    final ok = await editForm(
      context,
      evaluation == null ? 'Nilai rekaman' : 'Revisi evaluasi',
      [
        field('nilai_ketepatan', 'Ketepatan (0–100)'),
        field('nilai_kelancaran', 'Kelancaran (0–100)'),
        field('komentar', 'Komentar'),
        field('saran', 'Saran belajar'),
      ],
      (values) async {
        await widget.api.request(
          evaluation == null
              ? 'guru/rekaman/$id/evaluasi'
              : 'guru/evaluasi/$evaluation',
          method: evaluation == null ? 'POST' : 'PUT',
          body: {
            ...values,
            if (evaluation != null) 'revision': row['revision'],
          },
        );
      },
      initial: evaluation == null
          ? {}
          : {
              'nilai_ketepatan': row['accuracy_score'].toString(),
              'nilai_kelancaran': row['fluency_score'].toString(),
              'komentar': row['comment'] ?? '',
              'saran': row['advice'] ?? '',
            },
    );
    if (mounted && ok) refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rekaman siswa')),
    body: FutureBuilder(
      future: recordings,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.hasError) return Center(child: Text(state.error.toString()));
        final data = state.requireData;
        return ListView(
          children: [
            if ((data['data'] as List).isEmpty)
              const ListTile(title: Text('Belum ada rekaman.')),
            for (final row in data['data'])
              ListTile(
                title: Text(row['target_text_snapshot']),
                onTap: () => analysis(row['id']),
                subtitle: Text(row['nama'] ?? row['status']),
                leading: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Dengarkan',
                  onPressed: row['status'] == 'file_deleted'
                      ? null
                      : () => listen(row['id']),
                ),
                trailing:
                    row['status'] == 'uploaded' || row['evaluasi_id'] != null
                    ? TextButton(
                        onPressed: () => evaluate(row),
                        child: Text(
                          row['evaluasi_id'] == null ? 'Nilai' : 'Revisi',
                        ),
                      )
                    : null,
              ),
            if (page > 1)
              TextButton(
                onPressed: () {
                  page--;
                  refresh();
                },
                child: const Text('Sebelumnya'),
              ),
            if (page < data['last_page'])
              TextButton(
                onPressed: () {
                  page++;
                  refresh();
                },
                child: const Text('Berikutnya'),
              ),
          ],
        );
      },
    ),
  );
}

class ClassTestBuilder extends StatefulWidget {
  const ClassTestBuilder({super.key, required this.api, required this.classId});
  final int classId;
  final BacaTepatApi api;
  @override
  State<ClassTestBuilder> createState() => _ClassTestBuilderState();
}

class _ClassTestBuilderState extends State<ClassTestBuilder> {
  final title = TextEditingController();
  final selected = <int>{};
  int page = 1;
  int? draftId;
  bool busy = false;
  late Future<Map<String, dynamic>> questions = load();
  Future<Map<String, dynamic>> load() => widget.api.request(
    'guru/soal?page=$page&status_review=approved&penggunaan=diagnostic',
  );
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (draftId == null) {
        final response = await widget.api.request(
          'guru/diagnostik',
          body: {
            'kelas_id': widget.classId,
            'judul': title.text.trim(),
            'soal': [
              for (final entry in selected.indexed)
                {'soal_id': entry.$2, 'urutan': entry.$1 + 1},
            ],
          },
        );
        draftId = response['data']['id'];
      }
      await widget.api.request(
        'guru/diagnostik/$draftId/status',
        method: 'PATCH',
        body: {'status': 'aktif'},
      );
      if (mounted) Navigator.pop(context);
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  final aspects = <int, String>{};
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Susun tes diagnostik')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: title,
            enabled: draftId == null,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Judul tes'),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: questions,
            builder: (context, state) {
              if (state.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.hasError) {
                return Center(child: Text(state.error.toString()));
              }
              final data = state.requireData;
              return ListView(
                children: [
                  for (final q in data['data'])
                    CheckboxListTile(
                      title: Text(q['prompt']),
                      subtitle: Text(q['aspect_code']),
                      value: selected.contains(q['id']),
                      onChanged: draftId != null || busy
                          ? null
                          : (value) => setState(() {
                              if (value == true) {
                                selected.add(q['id']);
                                aspects[q['id']] = q['aspect_code'];
                              } else {
                                selected.remove(q['id']);
                                aspects.remove(q['id']);
                              }
                            }),
                    ),
                  if (page > 1)
                    TextButton(
                      onPressed: () => setState(() {
                        page--;
                        questions = load();
                      }),
                      child: const Text('Sebelumnya'),
                    ),
                  if (page < data['last_page'])
                    TextButton(
                      onPressed: () => setState(() {
                        page++;
                        questions = load();
                      }),
                      child: const Text('Berikutnya'),
                    ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          child: FilledButton(
            onPressed:
                busy ||
                    aspects.values.toSet().length < 4 ||
                    title.text.trim().isEmpty
                ? null
                : publish,
            child: Text(
              'Aktifkan tes (${aspects.values.toSet().length}/4 aspek)',
            ),
          ),
        ),
      ],
    ),
  );
}
