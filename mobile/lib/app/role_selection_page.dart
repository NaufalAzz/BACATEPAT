import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  static const _welcomeDuration = Duration(milliseconds: 5000);
  static const _welcomeMotionDuration = Duration(milliseconds: 3600);

  late final AnimationController _bookOpen;
  late final CurvedAnimation _bookOpening;
  Timer? _finish;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _bookOpen = AnimationController(
      vsync: this,
      duration: _welcomeMotionDuration,
    );
    _bookOpening = CurvedAnimation(parent: _bookOpen, curve: Curves.linear);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bookOpen.forward();
      _finish = Timer(_welcomeDuration, _goToLogin);
    });
  }

  @override
  void dispose() {
    _finish?.cancel();
    _bookOpening.dispose();
    _bookOpen.dispose();
    super.dispose();
  }

  void _goToLogin() {
    if (!mounted || _leaving) return;
    _leaving = true;
    _finish?.cancel();
    _bookOpen.stop();
    Navigator.pushReplacementNamed(context, '/siswa/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF9F1),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              left: -45,
              top: 48,
              child: _Orb(size: 170, color: Color(0xFFFBE6B2)),
            ),
            const Positioned(
              right: -55,
              top: -80,
              child: _Orb(size: 190, color: Color(0xFFE7EBE8)),
            ),
            const Positioned(
              right: -85,
              bottom: 82,
              child: _Orb(size: 255, color: Color(0xFFF1DED5)),
            ),
            const Positioned(
              left: -80,
              bottom: -80,
              child: _Orb(size: 160, color: Color(0xFFD8E8E1)),
            ),
            Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 18, 0),
                    child: TextButton(
                      key: const ValueKey('welcome-skip'),
                      onPressed: _goToLogin,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F3F0),
                        foregroundColor: AppTokens.mutedText,
                        minimumSize: const Size(64, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text(
                        'Lewati',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: constraints.maxHeight < 700 ? 190 : 220,
                  width: constraints.maxWidth,
                  child: _WelcomeIllustration(open: _bookOpening),
                ),
                const SizedBox(height: 26),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BrandLetter(),
                    SizedBox(width: 10),
                    Text(
                      'BacaTepat',
                      style: TextStyle(
                        color: AppTokens.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 34),
                  child: Text(
                    'Teman belajar membaca yang tumbuh\nbersamamu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTokens.mutedText,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 150,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E5DF),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration({required this.open});

  final Animation<double> open;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: open,
    builder: (context, _) {
      final progress = open.value;
      final bookEntrance = Curves.easeOutCubic.transform(
        _segment(progress, 0, .25),
      );
      final bookOpacity = Curves.easeOut.transform(_segment(progress, 0, .20));

      return Center(
        child: SizedBox(
          key: const ValueKey('welcome-book-animation'),
          width: 240,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                key: const ValueKey('welcome-story-orbit'),
                size: const Size(240, 220),
                painter: _StoryOrbitPainter(progress: progress),
              ),
              Transform.translate(
                key: const ValueKey('welcome-book-rise'),
                offset: Offset(0, 16 * (1 - bookEntrance)),
                child: Transform.scale(
                  key: const ValueKey('welcome-book-scale'),
                  scale: .88 + .12 * bookEntrance,
                  child: Opacity(
                    key: const ValueKey('welcome-book-fade'),
                    opacity: bookOpacity,
                    child: Image.asset(
                      key: const ValueKey('welcome-book-logo'),
                      'assets/illustrations/welcome-open-book.png',
                      width: 180,
                      height: 128,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              _StoryLetter(
                id: 'b',
                asset: 'assets/illustrations/welcome-letter-b.png',
                target: const Offset(14, 26),
                origin: const Offset(78, 70),
                start: .14,
                finish: .59,
                arc: -30,
                rotation: -.12,
                progress: progress,
              ),
              _StoryLetter(
                id: 'a',
                asset: 'assets/illustrations/welcome-letter-a.png',
                target: const Offset(178, 26),
                origin: const Offset(158, 72),
                start: .30,
                finish: .77,
                arc: -34,
                rotation: .11,
                progress: progress,
              ),
              _StoryLetter(
                id: 'ca',
                asset: 'assets/illustrations/welcome-letter-ca.png',
                target: const Offset(14, 146),
                origin: const Offset(82, 140),
                start: .46,
                finish: .90,
                arc: 22,
                rotation: -.08,
                progress: progress,
              ),
              CustomPaint(
                key: const ValueKey('welcome-book-sparkles'),
                size: const Size(220, 220),
                painter: _StorySparklePainter(progress: progress),
              ),
            ],
          ),
        ),
      );
    },
  );
}

double _segment(double value, double start, double end) =>
    ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();

class _StoryLetter extends StatelessWidget {
  const _StoryLetter({
    required this.id,
    required this.asset,
    required this.target,
    required this.origin,
    required this.start,
    required this.finish,
    required this.arc,
    required this.rotation,
    required this.progress,
  });

  final String id;
  final String asset;
  final Offset target;
  final Offset origin;
  final double start;
  final double finish;
  final double arc;
  final double rotation;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final travel = Curves.easeOutCubic.transform(
      _segment(progress, start, finish),
    );
    final fade = Curves.easeOut.transform(_segment(travel, .52, .84));
    final startOffset = origin - target;
    final offset =
        Offset.lerp(startOffset, Offset.zero, travel)! +
        Offset(0, arc * math.sin(math.pi * travel));

    return Positioned(
      key: ValueKey('welcome-letter-$id'),
      left: target.dx,
      top: target.dy,
      child: Opacity(
        key: ValueKey('welcome-letter-$id-fade'),
        opacity: fade,
        child: Transform.translate(
          key: ValueKey('welcome-letter-$id-move'),
          offset: offset,
          child: Transform.rotate(
            angle: rotation * (1 - travel),
            child: Image.asset(asset, width: 48, height: 48),
          ),
        ),
      ),
    );
  }
}

class _StoryOrbitPainter extends CustomPainter {
  const _StoryOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final innerOrbit = Paint()
      ..color = AppTokens.outline.withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 88, innerOrbit);

    final reveal = Curves.easeOutCubic.transform(_segment(progress, .04, .96));
    final visibleDots = (32 * reveal).ceil();
    for (var dot = 0; dot < visibleDots; dot++) {
      final angle = -math.pi / 2 + 2 * math.pi * dot / 32;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * 108;
      canvas.drawCircle(
        point,
        1.2,
        Paint()..color = AppTokens.outline.withValues(alpha: .55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StoryOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StorySparklePainter extends CustomPainter {
  const _StorySparklePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const starts = [.26, .40, .54];
    const finishes = [.65, .80, .94];
    const origins = [Offset(74, 60), Offset(150, 105), Offset(72, 146)];
    const targets = [Offset(108, 8), Offset(211, 112), Offset(110, 211)];
    const arcs = [-10.0, -8.0, 10.0];
    const colors = [Color(0xFFE6AC4D), Color(0xFF75AFA3), Color(0xFFE6AC4D)];
    for (var index = 0; index < starts.length; index++) {
      final travel = Curves.easeOutCubic.transform(
        _segment(progress, starts[index], finishes[index]),
      );
      final fade = Curves.easeOut.transform(
        _segment(progress, starts[index], starts[index] + .10),
      );
      final offset =
          Offset.lerp(origins[index], targets[index], travel)! +
          Offset(0, arcs[index] * math.sin(math.pi * travel));
      final sizeFactor = .55 + .45 * math.sin(math.pi * travel / 2);
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.scale(sizeFactor);
      final path = Path()
        ..moveTo(0, -5)
        ..quadraticBezierTo(1, -1, 5, 0)
        ..quadraticBezierTo(1, 1, 0, 5)
        ..quadraticBezierTo(-1, 1, -5, 0)
        ..quadraticBezierTo(-1, -1, 0, -5)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = colors[index].withValues(alpha: fade * .72),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StorySparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BrandLetter extends StatelessWidget {
  const _BrandLetter();
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 48,
    decoration: BoxDecoration(
      color: AppTokens.primary,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(color: AppTokens.accent, offset: Offset(4, 4)),
      ],
    ),
    alignment: Alignment.center,
    child: const Text(
      'B',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 25,
      ),
    ),
  );
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .72),
        shape: BoxShape.circle,
      ),
    ),
  );
}
