import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final active = store.activeStudents;
    final diagnosticPercent = active.isEmpty
        ? 0
        : (store.completedDiagnosticCount * 100 / active.length).round();
    final averages = _averageScores(store.diagnosticStudents);
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        const TeacherPageHeading(
          title: 'Ringkasan kelas',
          subtitle: 'Pantau kegiatan membaca dan tentukan tindak lanjut.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final columns = constraints.maxWidth >= 960 && textScale <= 1.15
                ? 4
                : constraints.maxWidth >= 600 && textScale <= 1.15
                ? 2
                : 1;
            final tileWidth = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - AppTokens.space12 * (columns - 1)) /
                      columns;
            return Wrap(
              spacing: AppTokens.space12,
              runSpacing: AppTokens.space12,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: MetricTile(
                    label: 'Siswa aktif',
                    value: '${active.length}',
                    icon: Icons.people_alt_outlined,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: MetricTile(
                    label: 'Kelas',
                    value: '${store.classes.length}',
                    icon: Icons.class_outlined,
                    tint: AppTokens.accent,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: MetricTile(
                    label: 'Diagnostik selesai',
                    value: '$diagnosticPercent%',
                    icon: Icons.fact_check_outlined,
                    tint: AppTokens.success,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: MetricTile(
                    label: 'Rekaman menunggu',
                    value: '${store.pendingRecordingCount}',
                    icon: Icons.mic_none_rounded,
                    tint: const Color(0xFF4F71A8),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.space24),
        LayoutBuilder(
          builder: (context, constraints) {
            final chart = TeacherPanel(
              title: 'Ringkasan kemampuan',
              child: Column(
                children: [
                  for (final aspect in const [
                    'huruf',
                    'suku_kata',
                    'kata',
                    'kalimat',
                  ])
                    _AspectAverage(
                      label: aspectLabel(aspect),
                      value: averages[aspect] ?? 0,
                    ),
                ],
              ),
            );
            final support = TeacherPanel(
              title: 'Perlu pendampingan',
              trailing: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/guru/siswa'),
                child: const Text('Semua siswa'),
              ),
              child: Column(
                children: [
                  for (final student in store.activeStudents.where(
                    (item) => item.needsSupport,
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline_rounded),
                      ),
                      title: Text(student.name),
                      subtitle: Text(
                        '${store.className(student.classId)} • ${student.masterySummary}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/guru/siswa/detail',
                        arguments: student.id,
                      ),
                    ),
                  if (!store.activeStudents.any((item) => item.needsSupport))
                    const EmptyState(
                      message:
                          'Tidak ada siswa yang perlu pendampingan saat ini.',
                    ),
                ],
              ),
            );
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  chart,
                  const SizedBox(height: AppTokens.space16),
                  support,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: chart),
                const SizedBox(width: AppTokens.space16),
                Expanded(child: support),
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.space24),
        TeacherPanel(
          title: 'Antrean evaluasi rekaman',
          trailing: TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/guru/rekaman'),
            child: const Text('Buka antrean'),
          ),
          child: Column(
            children: [
              for (final recording in store.recordings.where(
                (item) => item.status == 'terkirim',
              ))
                Builder(
                  builder: (context) {
                    final student = store.studentById(recording.studentId)!;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.graphic_eq_rounded),
                      ),
                      title: Text(student.name),
                      subtitle: Text(
                        '${aspectLabel(recording.aspect)} • ${recording.durationSeconds} detik',
                      ),
                      trailing: const StatusBadge(label: 'Menunggu'),
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        '/guru/rekaman',
                      ),
                    );
                  },
                ),
              if (store.pendingRecordingCount == 0)
                const EmptyState(
                  message: 'Tidak ada rekaman yang menunggu evaluasi.',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Map<String, int> _averageScores(List<DemoStudent> students) {
  final result = <String, int>{};
  for (final aspect in const ['huruf', 'suku_kata', 'kata', 'kalimat']) {
    final scores = students.map((item) => item.scores![aspect]!).toList();
    result[aspect] = scores.isEmpty
        ? 0
        : (scores.reduce((a, b) => a + b) / scores.length).round();
  }
  return result;
}

class _AspectAverage extends StatelessWidget {
  const _AspectAverage({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 140,
          child: LinearProgressIndicator(value: value / 100, minHeight: 8),
        ),
        const SizedBox(width: AppTokens.space12),
        SizedBox(width: 40, child: Text('$value%')),
      ],
    ),
  );
}
