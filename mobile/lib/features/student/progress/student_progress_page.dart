import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../mastery_history_chart.dart';
import '../student_demo_store.dart';
import '../student_widgets.dart';

class StudentProgressPage extends StatefulWidget {
  const StudentProgressPage({super.key});

  @override
  State<StudentProgressPage> createState() => _StudentProgressPageState();
}

class _StudentProgressPageState extends State<StudentProgressPage> {
  String _aspect = 'suku_kata';

  static const _aspects = ['huruf', 'suku_kata', 'kata', 'kalimat'];

  @override
  void initState() {
    super.initState();
    StudentDemoStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    StudentDemoStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = StudentDemoStore.instance;
    final latestMastery = store.latestMasteryByAspect;
    final diagnosticScores = store.diagnosticScores;
    final masteryHistory =
        store.masteryHistory.where((item) => item.aspect == _aspect).toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space16,
        AppTokens.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StreakBanner(
            streak: _streakDays(store.activities),
            total: store.activities.length,
          ),
          const SizedBox(height: AppTokens.space16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final aspect in _aspects)
                  Padding(
                    padding: const EdgeInsets.only(right: AppTokens.space8),
                    child: StudentChip(
                      key: ValueKey('progress-aspect-$aspect'),
                      label: aspectLabel(aspect),
                      selected: _aspect == aspect,
                      onTap: () => setState(() => _aspect = aspect),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          _LevelCard(mastery: latestMastery[_aspect], aspect: _aspect),
          const SizedBox(height: AppTokens.space16),
          _DiagnosticScoresPanel(
            scores: diagnosticScores,
            aspects: _aspects,
            selectedAspect: _aspect,
          ),
          _WeeklyChartCard(records: masteryHistory, aspect: _aspect),
          const SizedBox(height: AppTokens.space16),
          StudentPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StudentSectionLabel('Perkembangan ${aspectLabel(_aspect)}'),
                const SizedBox(height: AppTokens.space8),
                if (masteryHistory.isEmpty)
                  const Text(
                    'Belum ada riwayat untuk aspek ini.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTokens.mutedText,
                    ),
                  )
                else
                  MasteryHistoryChart(
                    chartKey: const ValueKey('student-mastery-history-chart'),
                    points: [
                      for (final record in masteryHistory)
                        MasteryPoint(
                          recordedAt: record.recordedAt,
                          score: record.score,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          const SizedBox(height: AppTokens.space16),
          _HistoryPanel(records: masteryHistory.reversed.toList()),
          const SizedBox(height: AppTokens.space16),
          _ActivityHistoryPanel(
            history: store.activities
                .where((item) => item.aspect == _aspect)
                .toList(),
          ),
        ],
      ),
    );
  }
}

int _streakDays(List<StudentActivity> activities) {
  final days =
      activities
          .map(
            (item) => DateTime(
              item.finishedAt.year,
              item.finishedAt.month,
              item.finishedAt.day,
            ),
          )
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  if (days.isEmpty) return 0;
  var streak = 1;
  for (var i = 1; i < days.length; i++) {
    if (days[i - 1].difference(days[i]).inDays != 1) break;
    streak++;
  }
  return streak;
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak, required this.total});

  final int streak;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppTokens.space20),
    decoration: BoxDecoration(
      color: AppTokens.sunshine,
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
    ),
    child: Row(
      children: [
        Text(
          '$streak',
          style: const TextStyle(
            fontSize: 38,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: AppTokens.warning,
          ),
        ),
        const SizedBox(width: AppTokens.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'hari beruntun',
                style: TextStyle(fontSize: 11.5, color: AppTokens.mutedText),
              ),
              const Text(
                'Terus bertumbuh!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kamu sudah membaca $total kali.',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.mastery, required this.aspect});

  final MasteryRecord? mastery;
  final String aspect;

  String get _status => switch (mastery?.status) {
    'dikuasai' => 'Dikuasai',
    'sedang_berlatih' => 'Sedang berlatih',
    _ => 'Belum dikuasai',
  };

  @override
  Widget build(BuildContext context) {
    final level = (mastery?.level ?? 1).clamp(1, 4);
    final score = mastery?.score ?? 0;
    return StudentPanel(
      padding: const EdgeInsets.all(AppTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentSectionLabel(
            'Kemajuan ${aspectLabel(aspect)}',
            color: AppTokens.primary,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space20),
          Row(
            children: [
              for (var step = 1; step <= 4; step++) ...[
                if (step > 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: step <= level
                          ? AppTokens.primary.withValues(alpha: .35)
                          : AppTokens.outline,
                    ),
                  ),
                _StepDot(step: step, level: level),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.space16),
          Center(
            child: Text(
              level >= 4
                  ? 'Kamu sudah di tingkat tertinggi!'
                  : 'Tinggal sedikit lagi untuk naik tingkat!',
              style: const TextStyle(fontSize: 12, color: AppTokens.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.step, required this.level});

  final int step;
  final int level;

  @override
  Widget build(BuildContext context) {
    final done = step < level;
    final current = step == level;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppTokens.primary
            : current
            ? AppTokens.accent
            : AppTokens.surface,
        border: Border.all(
          color: done
              ? AppTokens.primary
              : current
              ? AppTokens.accent
              : AppTokens.outline,
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : Text(
              '$step',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: current ? AppTokens.text : AppTokens.mutedText,
              ),
            ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.records, required this.aspect});

  final List<MasteryRecord> records;
  final String aspect;

  @override
  Widget build(BuildContext context) {
    final weekly = _weeklyScores(records);
    if (weekly.isEmpty) {
      return StudentPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4 minggu terakhir',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTokens.text,
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            const StudentEmptyState(
              message: 'Belum ada data kemajuan untuk aspek ini.',
              icon: Icons.show_chart_outlined,
            ),
          ],
        ),
      );
    }
    return StudentPanel(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '4 minggu terakhir',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          SizedBox(
            key: const ValueKey('student-progress-chart'),
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < weekly.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (i == weekly.length - 1)
                            Text(
                              '${weekly[i].score}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTokens.text,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Container(
                            height: 90 * weekly[i].score / 100,
                            decoration: BoxDecoration(
                              color: i == weekly.length - 1
                                  ? AppTokens.primary
                                  : const Color(0xFFDCE8EC),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space8),
          Row(
            children: [
              Text(
                _shortDate(weekly.first.date),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppTokens.mutedText,
                ),
              ),
              const Spacer(),
              Text(
                _shortDate(weekly.last.date),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppTokens.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<({DateTime date, int score})> _weeklyScores(List<MasteryRecord> records) {
  if (records.isEmpty) return const [];
  final latest = records.last.recordedAt;
  final buckets = <int, List<int>>{};
  for (final record in records) {
    final weeksAgo = latest.difference(record.recordedAt).inDays ~/ 7;
    if (weeksAgo > 4) continue;
    buckets.putIfAbsent(4 - weeksAgo, () => []).add(record.score);
  }
  return [
    for (final entry in buckets.entries)
      (
        date: latest.subtract(Duration(days: (4 - entry.key) * 7)),
        score: (entry.value.reduce((a, b) => a + b) / entry.value.length)
            .round(),
      ),
  ];
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _shortDate(DateTime date) => '${date.day} ${_months[date.month - 1]}';

class _DiagnosticScoresPanel extends StatelessWidget {
  const _DiagnosticScoresPanel({
    required this.scores,
    required this.aspects,
    required this.selectedAspect,
  });

  final Map<String, int> scores;
  final List<String> aspects;
  final String selectedAspect;

  @override
  Widget build(BuildContext context) => StudentPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentSectionLabel('Hasil tes diagnostik'),
        const SizedBox(height: AppTokens.space8),
        if (scores.isEmpty)
          const Text(
            'Belum ada hasil diagnostik. Selesaikan tes membaca bersama Gurumu.',
            style: TextStyle(fontSize: 12.5, color: AppTokens.mutedText),
          )
        else
          for (final aspect in aspects)
            if (scores.containsKey(aspect))
              StudentProgressBar(
                label: aspectLabel(aspect),
                value: scores[aspect]!,
              ),
        const SizedBox(height: AppTokens.space8),
        Text(
          '${aspectLabel(selectedAspect)}: ${scores[selectedAspect] ?? 0}%',
          style: const TextStyle(fontSize: 11.5, color: AppTokens.mutedText),
        ),
      ],
    ),
  );
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.records});

  final List<MasteryRecord> records;

  @override
  Widget build(BuildContext context) => StudentPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentSectionLabel('Riwayat penguasaan'),
        const SizedBox(height: AppTokens.space8),
        if (records.isEmpty)
          const Text(
            'Belum ada perubahan penguasaan untuk aspek ini.',
            style: TextStyle(fontSize: 12.5, color: AppTokens.mutedText),
          )
        else
          for (final record in records.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.score}% · ${_statusLabel(record.status)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.text,
                          ),
                        ),
                        Text(
                          '${record.source == 'diagnostik' ? 'Tes diagnostik' : 'Latihan'} · ${_shortDate(record.recordedAt)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTokens.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Tingkat ${record.level}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTokens.mutedText,
                    ),
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}

class _ActivityHistoryPanel extends StatelessWidget {
  const _ActivityHistoryPanel({required this.history});

  final List<StudentActivity> history;

  @override
  Widget build(BuildContext context) => StudentPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentSectionLabel('Riwayat latihan'),
        const SizedBox(height: AppTokens.space8),
        if (history.isEmpty)
          const Text(
            'Mulai berlatih untuk melihat kemajuanmu.',
            style: TextStyle(fontSize: 12.5, color: AppTokens.mutedText),
          )
        else
          for (final activity in history.take(4))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.text,
                          ),
                        ),
                        Text(
                          '${aspectLabel(activity.aspect)} · ${_shortDate(activity.finishedAt)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTokens.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${activity.score}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.primary,
                    ),
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}

String _statusLabel(String status) => switch (status) {
  'dikuasai' => 'Dikuasai',
  'sedang_berlatih' => 'Sedang berlatih',
  _ => 'Belum dikuasai',
};
