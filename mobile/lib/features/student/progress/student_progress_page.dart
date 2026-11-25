import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
import '../mastery_history_chart.dart';
import '../student_demo_store.dart';
import '../student_widgets.dart';

class StudentProgressPage extends StatefulWidget {
  const StudentProgressPage({
    super.key,
    this.records,
    this.activities,
    this.historyLink,
    this.completedCount,
  });
  final List<MasteryRecord>? records;
  final List<StudentActivity>? activities;
  final Widget? historyLink;
  final int? completedCount;

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
    final records = widget.records ?? store.masteryHistory;
    final activities = widget.activities ?? store.activities;
    final latestMastery = widget.records == null
        ? store.latestMasteryByAspect
        : {for (final row in records) row.aspect: row};
    final diag = records.where((row) => row.source == 'diagnostik').toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final diagnosticScores = widget.records == null
        ? store.diagnosticScores
        : {
            for (final row in diag.where(
              (row) => row.sourceId == diag.first.sourceId,
            ))
              row.aspect: row.score,
          };
    final diagnosticScore = diagnosticScores[_aspect];
    final history = activities.where((item) => item.aspect == _aspect);
    final masteryHistory =
        records.where((item) => item.aspect == _aspect).toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final chartRecords = masteryHistory.reversed.toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const StudentPageHeading(
          title: 'Perkembangan Saya',
          subtitle: 'Lihat langkah hebat yang sudah kamu capai.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final aspect in _aspects)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    key: ValueKey('progress-aspect-$aspect'),
                    label: Text(aspectLabel(aspect)),
                    selected: _aspect == aspect,
                    onSelected: (_) => setState(() => _aspect = aspect),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StudentPanel(
          color: StudentColors.sunshine,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 36,
                color: Color(0xFFD79E22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terus semangat membaca!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.text,
                      ),
                    ),
                    Text(
                      '${widget.completedCount ?? activities.length} latihan sudah selesai',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTokens.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.completedCount ?? activities.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StudentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Langkah membacamu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _aspects.length; i++)
                _LearningStep(
                  aspect: _aspects[i],
                  mastery: latestMastery[_aspects[i]],
                  last: i == _aspects.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StudentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasil tes diagnostik',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 3),
              const Text(
                'Skor dari diagnostik terakhir, terpisah dari hasil latihan.',
                style: TextStyle(fontSize: 11, color: AppTokens.mutedText),
              ),
              const SizedBox(height: 10),
              if (diagnosticScores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Belum ada hasil diagnostik. Selesaikan tes membaca bersama Gurumu untuk melihat hasilnya.',
                  ),
                )
              else if (_aspects.any(
                (aspect) => !diagnosticScores.containsKey(aspect),
              )) ...[
                for (final aspect in _aspects)
                  if (diagnosticScores.containsKey(aspect))
                    ListTile(
                      key: ValueKey('diagnostic-score-$aspect'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(aspectLabel(aspect)),
                      trailing: Text('${diagnosticScores[aspect]}%'),
                    ),
              ] else ...[
                SizedBox(
                  height: 156,
                  width: double.infinity,
                  child: CustomPaint(
                    key: const ValueKey('student-progress-chart'),
                    painter: _StudentChartPainter(
                      scores: _aspects
                          .map((aspect) => diagnosticScores[aspect]!)
                          .toList(),
                      labels: const ['Huruf', 'Suku kata', 'Kata', 'Kalimat'],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    diagnosticScore == null
                        ? 'Belum ada skor diagnostik untuk ${aspectLabel(_aspect)}'
                        : '${aspectLabel(_aspect)}: $diagnosticScore% (${_statusForScore(diagnosticScore)})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTokens.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        StudentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perkembangan ${aspectLabel(_aspect)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 3),
              const Text(
                'Riwayat penguasaan dari tes diagnostik dan latihan.',
                style: TextStyle(fontSize: 11, color: AppTokens.mutedText),
              ),
              const SizedBox(height: 10),
              if (chartRecords.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Belum ada riwayat untuk aspek ini.'),
                )
              else
                MasteryHistoryChart(
                  chartKey: const ValueKey('student-mastery-history-chart'),
                  points: [
                    for (final record in chartRecords)
                      MasteryPoint(
                        recordedAt: record.recordedAt,
                        score: record.score,
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StudentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat latihan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Mulai berlatih untuk melihat kemajuanmu.'),
                )
              else
                for (final activity in history.take(4))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppTokens.success,
                    ),
                    title: Text(activity.title),
                    trailing: Text('${activity.score}%'),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StudentPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat penguasaan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (masteryHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Belum ada perubahan penguasaan untuk aspek ini.',
                  ),
                )
              else
                for (final record in masteryHistory.take(6))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${record.score}% · ${_status(record.status)}'),
                    subtitle: Text(
                      '${record.source == 'diagnostik' ? 'Tes diagnostik' : 'Latihan'} · ${_formatDate(record.recordedAt)}',
                    ),
                    trailing: Text('Tingkat ${record.level}'),
                  ),
            ],
          ),
        ),
        if (widget.historyLink != null) widget.historyLink!,
      ],
    );
  }

  String _status(String status) => switch (status) {
    'belum_dikuasai' => 'Belum dikuasai',
    'sedang_berlatih' => 'Sedang berlatih',
    'dikuasai' => 'Dikuasai',
    _ => 'Belum dinilai',
  };

  String _statusForScore(int score) => _status(
    score < 60
        ? 'belum_dikuasai'
        : score < 80
        ? 'sedang_berlatih'
        : 'dikuasai',
  );

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _LearningStep extends StatelessWidget {
  const _LearningStep({
    required this.aspect,
    required this.mastery,
    required this.last,
  });
  final String aspect;
  final MasteryRecord? mastery;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final score = mastery?.score;
    final status = mastery?.status;
    return SizedBox(
      height: 43,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (score ?? 0) >= 60
                        ? AppTokens.primary
                        : Colors.white,
                    border: Border.all(
                      color: (score ?? 0) >= 60
                          ? AppTokens.primary
                          : const Color(0xFFC8D7D2),
                      width: 2,
                    ),
                  ),
                  child: (score ?? 0) >= 60
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFD9E5E1)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aspectLabel(aspect),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: (score ?? 0) >= 60
                    ? AppTokens.text
                    : AppTokens.mutedText,
              ),
            ),
          ),
          Text(
            status == null
                ? 'Belum dinilai'
                : status == 'dikuasai'
                ? 'Dikuasai'
                : status == 'sedang_berlatih'
                ? 'Sedang berlatih'
                : 'Belum dikuasai',
            style: const TextStyle(fontSize: 10, color: AppTokens.mutedText),
          ),
        ],
      ),
    );
  }
}

class _StudentChartPainter extends CustomPainter {
  const _StudentChartPainter({required this.scores, required this.labels});
  final List<int> scores;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 26.0;
    const top = 7.0;
    final chartHeight = size.height - 27;
    final chartWidth = size.width - left - 5;
    final grid = Paint()
      ..color = AppTokens.outline
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      final label = TextPainter(
        text: TextSpan(
          text: '${100 - i * 25}',
          style: const TextStyle(fontSize: 9, color: AppTokens.mutedText),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - 5));
    }
    final slotWidth = chartWidth / scores.length;
    final bar = Paint()..color = AppTokens.primary;
    for (var i = 0; i < scores.length; i++) {
      final barHeight = chartHeight * scores[i].clamp(0, 100) / 100;
      final x = left + slotWidth * i + slotWidth * .26;
      final y = top + chartHeight - barHeight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, slotWidth * .48, barHeight),
          const Radius.circular(4),
        ),
        bar,
      );
      final label = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 8, color: AppTokens.mutedText),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: 'â€¦',
      )..layout(maxWidth: slotWidth);
      label.paint(
        canvas,
        Offset(
          left + slotWidth * i + (slotWidth - label.width) / 2,
          size.height - 13,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StudentChartPainter oldDelegate) =>
      scores.join(',') != oldDelegate.scores.join(',') ||
      labels.join(',') != oldDelegate.labels.join(',');
}
