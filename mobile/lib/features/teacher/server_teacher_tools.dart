import 'package:flutter/material.dart';

import '../../core/api/bacatepat_api.dart';

typedef Field = ({String key, String label, List<String>? options});
Field field(String key, String label, [List<String>? options]) =>
    (key: key, label: label, options: options);

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
  Future<void> Function() run,
) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(title),
        ),
      ],
    ),
  );
  if (accepted != true) return false;
  try {
    await run();
    return true;
  } on ApiError catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }
}

/// Keep each draft open when validation fails so a teacher can correct it.
Future<bool> editForm(
  BuildContext context,
  String title,
  List<Field> fields,
  Future<void> Function(Map<String, String>) save, {
  Map<String, String> initial = const {},
}) async {
  return await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _Editor(title, fields, save, initial),
        ),
      ) ??
      false;
}

class _Editor extends StatefulWidget {
  const _Editor(this.title, this.fields, this.save, this.initial);
  final Map<String, String> initial;
  final String title;
  final List<Field> fields;
  final Future<void> Function(Map<String, String>) save;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final key = GlobalKey<FormState>();
  final values = <String, String>{};
  bool busy = false;
  String? error;
  Future<void> submit() async {
    if (!key.currentState!.validate() || busy) return;
    key.currentState!.save();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.save(values);
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final f in widget.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: f.options == null
                  ? TextFormField(
                      initialValue: widget.initial[f.key],
                      decoration: InputDecoration(labelText: f.label),
                      obscureText: f.key.startsWith('password'),
                      validator: (s) =>
                          (s ?? '').trim().isEmpty ? 'Wajib diisi' : null,
                      onSaved: (s) => values[f.key] = s!.trim(),
                    )
                  : DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: f.label),
                      initialValue: widget.initial[f.key] ?? f.options!.first,
                      items: [
                        for (final o in f.options!)
                          DropdownMenuItem(
                            value: o,
                            child: Text(o.replaceAll('_', ' ')),
                          ),
                      ],
                      onChanged: busy ? null : (_) {},
                      onSaved: (s) => values[f.key] = s!,
                    ),
            ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: busy ? null : submit,
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}

class TeacherContentPage extends StatefulWidget {
  const TeacherContentPage({
    super.key,
    required this.api,
    this.initialSection = "materi",
  });
  final String initialSection;
  final BacaTepatApi api;
  @override
  State<TeacherContentPage> createState() => _TeacherContentPageState();
}

class _TeacherContentPageState extends State<TeacherContentPage> {
  static const aspects = ['huruf', 'suku_kata', 'kata', 'kalimat'];
  late String section = widget.initialSection;
  int page = 1;
  late Future<Map<String, dynamic>> rows = load();
  Future<Map<String, dynamic>> load() =>
      widget.api.request('guru/$section?page=$page');
  void reload() => setState(() => rows = load());
  int? pendingDraft;
  String? draftStatus;

  Future<void> generate() async {
    final kind = section;
    final saved = await editForm(
      context,
      'Buat draf AI',
      [
        field('tema', 'Tema bacaan'),
        field('aspek', 'Aspek', aspects),
        field('tingkat', 'Tingkat', ['1', '2', '3']),
        field('jumlah', 'Jumlah draf', ['1', '2', '3', '4', '5']),
        if (kind == 'soal')
          field('tipe', 'Jenis soal', ['pilihan_ganda', 'baca_lisan']),
      ],
      (values) async {
        final response = await widget.api.request(
          'guru/ai/$kind',
          body: values,
        );
        pendingDraft = response['data']['id'];
        draftStatus = 'Dalam antrean';
      },
    );
    if (mounted && saved) reload();
  }

  Future<void> checkDraft() async {
    try {
      final response = await widget.api.request(
        'guru/ai/permintaan/$pendingDraft',
      );
      if (!mounted) return;
      draftStatus = {
        'succeeded': 'Draf tersedia untuk ditinjau',
        'failed': 'Pembuatan draf gagal',
        'queued': 'Dalam antrean',
      }[response['data']['status']];
      reload();
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> editContent([Map<String, dynamic>? existing]) async {
    final material = section == 'materi';
    String type = 'pilihan_ganda';
    List<Map<String, dynamic>> materials = [];
    if (!material) {
      final choice = existing != null
          ? (existing['question_type'] == 'oral_reading'
                ? 'baca_lisan'
                : 'pilihan_ganda')
          : await showDialog<String>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Jenis soal'),
                children: [
                  for (final entry in {
                    'pilihan_ganda': 'Pilihan ganda',
                    'baca_lisan': 'Baca lisan',
                  }.entries)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, entry.key),
                      child: Text(entry.value),
                    ),
                ],
              ),
            );
      if (choice == null || !mounted) return;
      type = choice;
      try {
        int next = 1;
        while (true) {
          final result = await widget.api.request('guru/materi?page=$next');
          materials.addAll(
            (result['data'] as List).cast<Map<String, dynamic>>(),
          );
          if (next >= result['last_page']) break;
          next++;
        }
      } on ApiError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
        return;
      }
      if (!mounted) return;
    }
    final saved = await editForm(
      context,
      '${existing == null ? 'Tambah' : 'Edit'} $section',
      [
        field('aspek', 'Aspek', aspects),
        field('tingkat_kesulitan', 'Tingkat', ['1', '2', '3']),
        if (material) ...[
          field('judul', 'Judul'),
          field('konten', 'Isi materi'),
        ] else ...[
          field('pertanyaan', 'Pertanyaan'),
          field('penggunaan', 'Digunakan untuk', [
            'keduanya',
            'diagnostik',
            'latihan',
          ]),
          field('materi', 'Materi terkait', [
            'Tanpa materi',
            for (final m in materials) "${m['id']} · ${m['title']}",
          ]),
          if (type == 'baca_lisan') field('teks_target', 'Teks bacaan'),
          if (type == 'pilihan_ganda')
            field('opsi', 'Opsi jawaban (pisahkan dengan |)'),
          if (type == 'pilihan_ganda') field('kunci_jawaban', 'Jawaban benar'),
        ],
      ],
      (values) async {
        final data = <String, dynamic>{...values};
        if (!material) {
          final selected = data.remove('materi') as String;
          if (selected != 'Tanpa materi') {
            final item = materials.firstWhere(
              (m) => m['id'] == int.parse(selected.split(' · ').first),
            );
            data.addAll({
              'materi_id': item['id'],
              'aspek': item['aspect_code'],
              'tingkat_kesulitan': item['level'],
            });
          }
          if (type == 'pilihan_ganda') {
            data['opsi_jawaban'] = (data.remove('opsi') as String)
                .split('|')
                .map((v) => v.trim())
                .toList();
          }
          data['tipe'] = type;
        }
        await widget.api.request(
          existing == null
              ? 'guru/$section'
              : 'guru/$section/${existing['id']}',
          body: data,
          method: existing == null ? 'POST' : 'PUT',
        );
      },
      initial: existing == null
          ? {}
          : {
              'aspek': existing['aspect_code'],
              'tingkat_kesulitan': existing['level'].toString(),
              if (material) ...{
                'judul': existing['title'],
                'konten': existing['content'],
              } else ...{
                'pertanyaan': existing['prompt'],
                'teks_target': existing['target_text'] ?? '',
                'penggunaan':
                    {
                      'both': 'keduanya',
                      'practice': 'latihan',
                      'diagnostic': 'diagnostik',
                    }[existing['usage_scope']] ??
                    'keduanya',
                'materi': 'Tanpa materi',
                for (final m in materials)
                  if (m['id'] == existing['material_id'])
                    'materi': "${m['id']} · ${m['title']}",
                'opsi': [for (final o in existing['options']) o['option_text']]
                    .join(' | '),
                for (final o in existing['options'])
                  if (o['is_correct'] == 1) 'kunci_jawaban': o['option_text'],
              },
            },
    );
    if (mounted && saved) reload();
  }

  Future<void> changeStatus(int id, bool approved) async {
    final material = section == 'materi';
    try {
      await widget.api.request(
        'guru/$section/$id/${material ? 'status' : 'review'}',
        method: 'PATCH',
        body: material
            ? {'status': approved ? 'aktif' : 'arsip'}
            : {'status_review': approved ? 'disetujui' : 'ditolak'},
      );
      if (mounted) reload();
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Materi dan soal'),
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          tooltip: 'Buat draf AI',
          onPressed: generate,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Tambah',
          onPressed: editContent,
        ),
      ],
    ),
    body: Column(
      children: [
        if (pendingDraft != null)
          ListTile(
            title: Text(draftStatus ?? 'Dalam antrean'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Periksa status draf',
              onPressed: checkDraft,
            ),
          ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'materi', label: Text('Materi')),
            ButtonSegment(value: 'soal', label: Text('Soal')),
          ],
          selected: {section},
          onSelectionChanged: (v) {
            section = v.first;
            page = 1;
            reload();
          },
        ),
        Expanded(
          child: FutureBuilder(
            future: rows,
            builder: (context, state) {
              if (state.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.hasError) {
                return Center(child: Text(state.error.toString()));
              }
              final response = state.requireData;
              return ListView(
                children: [
                  for (final row in response['data'])
                    ListTile(
                      title: Text(row['title'] ?? row['prompt']),
                      subtitle: Text(
                        [
                          row['aspect_code'],
                          if (row['content'] != null) row['content'],
                          if (row['target_text'] != null) row['target_text'],
                          for (final o in row['options'] ?? [])
                            "${o['option_text']}${o['is_correct'] == 1 ? ' ✓' : ''}",
                          row['status'] ?? row['review_status'],
                        ].join(' · '),
                      ),
                      onTap: () => editContent(row),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Ubah status',
                        onSelected: (action) async {
                          if (action == 'hapus') {
                            final ok = await confirmAction(
                              context,
                              'Hapus soal',
                              row['prompt'],
                              () async {
                                await widget.api.request(
                                  "guru/soal/${row['id']}",
                                  method: 'DELETE',
                                );
                              },
                            );
                            if (mounted && ok) reload();
                          } else {
                            await changeStatus(row['id'], action == 'setujui');
                          }
                        },
                        itemBuilder: (_) => [
                          if (section == 'soal')
                            const PopupMenuItem(
                              value: 'hapus',
                              child: Text('Hapus soal'),
                            ),
                          const PopupMenuItem(
                            value: 'setujui',
                            child: Text('Setujui'),
                          ),
                          PopupMenuItem(
                            value: 'tolak',
                            child: Text(
                              section == 'materi' ? 'Arsipkan' : 'Tolak',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (page > 1)
                    TextButton(
                      onPressed: () {
                        page--;
                        reload();
                      },
                      child: const Text('Sebelumnya'),
                    ),
                  if (page < response['last_page'])
                    TextButton(
                      onPressed: () {
                        page++;
                        reload();
                      },
                      child: const Text('Berikutnya'),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
