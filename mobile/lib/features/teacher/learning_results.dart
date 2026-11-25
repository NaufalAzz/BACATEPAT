import 'package:flutter/material.dart';

import '../../core/api/bacatepat_api.dart';
import 'server_reviews.dart';
import 'server_teacher_tools.dart';

class LearningProgress extends StatefulWidget {
  const LearningProgress({
    super.key,
    required this.api,
    this.studentId,
    this.name,
  });
  final BacaTepatApi api;
  final int? studentId;
  final String? name;
  @override
  State<LearningProgress> createState() => _LearningProgressState();
}

class _LearningProgressState extends State<LearningProgress> {
  late final data = widget.api.request(
    widget.studentId == null
        ? 'siswa/perkembangan'
        : 'guru/perkembangan/siswa/${widget.studentId}',
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.name ?? 'Perkembangan membaca'),
      actions: [
        if (widget.studentId != null)
          IconButton(
            tooltip: 'Unduh laporan',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ClassReport(
                  api: widget.api,
                  path: 'guru/laporan/siswa/${widget.studentId}',
                ),
              ),
            ),
          ),
      ],
    ),
    body: FutureBuilder(
      future: data,
      builder: (context, state) {
        if (state.hasError) return Center(child: Text(state.error.toString()));
        if (!state.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = state.requireData['data']['aspek'];
        if (groups is! Map || groups.isEmpty) {
          return const Center(child: Text('Belum ada hasil belajar.'));
        }
        return ListView(
          children: [
            for (final entry in groups.entries)
              ExpansionTile(
                title: Text(entry.key.toString().replaceAll('_', ' ')),
                subtitle: Text('Skor terakhir ${entry.value.last['skor']}'),
                children: [
                  for (final row in (entry.value as List).reversed)
                    ListTile(
                      title: Text('${row['tanggal']} · ${row['skor']}'),
                      subtitle: LinearProgressIndicator(
                        value: double.parse(row['skor'].toString()) / 100,
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    ),
  );
}

class DiagnosticResults extends StatefulWidget {
  const DiagnosticResults({
    super.key,
    required this.api,
    required this.classId,
    this.testId,
    this.title,
  });
  final BacaTepatApi api;
  final int classId;
  final int? testId;
  final String? title;
  @override
  State<DiagnosticResults> createState() => _DiagnosticResultsState();
}

class _DiagnosticResultsState extends State<DiagnosticResults> {
  int page = 1;
  late Future<Map<String, dynamic>> rows = load();
  Future<Map<String, dynamic>> load() => widget.api.request(
    widget.testId == null
        ? 'guru/diagnostik?kelas_id=${widget.classId}&page=$page'
        : 'guru/diagnostik/${widget.testId}/hasil?page=$page',
  );
  void turn(int step) => setState(() {
    page += step;
    rows = load();
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title ?? 'Hasil diagnostik')),
    body: FutureBuilder(
      future: rows,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.hasError) return Center(child: Text(state.error.toString()));
        final data = state.requireData;
        return ListView(
          children: [
            if ((data['data'] as List).isEmpty)
              ListTile(
                title: Text(
                  widget.testId == null
                      ? 'Belum ada tes.'
                      : 'Belum ada siswa yang mengerjakan tes.',
                ),
              ),
            for (final row in data['data'])
              if (widget.testId == null)
                ListTile(
                  title: Text(row['title']),
                  subtitle: Text(
                    {
                          'draft': 'Draf',
                          'active': 'Aktif',
                          'finished': 'Selesai',
                        }[row['status']] ??
                        row['status'],
                  ),
                  trailing: row['status'] == 'draft'
                      ? TextButton(
                          child: const Text('Ubah draf'),
                          onPressed: () async {
                            try {
                              final detail = await widget.api.request(
                                "guru/diagnostik/${row['id']}",
                              );
                              if (!context.mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => ClassTestBuilder(
                                    api: widget.api,
                                    classId: widget.classId,
                                    draft: detail['data'],
                                  ),
                                ),
                              );
                              if (mounted) turn(0);
                            } on ApiError catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.message)),
                                );
                              }
                            }
                          },
                        )
                      : row['status'] == 'active'
                      ? TextButton(
                          child: const Text('Akhiri tes'),
                          onPressed: () async {
                            final ok = await confirmAction(
                              context,
                              'Akhiri tes',
                              row['title'],
                              () async {
                                await widget.api.request(
                                  "guru/diagnostik/${row['id']}/status",
                                  method: 'PATCH',
                                  body: {'status': 'selesai'},
                                );
                              },
                            );
                            if (mounted && ok) turn(0);
                          },
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => DiagnosticResults(
                        api: widget.api,
                        classId: widget.classId,
                        testId: row['id'],
                        title: row['title'],
                      ),
                    ),
                  ),
                )
              else
                ListTile(
                  title: Text(row['nama']),
                  subtitle: Text(
                    {
                          'completed': 'Selesai',
                          'waiting_teacher': 'Menunggu penilaian',
                          'in_progress': 'Sedang dikerjakan',
                          'abandoned': 'Dihentikan',
                        }[row['status']] ??
                        row['status'],
                  ),
                  trailing: Text('${row['skor'] ?? "–"}'),
                ),
            if (page > 1)
              TextButton(
                onPressed: () => turn(-1),
                child: const Text('Sebelumnya'),
              ),
            if (page < data['last_page'])
              TextButton(
                onPressed: () => turn(1),
                child: const Text('Berikutnya'),
              ),
          ],
        );
      },
    ),
  );
}
