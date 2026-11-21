import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../teacher_demo_store.dart';
import '../teacher_widgets.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  int? _studentId;
  String _aspect = 'suku_kata';
  String _period = '4 minggu';

  @override
  Widget build(BuildContext context) {
    final store = TeacherDemoStore.instance;
    final scores = _seriesFor(_studentId, _aspect, store);
    final studentName = _studentId == null
        ? 'Rata-rata kelas'
        : store.studentById(_studentId!)?.name ?? 'Siswa';
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space16),
      children: [
        const TeacherPageHeading(
          title: 'Grafik Perkembangan',
          subtitle: 'Pantau perubahan skor membaca dari waktu ke waktu.',
        ),
        Wrap(
          spacing: AppTokens.space12,
          runSpacing: AppTokens.space12,
          children: [
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _studentId,
                decoration: const InputDecoration(
                  labelText: 'Siswa atau kelas',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Rata-rata kelas'),
                  ),
                  for (final student in store.activeStudents)
                    DropdownMenuItem<int?>(
                      value: student.id,
                      child: Text(student.name),
                    ),
                ],
                onChanged: (value) => setState(() => _studentId = value),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _aspect,
                decoration: const InputDecoration(labelText: 'Aspek'),
                items: const [
                  DropdownMenuItem(value: 'huruf', child: Text('Huruf')),
                  DropdownMenuItem(
                    value: 'suku_kata',
                    child: Text('Suku kata'),
                  ),
                  DropdownMenuItem(value: 'kata', child: Text('Kata')),
                  DropdownMenuItem(
                    value: 'kalimat',
                    child: Text('Kalimat sederhana'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _aspect = value ?? _aspect),
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _period,
                decoration: const InputDecoration(labelText: 'Periode'),
                items: const [
                  DropdownMenuItem(value: '4 minggu', child: Text('4 minggu')),
                  DropdownMenuItem(value: '8 minggu', child: Text('8 minggu')),
                ],
                onChanged: (value) =>
                    setState(() => _period = value ?? _period),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space16),
        TeacherPanel(
          title: '$studentName • ${aspectLabel(_aspect)}',
          trailing: StatusBadge(label: _period),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: CustomPaint(
                  key: const ValueKey('progress-chart'),
                  painter: _ProgressChartPainter(
                    scores: scores,
                    color: AppTokens.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space8),
              const Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppTokens.space8,
                runSpacing: AppTokens.space4,
                children: [
                  Text('Minggu 1'),
                  Text('Minggu 2'),
                  Text('Minggu 3'),
                  Text('Minggu 4'),
                ],
              ),
              const SizedBox(height: AppTokens.space16),
              Text(
                'Skor terakhir ${scores.last}% • ${masteryLabel(scores.last)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        const TeacherPanel(
          child: Text(
            'Status penguasaan menggambarkan kemajuan belajar dan bukan diagnosis medis atau gangguan belajar.',
          ),
        ),
      ],
    );
  }
}

List<int> _seriesFor(int? studentId, String aspect, TeacherDemoStore store) {
  if (studentId == 1) {
    return switch (aspect) {
      'huruf' => [62, 74, 88, 100],
      'suku_kata' => [0, 28, 45, 60],
      'kata' => [42, 50, 62, 70],
      _ => [35, 45, 54, 60],
    };
  }
  if (studentId == 2) {
    return switch (aspect) {
      'huruf' => [48, 60, 72, 80],
      'suku_kata' => [30, 48, 62, 75],
      'kata' => [25, 36, 46, 55],
      _ => [20, 32, 40, 45],
    };
  }
  if (studentId != null) {
    final score = store.studentById(studentId)?.scores?[aspect] ?? 65;
    return [
      math.max(0, score - 24),
      math.max(0, score - 16),
      math.max(0, score - 8),
      score,
    ];
  }
  final scores = store.diagnosticStudents
      .map((student) => student.scores![aspect]!)
      .toList();
  final avg = scores.isEmpty
      ? 0
      : (scores.reduce((a, b) => a + b) / scores.length).round();
  return [
    math.max(0, avg - 24),
    math.max(0, avg - 16),
    math.max(0, avg - 8),
    avg,
  ];
}

class _ProgressChartPainter extends CustomPainter {
  const _ProgressChartPainter({required this.scores, required this.color});

  final List<int> scores;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const top = 12.0;
    const right = 12.0;
    const bottom = 18.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final gridPaint = Paint()
      ..color = AppTokens.outline
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var value = 0; value <= 100; value += 20) {
      final y = chart.bottom - chart.height * value / 100;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      textPainter.text = TextSpan(
        text: '$value',
        style: const TextStyle(color: AppTokens.mutedText, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final x = chart.left + chart.width * i / (scores.length - 1);
      final y = chart.bottom - chart.height * scores[i] / 100;
      points.add(Offset(x, y));
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 6, Paint()..color = AppTokens.surface);
      canvas.drawCircle(point, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) =>
      oldDelegate.scores != scores || oldDelegate.color != color;
}
