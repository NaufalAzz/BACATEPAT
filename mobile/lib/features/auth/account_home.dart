import 'package:flutter/material.dart';

import '../../app/navigation_plan.dart';
import '../teacher/dashboard/dashboard_page.dart';
import '../teacher/teacher_shell.dart';
import '../teacher/profile/profile_page.dart';
import '../student/audio/student_audio_page.dart';
import '../teacher/classes/classes_page.dart';
import '../teacher/teacher_demo_store.dart' show DemoMaterial, aspectLabel;
import '../teacher/teacher_widgets.dart';
import '../student/dashboard/student_dashboard_page.dart';
import '../student/student_shell.dart';
import '../student/progress/student_progress_page.dart';
import '../student/practice/student_practice_pages.dart';
import '../student/student_demo_store.dart' show StudentActivity, MasteryRecord;
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
    if (!teacher) {
      final result = await widget.api.request('siswa/beranda');
      if (tab == 'S9') {
        final response = await widget.api.request('siswa/perkembangan');
        final groups = response['data']['aspek'];
        result['records'] = <MasteryRecord>[
          if (groups is Map)
            for (final entries in groups.values)
              for (final row in entries)
                MasteryRecord(
                  id: row['id'],
                  studentId: row['student_id'],
                  classId: row['class_id'],
                  aspect: row['aspek'],
                  level: row['observed_level'],
                  score: num.parse(row['skor'].toString()).round(),
                  source: row['sumber'] == 'diagnostic'
                      ? 'diagnostik'
                      : row['sumber'],
                  sourceId:
                      row['diagnostic_attempt_id'] ??
                      row['practice_attempt_id'] ??
                      row['audio_evaluation_revision_id'],
                  status: const {
                    'not_mastered': 'belum_dikuasai',
                    'practicing': 'sedang_berlatih',
                    'mastered': 'dikuasai',
                  }[row['status']]!,
                  recordedAt: DateTime.parse(row['tanggal']),
                  reason: row['reason'],
                ),
        ];
      }
      if (tab == 'S4') {
        final catalog = <DemoMaterial>[];
        var page = 1;
        while (true) {
          final rows = await widget.api.request('siswa/latihan?page=$page');
          for (final row in rows['data']) {
            catalog.add(
              DemoMaterial(
                id: row['materi_id'],
                title: row['judul'],
                content: row['konten'],
                aspect: row['aspek'],
                level: row['tingkat'],
              ),
            );
          }
          if (page >= rows['last_page']) break;
          page++;
        }
        result['catalog'] = catalog;
      }
      return result;
    }
    final responses = await Future.wait([
      widget.api.request('guru/kelas'),
      widget.api.request('guru/dashboard'),
      widget.api.request('guru/pendampingan'),
    ]);
    pending = responses[1]['data']['pending'];
    return {
      'data': responses.first['data'],
      'summary': responses[1]['data'],
      'support': responses[2]['data'],
    };
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

  late String tab = teacher ? 'G2' : 'S2';

  Future<void> open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) setState(() => overview = load());
  }

  void select(String id) => setState(() {
    tab = id;
    overview = load();
  });

  void openMaterial(DemoMaterial material) {
    open(
      Scaffold(
        appBar: AppBar(title: const Text('Materi latihan')),
        body: StudentMaterialDetailPage(
          item: material,
          onStart: () => open(
            ServerDiagnosticPage(
              api: widget.api,
              material: {
                'materi_id': material.id,
                'judul': material.title,
                'konten': material.content,
              },
            ),
          ),
        ),
      ),
    );
  }

  bool largerText = false;
  Widget accountSettings() {
    if (!teacher) {
      return StudentProfilePage(
        profile: profile,
        largerText: largerText,
        onToggle: () => setState(() => largerText = !largerText),
        onLogout: logout,
      );
    }
    return ProfilePage(
      profile: profile,
      onLogout: logout,
      onSave: (name, email, days) async {
        final response = await widget.api.request(
          'guru/profil',
          method: 'PUT',
          body: {'nama': name, 'email': email, 'retensi_audio_hari': days},
        );
        if (mounted) setState(() => profile = response['data']);
      },
      onPassword: () => editForm(
        context,
        'Ganti kata sandi',
        [
          field('password_lama', 'Kata sandi lama'),
          field('password_baru', 'Kata sandi baru'),
        ],
        (values) async {
          await widget.api.request(
            'auth/password',
            method: 'PUT',
            body: values,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = (teacher ? NavigationPlan.teacher : NavigationPlan.student)
        .firstWhere((s) => s.id == tab);
    final body = FutureBuilder<Map<String, dynamic>>(
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

          if (tab == 'G2') {
            return DashboardOverview(
              activeCount: summary['aktif'],
              classCount: summary['kelas'],
              pendingCount: summary['pending'],
              diagnosticPercent: summary['aktif'] == 0
                  ? 0
                  : (summary['diagnosed'] * 100 / summary['aktif']).round(),
              averages: {
                for (final row in summary['averages'])
                  row['aspect_code']: num.parse(row['score'].toString())
                      .round(),
              },
              onStudents: () => select('G3'),
              onRecordings: () => select('G13'),
              supportRows: [
                for (final row in state.requireData['support'])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline_rounded),
                    ),
                    title: Text(row['nama']),
                    subtitle: Text("${row['kelas']} • ${row['alasan']}"),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => open(
                      StudentManagement(api: widget.api, id: row['siswa_id']),
                    ),
                  ),
              ],
              recommendations: [
                for (final row in summary['recommendations'])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("${row['name']} · ${row['title']}"),
                    subtitle: Text(
                      "${aspectLabel(row['aspect_code'])}, tingkat ${row['target_level']} · ${row['reason']}",
                    ),
                  ),
              ],
              gaps: [
                for (final row in summary['gaps'])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "${row['name']} · ${aspectLabel(row['aspect_code'])} tingkat ${row['target_level']}",
                    ),
                    subtitle: Text(row['reason']),
                  ),
              ],
              recordings: [
                for (final row in summary['recordings'])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.graphic_eq_rounded),
                    ),
                    title: Text(row['name']),
                    subtitle: Text(
                      "${row['target_text_snapshot']} • ${row['duration_seconds']} detik",
                    ),
                    trailing: const StatusBadge(label: 'Menunggu'),
                    onTap: () => select('G13'),
                  ),
              ],
            );
          }
          if (tab == 'G17') return accountSettings();
          if (tab == 'G3') {
            return ApiListPage(
              api: widget.api,
              title: 'Siswa',
              path: 'guru/siswa',
              empty: 'Belum ada siswa.',
              tile: (_, row, refresh) => ListTile(
                title: Text(row['nama']),
                subtitle: Text(row['kelas']),
                onTap: () async {
                  await open(StudentManagement(api: widget.api, id: row['id']));
                  refresh();
                },
              ),
            );
          }
          if (tab == 'G6' || tab == 'G9') {
            return TeacherContentPage(
              key: ValueKey(tab),
              api: widget.api,
              initialSection: tab == 'G6' ? 'materi' : 'soal',
            );
          }
          if (tab == 'G13') return TeacherRecordings(api: widget.api);
          if (tab == 'G5') {
            return ClassesPage(
              rows: classes,
              onAdd: editClass,
              onEdit: editClass,
              onOpen: (row) => open(
                ClassRoster(
                  api: widget.api,
                  id: row['id'],
                  name: row['nama_kelas'],
                ),
              ),
              onDelete: (row) async {
                final ok = await confirmAction(
                  context,
                  'Hapus kelas',
                  row['nama_kelas'],
                  () async {
                    await widget.api.request(
                      "guru/kelas/${row['id']}",
                      method: 'DELETE',
                    );
                  },
                );
                if (mounted && ok) setState(() => overview = load());
              },
            );
          }
          return ListView(
            children: [
              TeacherPageHeading(
                title: screen.title,
                subtitle: 'Pilih kelas untuk melihat data pembelajaran.',
              ),
              if (tab == 'G15')
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => tab == 'G11'
                          ? DiagnosticResults(api: widget.api, classId: c['id'])
                          : tab == 'G16'
                          ? ClassReport(
                              api: widget.api,
                              path: "guru/laporan/kelas/${c['id']}",
                            )
                          : ClassRoster(
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
        final activities = <StudentActivity>[
          for (final row in (data['latihan'] as List).where(
            (r) => r['status'] == 'completed' && r['nilai'] != null,
          ))
            StudentActivity(
              title: row['judul'],
              aspect: row['aspect_code'],
              score: num.parse(row['nilai'].toString()).round(),
              finishedAt: DateTime.parse(row['finished_at'] ?? row['tanggal']),
            ),
        ];
        if (tab == 'S4') {
          final scores = <String, int>{};
          for (final row in data['latihan']) {
            if (row['nilai'] != null) {
              scores.putIfAbsent(
                row['aspect_code'],
                () => num.parse(row['nilai'].toString()).round(),
              );
            }
          }
          return StudentPracticeListPage(
            catalog: state.requireData['catalog'],
            recommendedId: material?['materi_id'],
            reason: material?['alasan'],
            hasDiagnostic: data['has_diagnostic'],
            completeBaseline: data['completed'],
            scores: scores,
            onOpen: openMaterial,
          );
        }
        if (tab == 'S2') {
          final recommended = material == null
              ? null
              : DemoMaterial(
                  id: material['materi_id'],
                  title: material['judul'],
                  aspect: material['aspect_code'],
                  level: material['level'],
                  content: material['konten'],
                );
          return StudentOverview(
            name: profile['nama'],
            className: profile['kelas'] ?? '',
            hasActiveTest: data['active_test'],
            hasAnyDiagnostic: data['has_diagnostic'],
            completed: data['completed'],
            completeBaseline: data['completed'],
            active: recommended,
            reason: material?['alasan'] ?? '',
            activities: activities.take(2).toList(),
            onHistory: () => select('S8'),
            onPractice: () => select('S4'),
            onDiagnostic: () => open(ServerDiagnosticPage(api: widget.api)),
            onStart: () {
              if (recommended != null) openMaterial(recommended);
            },
          );
        }
        if (tab == 'S10') return accountSettings();
        if (tab == 'S9') {
          return StudentProgressPage(
            records: state.requireData['records'],
            activities: activities,
            completedCount: data['practice_completed'],
            historyLink: TextButton(
              onPressed: () => select('S8'),
              child: const Text('Riwayat dan evaluasi'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
    );
    if (teacher) {
      return TeacherShell(
        screen: screen,
        name: profile['nama'],
        pending: pending,
        body: body,
        onSelect: select,
      );
    }
    return StudentShell(
      largerText: largerText,
      screen: screen,
      name: profile['nama'],
      body: body,
      onSelect: select,
    );
  }

  int pending = 0;
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
