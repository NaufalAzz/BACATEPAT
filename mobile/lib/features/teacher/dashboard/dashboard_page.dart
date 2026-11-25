import 'package:flutter/material.dart';

import '../../../app/app_session.dart';
import '../../../core/theme/app_tokens.dart';
import '../../student/student_demo_store.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final active = store.activeStudents;
    final studentStore = StudentDemoStore.instance;
    final teacherId = AppSession.teacherId ?? -1;
    final latestByStudent = _latestMasteryByStudent(
      studentStore.masteryHistoryForTeacher(teacherId),
    );
    final activeStudentIds = active.map((item) => item.id).toSet();
    final diagnosedStudentCount = latestByStudent.keys
        .where(activeStudentIds.contains)
        .length;
    final diagnosticPercent = active.isEmpty
        ? 0
        : (diagnosedStudentCount * 100 / active.length).round();
    final averages = _averageScores(
      latestByStudent.values.expand((value) => value.values).toList(),
    );
    return DashboardOverview(
      activeCount: active.length,
      classCount: store.accessibleClasses.length,
      diagnosticPercent: diagnosticPercent,
      pendingCount: store.pendingRecordingCount,
      averages: averages,
      onStudents: () => Navigator.pushReplacementNamed(context, '/guru/siswa'),
      onRecordings: () =>
          Navigator.pushReplacementNamed(context, '/guru/rekaman'),
      supportRows: [
        for (final student in store.activeStudents.where(
          (item) => studentStore.needsSupportForStudent(item.id),
        ))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline_rounded),
            ),
            title: Text(student.name),
            subtitle: Text(
              '${store.className(student.classId)} • ${masterySummaryFor({for (final entry in (latestByStudent[student.id] ?? const <String, MasteryRecord>{}).entries) entry.key: entry.value.score})}',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(
              context,
              '/guru/siswa/detail',
              arguments: student.id,
            ),
          ),
      ],
      recommendations: [
        for (final recommendation
            in studentStore.activeRecommendationsForTeacher(teacherId))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${store.studentById(recommendation.studentId)?.name ?? 'Siswa'} · ${store.materialById(recommendation.materialId)?.title ?? 'Materi tidak tersedia'}',
            ),
            subtitle: Text(
              '${aspectLabel(recommendation.aspect)}, tingkat ${recommendation.level} · ${recommendation.reason}',
            ),
          ),
      ],
      gaps: [
        for (final gap in studentStore.materialGapsForTeacher(teacherId))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${store.studentById(gap.studentId)?.name ?? 'Siswa'} · ${aspectLabel(gap.aspect)} tingkat ${gap.level}',
            ),
            subtitle: Text(gap.reason),
          ),
      ],
      recordings: [
        for (final recording in store.accessibleRecordings.where(
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
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/guru/rekaman'),
              );
            },
          ),
      ],
    );
  }
}

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({
    super.key,
    required this.activeCount,
    required this.classCount,
    required this.diagnosticPercent,
    required this.pendingCount,
    required this.averages,
    required this.onStudents,
    required this.onRecordings,
    required this.supportRows,
    required this.recommendations,
    required this.gaps,
    required this.recordings,
  });
  final int activeCount, classCount, diagnosticPercent, pendingCount;
  final Map<String, int?> averages;
  final VoidCallback onStudents, onRecordings;
  final List<Widget> supportRows, recommendations, gaps, recordings;
  @override
  Widget build(BuildContext context) {
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
                    value: '$activeCount',
                    icon: Icons.people_alt_outlined,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: MetricTile(
                    label: 'Kelas',
                    value: '$classCount',
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
                    value: '$pendingCount',
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
                      value: averages[aspect],
                    ),
                ],
              ),
            );
            final support = TeacherPanel(
              title: 'Perlu pendampingan',
              trailing: TextButton(
                onPressed: onStudents,
                child: const Text('Semua siswa'),
              ),
              child: Column(
                children: [
                  ...supportRows,
                  if (supportRows.isEmpty)
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
        const SizedBox(height: AppTokens.space16),
        TeacherPanel(
          title: 'Rekomendasi aktif',
          child: Column(
            children: [
              ...recommendations,
              if (recommendations.isEmpty)
                const EmptyState(message: 'Belum ada rekomendasi aktif.'),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        TeacherPanel(
          title: 'Materi yang perlu disiapkan',
          child: Column(
            children: [
              ...gaps,
              if (gaps.isEmpty)
                const EmptyState(
                  message: 'Tidak ada kekurangan materi saat ini.',
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space24),
        TeacherPanel(
          title: 'Antrean evaluasi rekaman',
          trailing: TextButton(
            onPressed: onRecordings,
            child: const Text('Buka antrean'),
          ),
          child: Column(
            children: [
              ...recordings,
              if (recordings.isEmpty)
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

Map<String, int?> _averageScores(List<MasteryRecord> records) {
  final result = <String, int?>{};
  for (final aspect in const ['huruf', 'suku_kata', 'kata', 'kalimat']) {
    final scores = records
        .where((item) => item.aspect == aspect)
        .map((item) => item.score)
        .toList();
    result[aspect] = scores.isEmpty
        ? null
        : (scores.reduce((a, b) => a + b) / scores.length).round();
  }
  return result;
}

Map<int, Map<String, MasteryRecord>> _latestMasteryByStudent(
  List<MasteryRecord> records,
) {
  final ordered = records.toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  final result = <int, Map<String, MasteryRecord>>{};
  for (final record in ordered) {
    result.putIfAbsent(record.studentId, () => {})[record.aspect] = record;
  }
  return result;
}

class _AspectAverage extends StatelessWidget {
  const _AspectAverage({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        if (value == null)
          const SizedBox(width: 140, child: Text('Belum ada data'))
        else
          SizedBox(
            width: 140,
            child: LinearProgressIndicator(value: value! / 100, minHeight: 8),
          ),
        const SizedBox(width: AppTokens.space12),
        SizedBox(width: 60, child: Text(value == null ? '' : '$value%')),
      ],
    ),
  );
}
