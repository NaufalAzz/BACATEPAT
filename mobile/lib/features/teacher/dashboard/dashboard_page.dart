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
    final supportCount = active
        .where((student) => studentStore.needsSupportForStudent(student.id))
        .length;
    final activeTests = store.accessibleDiagnostics
        .where((item) => item.status == 'aktif')
        .length;
    final scores = averages.values.whereType<int>().toList();
    final averageScore = scores.isEmpty
        ? null
        : (scores.reduce((a, b) => a + b) / scores.length).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space16),
            child: Text(
              'Selamat pagi, ${store.teacherName}',
              style: const TextStyle(fontSize: 15, color: AppTokens.text),
            ),
          ),
          if (store.pendingRecordingCount > 0)
            _PendingRecordingNotice(count: store.pendingRecordingCount),
          if (store.pendingRecordingCount > 0)
            const SizedBox(height: AppTokens.space16),
          _MetricsGrid(
            activeCount: active.length,
            classCount: store.accessibleClasses.length,
            diagnosticPercent: diagnosticPercent,
            activeTests: activeTests,
            supportCount: supportCount,
            averageScore: averageScore,
          ),
          const SizedBox(height: AppTokens.space24),
          _SkillsAndSupportSection(
            averages: averages,
            store: store,
            studentStore: studentStore,
            latestByStudent: latestByStudent,
            teacherId: teacherId,
          ),
          const SizedBox(height: AppTokens.space20),
          _ActiveRecommendationsSection(
            store: store,
            studentStore: studentStore,
            teacherId: teacherId,
          ),
          const SizedBox(height: AppTokens.space20),
          _MaterialGapsSection(
            store: store,
            studentStore: studentStore,
            teacherId: teacherId,
          ),
          const SizedBox(height: AppTokens.space24),
          _RecordingQueueSection(store: store),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.activeCount,
    required this.classCount,
    required this.diagnosticPercent,
    required this.activeTests,
    required this.supportCount,
    required this.averageScore,
  });

  final int activeCount;
  final int classCount;
  final int diagnosticPercent;
  final int activeTests;
  final int supportCount;
  final int? averageScore;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 800 ? 2 : 1;
      final tileWidth =
          (constraints.maxWidth - AppTokens.space12 * (columns - 1)) / columns;
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
              tint: AppTokens.primary,
              subtitle: 'di $classCount kelas',
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: MetricTile(
              label: 'Tes aktif',
              value: '$activeTests',
              icon: Icons.assignment_outlined,
              tint: AppTokens.secondary,
              subtitle: '$diagnosticPercent siswa sudah selesai',
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: MetricTile(
              label: 'Perlu dampingan',
              value: '$supportCount',
              icon: Icons.warning_amber_rounded,
              tint: AppTokens.coral,
              subtitle: 'Tindak lanjut siswa',
            ),
          ),
          SizedBox(
            width: tileWidth,
            child: MetricTile(
              label: 'Rata-rata kelas',
              value: '${averageScore ?? 0}',
              icon: Icons.bar_chart_rounded,
              tint: AppTokens.warning,
            ),
          ),
        ],
      );
    },
  );
}

class _PendingRecordingNotice extends StatelessWidget {
  const _PendingRecordingNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppTokens.space16),
    decoration: BoxDecoration(
      color: AppTokens.sunshine,
      border: Border.all(color: const Color(0xFFEBD78D)),
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.mic_none_rounded,
              size: 20,
              color: AppTokens.warning,
            ),
            const SizedBox(width: AppTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count rekaman menunggu penilaian',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Dua rekaman sudah menunggu lebih dari 24 jam.',
                    style: TextStyle(fontSize: 11.5, color: AppTokens.warning),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/guru/rekaman'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Nilai sekarang'),
          ),
        ),
      ],
    ),
  );
}

class _SkillsAndSupportSection extends StatelessWidget {
  const _SkillsAndSupportSection({
    required this.averages,
    required this.store,
    required this.studentStore,
    required this.latestByStudent,
    required this.teacherId,
  });

  final Map<String, int?> averages;
  final TeacherDemoStore store;
  final StudentDemoStore studentStore;
  final Map<int, Map<String, MasteryRecord>> latestByStudent;
  final int teacherId;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final skillsPanel = TeacherPanel(
        eyebrow: 'Kemampuan membaca',
        title: store.accessibleClasses.isEmpty
            ? 'Ringkasan kelas'
            : 'Ringkasan Kelas ${store.className(store.accessibleClasses.first.id).replaceFirst('Kelas ', '')}',
        trailing: TextButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/guru/perkembangan'),
          style: TextButton.styleFrom(minimumSize: const Size(0, 30)),
          child: const Text(
            'Lihat grafik  ›',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTokens.primary,
            ),
          ),
        ),
        child: Column(
          children: [
            for (final aspect in const [
              'huruf',
              'suku_kata',
              'kata',
              'kalimat',
            ])
              _AspectAverageCard(
                label: aspectLabel(aspect),
                value: averages[aspect],
              ),
          ],
        ),
      );

      final supportStudents = store.activeStudents
          .where((item) => studentStore.needsSupportForStudent(item.id))
          .toList();

      final supportPanel = TeacherPanel(
        title: 'Perlu pendampingan',
        trailing: TextButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/guru/siswa'),
          child: Text(
            'Semua siswa',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTokens.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: supportStudents.isEmpty
            ? const EmptyState(
                message: 'Tidak ada siswa yang perlu pendampingan saat ini.',
                icon: Icons.celebration_rounded,
                iconColor: AppTokens.success,
              )
            : Column(
                children: [
                  for (final student in supportStudents)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: TeacherAvatar(name: student.name),
                      title: Text(
                        student.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${store.className(student.classId)} • ${masterySummaryFor({for (final entry in (latestByStudent[student.id] ?? const <String, MasteryRecord>{}).entries) entry.key: entry.value.score})}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTokens.mutedText),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppTokens.mutedText,
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/guru/siswa/detail',
                        arguments: student.id,
                      ),
                    ),
                ],
              ),
      );

      if (constraints.maxWidth < 760) {
        return Column(
          children: [
            skillsPanel,
            const SizedBox(height: AppTokens.space16),
            supportPanel,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: skillsPanel),
          const SizedBox(width: AppTokens.space16),
          Expanded(child: supportPanel),
        ],
      );
    },
  );
}

class _ActiveRecommendationsSection extends StatelessWidget {
  const _ActiveRecommendationsSection({
    required this.store,
    required this.studentStore,
    required this.teacherId,
  });

  final TeacherDemoStore store;
  final StudentDemoStore studentStore;
  final int teacherId;

  @override
  Widget build(BuildContext context) {
    final recommendations = studentStore.activeRecommendationsForTeacher(
      teacherId,
    );
    return TeacherPanel(
      title: 'Rekomendasi aktif',
      trailing: recommendations.isNotEmpty
          ? Text(
              '${recommendations.length} aktif',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTokens.primary,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
      child: recommendations.isEmpty
          ? const EmptyState(
              message: 'Belum ada rekomendasi aktif.\nTambah rekomendasi dari halaman detail siswa.',
              icon: Icons.recommend_rounded,
            )
          : Column(
              children: [
                for (final recommendation in recommendations)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.space8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTokens.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusMedium,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: AppTokens.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store
                                        .studentById(recommendation.studentId)
                                        ?.name ??
                                    'Siswa',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                store
                                        .materialById(recommendation.materialId)
                                        ?.title ??
                                    'Materi tidak tersedia',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTokens.mutedText),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Tingkat ${recommendation.level}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTokens.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: AppTokens.space8),
                        StatusBadge(
                          label: recommendation.source == 'guru'
                              ? 'Dari Guru'
                              : 'Sistem',
                          variant: recommendation.source == 'guru'
                              ? StatusVariant.active
                              : StatusVariant.info,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MaterialGapsSection extends StatelessWidget {
  const _MaterialGapsSection({
    required this.store,
    required this.studentStore,
    required this.teacherId,
  });

  final TeacherDemoStore store;
  final StudentDemoStore studentStore;
  final int teacherId;

  @override
  Widget build(BuildContext context) {
    final gaps = studentStore.materialGapsForTeacher(teacherId);
    return TeacherPanel(
      title: 'Materi yang perlu disiapkan',
      trailing: gaps.isNotEmpty
          ? Text(
              '${gaps.length} item',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTokens.warning,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
      child: gaps.isEmpty
          ? const EmptyState(
              message: 'Tidak ada kekurangan materi saat ini.',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppTokens.success,
            )
          : Column(
              children: [
                for (final gap in gaps)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.space8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTokens.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusMedium,
                            ),
                          ),
                          child: Icon(
                            Icons.library_add_rounded,
                            color: AppTokens.warning,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.studentById(gap.studentId)?.name ??
                                    'Siswa',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${aspectLabel(gap.aspect)} tingkat ${gap.level}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTokens.mutedText),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          gap.reason,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTokens.warning,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RecordingQueueSection extends StatelessWidget {
  const _RecordingQueueSection({required this.store});

  final TeacherDemoStore store;

  @override
  Widget build(BuildContext context) {
    final pending = store.accessibleRecordings
        .where((item) => item.status == 'terkirim')
        .toList();

    return TeacherPanel(
      title: 'Antrean evaluasi rekaman',
      trailing: TextButton(
        onPressed: () =>
            Navigator.pushReplacementNamed(context, '/guru/rekaman'),
        child: Text(
          'Buka antrean',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppTokens.primary, fontWeight: FontWeight.w700),
        ),
      ),
      child: pending.isEmpty
          ? const EmptyState(
              message: 'Tidak ada rekaman yang menunggu evaluasi.',
              icon: Icons.mic_none_rounded,
            )
          : Column(
              children: [
                for (final recording in pending)
                  Builder(
                    builder: (context) {
                      final student = store.studentById(recording.studentId)!;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppTokens.secondary.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: AppTokens.secondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${aspectLabel(recording.aspect)} • ${recording.durationSeconds} detik',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTokens.mutedText),
                        ),
                        trailing: StatusBadge(
                          label: 'Menunggu',
                          variant: StatusVariant.pending,
                        ),
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          '/guru/rekaman',
                        ),
                      );
                    },
                  ),
              ],
            ),
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

class _AspectAverageCard extends StatelessWidget {
  const _AspectAverageCard({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final progressColor = hasValue
        ? (value! < 60
              ? AppTokens.warning
              : value! < 80
              ? AppTokens.accent
              : AppTokens.success)
        : AppTokens.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusRound),
              child: LinearProgressIndicator(
                value: hasValue ? value! / 100 : 0,
                minHeight: 10,
                backgroundColor: AppTokens.outline,
                color: progressColor,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          SizedBox(
            width: 56,
            child: Text(
              hasValue ? '$value%' : '—',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: hasValue ? progressColor : AppTokens.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
