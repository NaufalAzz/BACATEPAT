import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class MasteryPoint {
  const MasteryPoint({required this.recordedAt, required this.score});

  final DateTime recordedAt;
  final int score;
}

class MasteryHistoryChart extends StatelessWidget {
  const MasteryHistoryChart({
    required this.points,
    required this.chartKey,
    super.key,
  });

  final List<MasteryPoint> points;
  final Key chartKey;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 156,
    width: double.infinity,
    child: CustomPaint(
      key: chartKey,
      painter: _MasteryHistoryPainter(points: points),
    ),
  );
}

class _MasteryHistoryPainter extends CustomPainter {
  const _MasteryHistoryPainter({required this.points});

  final List<MasteryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const top = 8.0;
    const bottom = 23.0;
    const right = 6.0;
    final plotHeight = size.height - top - bottom;
    final plotWidth = size.width - left - right;
    final gridPaint = Paint()
      ..color = AppTokens.outline
      ..strokeWidth = 1;
    for (var tick = 0; tick <= 4; tick++) {
      final y = top + plotHeight * tick / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      _drawLabel(
        canvas,
        '${100 - tick * 25}',
        Offset(1, y - 5),
        maxWidth: left - 5,
      );
    }

    if (points.isEmpty) return;
    final firstTime = points.first.recordedAt;
    final lastTime = points.last.recordedAt;
    final duration = lastTime.difference(firstTime).inMicroseconds;
    final positions = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final elapsed = point.recordedAt.difference(firstTime).inMicroseconds;
      final x = points.length == 1 || duration == 0
          ? left + plotWidth / 2
          : left + plotWidth * elapsed / duration;
      final y = top + plotHeight * (100 - point.score.clamp(0, 100)) / 100;
      positions.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = AppTokens.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (positions.length > 1) {
      final path = Path()..moveTo(positions.first.dx, positions.first.dy);
      for (final point in positions.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }
    final pointPaint = Paint()..color = AppTokens.primary;
    for (final point in positions) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }

    _drawLabel(canvas, _formatDate(firstTime), Offset(left, size.height - 15));
    if (points.length > 1) {
      final painter = _labelPainter(_formatDate(lastTime))..layout();
      painter.paint(
        canvas,
        Offset(size.width - right - painter.width, size.height - 15),
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    double maxWidth = double.infinity,
  }) {
    final painter = _labelPainter(text)..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  TextPainter _labelPainter(String text) => TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(fontSize: 9, color: AppTokens.mutedText),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(covariant _MasteryHistoryPainter oldDelegate) =>
      points.length != oldDelegate.points.length ||
      points.indexed.any(
        (entry) =>
            entry.$2.score != oldDelegate.points[entry.$1].score ||
            entry.$2.recordedAt != oldDelegate.points[entry.$1].recordedAt,
      );
}
