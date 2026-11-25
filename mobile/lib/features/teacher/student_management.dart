import 'package:flutter/material.dart';

import '../../core/api/bacatepat_api.dart';
import 'learning_results.dart';
import '../../core/components/api_list_page.dart';
import 'server_teacher_tools.dart';

class StudentManagement extends StatefulWidget {
  const StudentManagement({super.key, required this.api, required this.id});
  final BacaTepatApi api;
  final int id;
  @override
  State<StudentManagement> createState() => _StudentManagementState();
}

class _StudentManagementState extends State<StudentManagement> {
  String get path => 'guru/siswa/${widget.id}';
  late Future<Map<String, dynamic>> student = widget.api.request(path);
  Future<void> edit(
    String title,
    List<Field> fields,
    String endpoint,
    String method,
    Map<String, dynamic> Function(Map<String, String>) payload, {
    Map<String, String> initial = const {},
  }) async {
    final changed = await editForm(context, title, fields, (v) async {
      await widget.api.request(endpoint, method: method, body: payload(v));
    }, initial: initial);
    if (changed && mounted) setState(() => student = widget.api.request(path));
  }

  Future<void> chooseClass() async {
    try {
      final result = await widget.api.request('guru/kelas');
      if (!mounted) return;
      final classes = [
        for (final c in result['data'])
          "${c['id']} · ${c['nama_kelas']} (${c['tahun_ajaran']})",
      ];
      if (classes.isEmpty) return;
      await edit(
        'Pindah kelas',
        [field('kelas', 'Kelas tujuan', classes)],
        '$path/kelas',
        'PATCH',
        (v) => {'kelas_id': int.parse(v['kelas']!.split(' · ').first)},
      );
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> recommend() async {
    try {
      final titles = <String>[];
      for (int page = 1; ; page++) {
        final result = await widget.api.request(
          'guru/materi?page=$page&status=aktif',
        );
        for (final m in result['data']) {
          titles.add("${m['id']} · ${m['title']}");
        }
        if (page >= result['last_page']) break;
      }
      if (!mounted) return;
      if (titles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktifkan materi terlebih dahulu.')),
        );
        return;
      }
      await edit(
        'Rekomendasi guru',
        [field('materi', 'Materi', titles), field('alasan', 'Alasan')],
        '$path/rekomendasi',
        'PUT',
        (v) => {
          'materi_id': int.parse(v['materi']!.split(' · ').first),
          'alasan': v['alasan'],
        },
      );
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil siswa')),
    body: FutureBuilder(
      future: student,
      builder: (context, state) {
        if (state.hasError) return Center(child: Text(state.error.toString()));
        if (!state.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = state.requireData['data'];
        return ListView(
          children: [
            ListTile(
              title: Text(s['nama']),
              subtitle: Text("${s['username']} · ${s['status']}"),
            ),
            ListTile(
              title: const Text('Evaluasi bacaan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ApiListPage(
                    api: widget.api,
                    title: 'Evaluasi bacaan · ${s['nama']}',
                    path: '$path/evaluasi',
                    empty: 'Belum ada evaluasi bacaan.',
                    tile: (_, row, _) => ListTile(
                      title: Text(row['bacaan']),
                      subtitle: Text(
                        [
                          'Ketepatan ${row['accuracy_score']} · Kelancaran ${row['fluency_score']}',
                          row['comment'],
                          row['advice'],
                        ].whereType<String>().join('\n'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final kind in ['diagnostik', 'latihan'])
              ListTile(
                title: Text('Riwayat $kind'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ApiListPage(
                      api: widget.api,
                      title: 'Riwayat $kind · ${s['nama']}',
                      path: '$path/$kind',
                      empty: 'Belum ada percobaan $kind.',
                      tile: (_, row, _) => ListTile(
                        title: Text(row['judul']),
                        subtitle: Text(
                          "${row['started_at']} · ${{'completed': 'Selesai', 'in_progress': 'Sedang dikerjakan', 'abandoned': 'Dihentikan', 'waiting_teacher': 'Menunggu penilaian Guru'}[row['status']] ?? row['status']}",
                        ),
                        trailing: Text(
                          row['skor'] == null ? '–' : '${row['skor']}',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ListTile(
              title: const Text('Perkembangan dan laporan'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => LearningProgress(
                    api: widget.api,
                    studentId: widget.id,
                    name: s['nama'],
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('Edit profil'),
              onTap: () => edit(
                'Edit profil',
                [
                  field('nama', 'Nama siswa'),
                  field('username', 'Nama pengguna'),
                  field('nama_wali', 'Nama wali'),
                ],
                path,
                'PUT',
                (v) => v,
                initial: {
                  'nama': s['nama'],
                  'username': s['username'],
                  'nama_wali': s['guardian_name'],
                },
              ),
            ),
            ListTile(title: const Text('Pindah kelas'), onTap: chooseClass),
            ListTile(title: const Text('Rekomendasi guru'), onTap: recommend),
            ListTile(
              title: const Text('Atur ulang kata sandi'),
              onTap: () => edit(
                'Atur ulang kata sandi',
                [field('password', 'Kata sandi baru')],
                '$path/reset-password',
                'POST',
                (v) => {'password_baru': v['password']},
              ),
            ),
            ListTile(
              title: const Text('Status akun'),
              onTap: () => edit(
                'Status akun',
                [
                  field('status', 'Status', ['aktif', 'nonaktif']),
                ],
                '$path/status',
                'PATCH',
                (v) => {'aktif': v['status'] == 'aktif'},
                initial: {'status': s['status']},
              ),
            ),
            ListTile(
              title: const Text('Persetujuan wali'),
              subtitle: Text(
                "Rekaman: ${s['parent_consent'] == 1 ? 'diizinkan' : 'belum diizinkan'} · Analisis OpenAI: ${s['ai_consent'] == 1 ? 'diizinkan' : 'belum diizinkan'}",
              ),
              onTap: () => edit(
                'Catat persetujuan wali',
                [
                  field('wali', 'Izin rekaman', ['Tidak', 'Ya']),
                  field('ai', 'Izin kirim rekaman ke OpenAI', ['Tidak', 'Ya']),
                ],
                '$path/persetujuan',
                'PUT',
                (v) => {
                  'persetujuan_wali': v['wali'] == 'Ya',
                  'persetujuan_ai': v['ai'] == 'Ya',
                },
                initial: {
                  'wali': s['parent_consent'] == 1 ? 'Ya' : 'Tidak',
                  'ai': s['ai_consent'] == 1 ? 'Ya' : 'Tidak',
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}
