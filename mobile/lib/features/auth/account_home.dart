import 'package:flutter/material.dart';

import '../../core/api/bacatepat_api.dart';
import '../../core/components/api_list_page.dart';
import '../student/diagnostic/server_diagnostic_page.dart';
import '../teacher/server_teacher_tools.dart';
import '../teacher/server_reviews.dart';
import '../teacher/learning_results.dart';
import '../teacher/student_management.dart';

class AccountHome extends StatefulWidget {
  const AccountHome({super.key, required this.api, required this.user});
  final BacaTepatApi api;
  final Map<String, dynamic> user;
  @override
  State<AccountHome> createState() => _AccountHomeState();
}

class _AccountHomeState extends State<AccountHome> {
  late Map<String, dynamic> profile = widget.user;
  bool get teacher => widget.user['role'] == 'guru';
  late Future<Map<String, dynamic>> overview = load();

  Future<void> editClass([Map<String, dynamic>? c]) async {
    final ok = await editForm(
      context,
      c == null ? 'Tambah kelas' : 'Ubah kelas',
      [
        field('nama_kelas', 'Nama kelas'),
        field('tingkat', 'Tingkat', ['1', '2', '3']),
        field('tahun_ajaran', 'Tahun ajaran (2026/2027)'),
      ],
      (data) async {
        await widget.api.request(
          c == null ? 'guru/kelas' : "guru/kelas/${c['id']}",
          method: c == null ? 'POST' : 'PUT',
          body: data,
        );
      },
      initial: {
        if (c != null)
          for (final key in ['nama_kelas', 'tingkat', 'tahun_ajaran'])
            key: c[key].toString(),
      },
    );
    if (mounted && ok) setState(() => overview = load());
  }

  @override
  void initState() {
    super.initState();
    widget.api.onExpired = exit;
  }

  @override
  void dispose() {
    widget.api.onExpired = null;
    super.dispose();
  }

  Future<Map<String, dynamic>> load() async {
    final response = await widget.api.request('auth/me');
    profile = response['data'];
    if (!teacher) return widget.api.request('siswa/beranda');
    final responses = await Future.wait([
      widget.api.request('guru/kelas'),
      widget.api.request('guru/dashboard'),
    ]);
    return {'data': responses.first['data'], 'summary': responses.last['data']};
  }

  void exit() =>
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);

  Future<void> logout() async {
    try {
      await widget.api.logout();
      if (mounted) exit();
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        exit();
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(profile['nama'] as String),
      actions: [
        if (teacher)
          PopupMenuButton<String>(
            tooltip: 'Pengaturan akun',
            onSelected: (action) async {
              if (action == 'password') {
                await editForm(
                  context,
                  'Ganti kata sandi',
                  [
                    field('password_lama', 'Kata sandi lama'),
                    field('password_baru', 'Kata sandi baru'),
                  ],
                  (v) async {
                    await widget.api.request(
                      'auth/password',
                      body: v,
                      method: 'PUT',
                    );
                  },
                );
              } else {
                final ok = await editForm(
                  context,
                  'Profil Guru',
                  [
                    field('nama', 'Nama guru'),
                    field('retensi_audio_hari', 'Retensi audio (1–180 hari)'),
                  ],
                  (v) async {
                    final r = await widget.api.request(
                      'guru/profil',
                      body: v,
                      method: 'PUT',
                    );
                    profile = r['data'];
                  },
                  initial: {
                    'nama': profile['nama'],
                    'retensi_audio_hari': profile['retensi_audio_hari']
                        .toString(),
                  },
                );
                if (mounted && ok) setState(() => overview = load());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'profil',
                child: Text('Profil dan retensi audio'),
              ),
              PopupMenuItem(value: 'password', child: Text('Ganti kata sandi')),
            ],
          ),
        IconButton(
          tooltip: 'Muat ulang',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() => overview = load()),
        ),
        IconButton(
          tooltip: 'Keluar',
          icon: const Icon(Icons.logout),
          onPressed: logout,
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: overview,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.hasError) return Center(child: Text(state.error.toString()));
        final data = state.requireData['data'];
        if (teacher) {
          final classes = data as List;
          final summary = state.requireData['summary'];

          return ListView(
            children: [
              ListTile(
                title: const Text('Ringkasan kelas'),
                subtitle: Text(
                  "${summary['kelas']} kelas · ${summary['siswa']} siswa · ${summary['tes_aktif']} tes aktif",
                ),
              ),
              ListTile(
                leading: const Icon(Icons.library_books),
                title: const Text('Materi dan soal'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TeacherContentPage(api: widget.api),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Tambah kelas'),
                onTap: () => editClass(),
              ),
              ListTile(
                leading: const Icon(Icons.headphones),
                title: const Text('Rekaman siswa'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TeacherRecordings(api: widget.api),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.support),
                title: const Text('Pendampingan siswa'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ApiListPage(
                      api: widget.api,
                      title: 'Pendampingan siswa',
                      path: 'guru/pendampingan',
                      empty: 'Belum ada siswa yang memerlukan tindak lanjut.',
                      tile: (context, row, refresh) => ListTile(
                        title: Text(row['nama']),
                        subtitle: Text("${row['aspek']} · ${row['alasan']}"),
                        trailing: TextButton(
                          child: const Text('Sudah didampingi'),
                          onPressed: () async {
                            try {
                              await widget.api.request(
                                'guru/siswa/${row['siswa_id']}/pendampingan',
                                method: 'PATCH',
                                body: {'perlu_pendampingan': false},
                              );
                              refresh();
                            } on ApiError catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.message)),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (final c in classes)
                ListTile(
                  title: Text(c['nama_kelas']),
                  subtitle: Text(c['tahun_ajaran']),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Ubah kelas')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus kelas'),
                      ),
                    ],
                    onSelected: (action) async {
                      if (action == 'edit') {
                        await editClass(c);
                        return;
                      }
                      final ok = await confirmAction(
                        context,
                        'Hapus kelas',
                        c['nama_kelas'],
                        () async {
                          await widget.api.request(
                            "guru/kelas/${c['id']}",
                            method: 'DELETE',
                          );
                        },
                      );
                      if (mounted && ok) setState(() => overview = load());
                    },
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ClassRoster(
                        api: widget.api,
                        id: c['id'],
                        name: c['nama_kelas'],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        final material = data['rekomendasi'];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Kelas ${profile['kelas']}'),
            ListTile(
              title: const Text('Tes diagnostik'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ServerDiagnosticPage(api: widget.api),
                ),
              ),
            ),
            ListTile(
              title: const Text('Perkembangan membaca'),
              trailing: const Icon(Icons.bar_chart),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => LearningProgress(api: widget.api),
                ),
              ),
            ),
            ListTile(
              title: const Text('Daftar latihan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ApiListPage(
                    api: widget.api,
                    title: 'Daftar latihan',
                    path: 'siswa/latihan',
                    empty: 'Belum ada latihan.',
                    tile: (context, m, _) => ListTile(
                      title: Text(m['judul']),
                      subtitle: Text(m['konten']),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ServerDiagnosticPage(
                            api: widget.api,
                            material: m,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const ListTile(title: Text('Rekomendasi belajar')),
            if (material == null)
              const Text('Belum ada rekomendasi.')
            else
              ListTile(
                title: Text(material['judul']),
                subtitle: Text(material['konten']),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ServerDiagnosticPage(
                        api: widget.api,
                        material: material,
                      ),
                    ),
                  );
                  if (mounted) setState(() => overview = load());
                },
              ),
            ListTile(
              title: const Text('Evaluasi bacaan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ApiListPage(
                    api: widget.api,
                    title: 'Evaluasi bacaan',
                    path: 'siswa/evaluasi',
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
                      title: 'Riwayat $kind',
                      path: kind == 'latihan'
                          ? 'siswa/latihan/riwayat'
                          : 'siswa/diagnostik/hasil',
                      empty: 'Belum ada percobaan $kind.',
                      tile: (_, row, _) => ListTile(
                        title: Text(row['judul'] ?? 'Tes diagnostik'),
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
          ],
        );
      },
    ),
  );
}

class ClassRoster extends StatefulWidget {
  const ClassRoster({
    super.key,
    required this.api,
    required this.id,
    required this.name,
  });
  final BacaTepatApi api;
  final int id;
  final String name;
  @override
  State<ClassRoster> createState() => _ClassRosterState();
}

class _ClassRosterState extends State<ClassRoster> {
  int page = 1;
  late Future<Map<String, dynamic>> roster = load();
  Future<Map<String, dynamic>> load() =>
      widget.api.request('guru/siswa?kelas_id=${widget.id}&page=$page');
  void turn(int step) => setState(() {
    page += step;
    roster = load();
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.name),
      actions: [
        IconButton(
          tooltip: 'Laporan kelas',
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ClassReport(
                api: widget.api,
                path: 'guru/laporan/kelas/${widget.id}',
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Susun tes',
          icon: const Icon(Icons.quiz),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  ClassTestBuilder(api: widget.api, classId: widget.id),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Tambah siswa',
          icon: const Icon(Icons.person_add),
          onPressed: () async {
            final ok = await editForm(
              context,
              'Tambah siswa',
              [
                field('nama', 'Nama siswa'),
                field('username', 'Nama pengguna'),
                field('password', 'Kata sandi'),
                field('nama_wali', 'Nama wali'),
              ],
              (data) async {
                await widget.api.request(
                  'guru/siswa',
                  body: {...data, 'kelas_id': widget.id},
                );
              },
            );
            if (mounted && ok) setState(() => roster = load());
          },
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: roster,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.hasError) return Center(child: Text(state.error.toString()));
        final result = state.requireData;
        return ListView(
          children: [
            ListTile(
              title: const Text('Grafik perkembangan kelas'),
              trailing: const Icon(Icons.bar_chart),
              onTap: () {
                final progress = widget.api.request(
                  'guru/perkembangan/kelas/${widget.id}',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text('Perkembangan kelas ${widget.name}'),
                      ),
                      body: FutureBuilder(
                        future: progress,
                        builder: (context, state) {
                          if (state.hasError) {
                            return Center(child: Text(state.error.toString()));
                          }
                          if (!state.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final groups = state.requireData['data'];
                          if (groups is! Map || groups.isEmpty) {
                            return const Center(
                              child: Text('Belum ada hasil belajar kelas ini.'),
                            );
                          }
                          return ListView(
                            children: [
                              for (final entry in groups.entries)
                                ListTile(
                                  title: Text(
                                    entry.key.toString().replaceAll('_', ' '),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Rata-rata ${entry.value['rata_rata']} dari ${entry.value['jumlah_pengamatan']} pengamatan",
                                      ),
                                      LinearProgressIndicator(
                                        value:
                                            (entry.value['rata_rata'] as num)
                                                .toDouble() /
                                            100,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Hasil diagnostik'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      DiagnosticResults(api: widget.api, classId: widget.id),
                ),
              ),
            ),
            if ((result['data'] as List).isEmpty)
              const ListTile(title: Text('Belum ada siswa.')),
            for (final s in result['data'])
              ListTile(
                title: Text(s['nama']),
                subtitle: Text(s['status']),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          StudentManagement(api: widget.api, id: s['id']),
                    ),
                  );
                  if (mounted) setState(() => roster = load());
                },
              ),
            if (page > 1)
              TextButton(
                onPressed: () => turn(-1),
                child: const Text('Sebelumnya'),
              ),
            if (page < result['last_page'])
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
