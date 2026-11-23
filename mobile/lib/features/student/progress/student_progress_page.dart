import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../teacher/teacher_demo_store.dart';
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
  Widget build(BuildContext context) {
    final store = StudentDemoStore.instance;
    final score = store.diagnosticScores[_aspect];
    final history = store.activities.where((item) => item.aspect == _aspect);
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
                      '${store.activities.length} latihan sudah selesai',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTokens.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${store.activities.length}',
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
                  score: store.diagnosticScores[_aspects[i]],
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
                'Hasil diagnostik per aspek',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 3),
              const Text(
                'Skor dari tes diagnostik terakhir',
                style: TextStyle(fontSize: 11, color: AppTokens.mutedText),
              ),
              const SizedBox(height: 10),
              if (store.diagnosticScores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Belum ada hasil tes diagnostik.'),
                )
              else ...[
                SizedBox(
                  height: 156,
                  width: double.infinity,
                  child: CustomPaint(
                    key: const ValueKey('student-progress-chart'),
                    painter: _StudentChartPainter(
                      scores: _aspects
                          .map((aspect) => store.diagnosticScores[aspect] ?? 0)
                          .toList(),
                      labels: const ['Huruf', 'Suku kata', 'Kata', 'Kalimat'],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Skor: ${score ?? 0}% (${_status(score ?? 0)})',
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
      ],
    );
  }

  String _status(int score) => score < 60
      ? 'Belum dikuasai'
      : score < 80
      ? 'Sedang berlatih'
      : 'Dikuasai';
}

class _LearningStep extends StatelessWidget {
  const _LearningStep({
    required this.aspect,
    required this.score,
    required this.last,
  });
  final String aspect;
  final int? score;
  final bool last;

  @override
  Widget build(BuildContext context) => SizedBox(
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
                  color: (score ?? 0) >= 60 ? AppTokens.primary : Colors.white,
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
              color: (score ?? 0) >= 60 ? AppTokens.text : AppTokens.mutedText,
            ),
          ),
        ),
        Text(
          score == null
              ? 'Belum dinilai'
              : (score ?? 0) >= 80
              ? 'Dikuasai'
              : (score ?? 0) >= 60
              ? 'Sedang berlatih'
              : 'Belum dikuasai',
          style: const TextStyle(fontSize: 10, color: AppTokens.mutedText),
        ),
      ],
    ),
  );
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
