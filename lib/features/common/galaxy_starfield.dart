import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'motion.dart';

/// Tilted spiral galaxy of round, twinkling stars orbiting the connect orb.
///
/// Fades in and spreads outward when [active] turns on (the tunnel is up),
/// slowly rotates while active, and fades back out when it turns off. The
/// star field is painted outside this widget's bounds, so size it to the orb.
class GalaxyStarfield extends StatefulWidget {
  final bool active;

  const GalaxyStarfield({super.key, required this.active});

  @override
  State<GalaxyStarfield> createState() => _GalaxyStarfieldState();
}

class _GalaxyStarfieldState extends State<GalaxyStarfield>
    with TickerProviderStateMixin {
  /// One full galaxy revolution; twinkle frequencies are whole cycles of it
  /// so the loop is seamless.
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  /// Entrance / exit of the whole star field.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    reverseDuration: const Duration(milliseconds: 450),
    value: widget.active ? 1.0 : 0.0,
  );

  static final List<_Star> _stars = _Star.generate();

  @override
  void initState() {
    super.initState();
    _reveal.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _orbit.stop();
    });
    if (widget.active) _startOrbit();
  }

  @override
  void didUpdateWidget(covariant GalaxyStarfield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    if (widget.active) {
      _startOrbit();
      if (Motion.isTestEnvironment) {
        _reveal.value = 1.0;
      } else {
        _reveal.forward();
      }
    } else if (Motion.isTestEnvironment) {
      _reveal.value = 0.0;
    } else {
      _reveal.reverse();
    }
  }

  void _startOrbit() {
    // Never loop forever under test: pumpAndSettle would never return.
    if (Motion.isTestEnvironment || _orbit.isAnimating) return;
    _orbit.repeat();
  }

  @override
  void dispose() {
    _orbit.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.isReduced(context);
    if (reduced && _orbit.isAnimating) _orbit.stop();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_orbit, _reveal]),
        builder: (context, _) => CustomPaint(
          painter: _GalaxyPainter(
            stars: _stars,
            time: reduced ? 0.0 : _orbit.value,
            reveal: _reveal.value,
            twinkle: !reduced,
          ),
        ),
      ),
    );
  }
}

class _Star {
  /// Angle within the galaxy disk, before rotation.
  final double angle;

  /// Distance from the orb center as a fraction of the disk radius (0..1).
  final double distance;
  final double radius;
  final Color color;

  /// Whole twinkle cycles per galaxy revolution, and their phase offset.
  final int twinkleCycles;
  final double phase;

  /// 0..1 delay of this star's entrance within the reveal.
  final double delay;

  const _Star({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.color,
    required this.twinkleCycles,
    required this.phase,
    required this.delay,
  });

  static const int _armStars = 46;
  static const int _scatterStars = 26;

  /// Fixed seed so the galaxy keeps the same shape every time it appears.
  static List<_Star> generate() {
    final rnd = math.Random(7);
    final stars = <_Star>[];

    Color pickColor() {
      final roll = rnd.nextDouble();
      if (roll < 0.50) return AppColors.primaryText;
      if (roll < 0.85) return AppColors.galaxyStarGlow;
      return AppColors.connectedStatus;
    }

    double pickRadius() {
      final roll = rnd.nextDouble();
      if (roll < 0.12) return 2.0 + rnd.nextDouble() * 0.6; // bright stars
      return 0.7 + rnd.nextDouble() * 1.0;
    }

    // Two spiral arms winding outward from the orb.
    for (int i = 0; i < _armStars; i++) {
      final arm = i % 2;
      final u = rnd.nextDouble();
      final jitter = (rnd.nextDouble() - 0.5) * 0.55;
      stars.add(
        _Star(
          angle: arm * math.pi + u * 2.4 + jitter,
          distance: u,
          radius: pickRadius(),
          color: pickColor(),
          twinkleCycles: 12 + rnd.nextInt(26),
          phase: rnd.nextDouble() * 2 * math.pi,
          delay: u * 0.6 + rnd.nextDouble() * 0.2,
        ),
      );
    }

    // Loose stars scattered through the disk between the arms.
    for (int i = 0; i < _scatterStars; i++) {
      final u = rnd.nextDouble();
      stars.add(
        _Star(
          angle: rnd.nextDouble() * 2 * math.pi,
          distance: u,
          radius: 0.6 + rnd.nextDouble() * 0.8,
          color: pickColor(),
          twinkleCycles: 12 + rnd.nextInt(26),
          phase: rnd.nextDouble() * 2 * math.pi,
          delay: rnd.nextDouble() * 0.8,
        ),
      );
    }
    return stars;
  }
}

class _GalaxyPainter extends CustomPainter {
  final List<_Star> stars;

  /// 0..1 progress through one galaxy revolution.
  final double time;
  final double reveal;
  final bool twinkle;

  _GalaxyPainter({
    required this.stars,
    required this.time,
    required this.reveal,
    required this.twinkle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (reveal <= 0) return;
    final center = size.center(Offset.zero);
    final s = size.shortestSide;

    // The disk is an ellipse (wider than tall, like a tilted galaxy) whose
    // inner edge clears the orb's ring brackets on every side.
    final inner = Offset(s * 0.57, s * 0.55);
    final outer = Offset(s * 0.76, s * 0.63);
    final spread = Curves.easeOutCubic.transform(reveal);

    _paintNebula(canvas, center, outer, spread);

    final rotation = time * 2 * math.pi;
    final glow = Paint();
    final core = Paint();
    final sparkle = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8;

    for (final star in stars) {
      final local = ((reveal - star.delay * 0.5) / 0.5).clamp(0.0, 1.0);
      if (local <= 0) continue;

      // Stars emerge from the orb and drift out to their orbit.
      final r =
          (inner + (outer - inner) * star.distance) *
          (0.78 + 0.22 * Curves.easeOutCubic.transform(local));
      final a = star.angle + rotation;
      final pos = center + Offset(math.cos(a) * r.dx, math.sin(a) * r.dy);

      // Stars on the far side of the tilted disk sit slightly dimmer.
      final depth = 0.75 + 0.25 * math.sin(a);
      final blink = twinkle
          ? 0.5 +
                0.5 *
                    math.sin(
                      time * 2 * math.pi * star.twinkleCycles + star.phase,
                    )
          : 0.75;
      final brightness = (0.25 + 0.75 * blink) * depth * local * spread;

      glow
        ..color = star.color.withValues(alpha: 0.45 * brightness)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.radius * 1.6);
      canvas.drawCircle(pos, star.radius * 1.8, glow);

      core.color = star.color.withValues(alpha: brightness.clamp(0.0, 1.0));
      canvas.drawCircle(pos, star.radius * (0.85 + 0.25 * blink), core);

      // The brightest stars flash a four-point sparkle at the peak of a blink.
      if (star.radius >= 2.0 && blink > 0.8) {
        final flash = ((blink - 0.8) / 0.2) * brightness;
        final arm = star.radius * 2.6 * flash + star.radius;
        sparkle.color = star.color.withValues(alpha: 0.7 * flash);
        canvas.drawLine(pos - Offset(arm, 0), pos + Offset(arm, 0), sparkle);
        canvas.drawLine(pos - Offset(0, arm), pos + Offset(0, arm), sparkle);
      }
    }
  }

  void _paintNebula(Canvas canvas, Offset center, Offset outer, double spread) {
    final radius = outer.dx * 1.12;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, outer.dy / outer.dx);
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.galaxyNebula.withValues(alpha: 0.0),
            AppColors.galaxyNebula.withValues(alpha: 0.16 * spread),
            AppColors.galaxyNebulaDeep.withValues(alpha: 0.10 * spread),
            AppColors.galaxyNebulaDeep.withValues(alpha: 0.0),
          ],
          stops: const [0.42, 0.62, 0.82, 1.0],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GalaxyPainter old) =>
      old.time != time || old.reveal != reveal || old.twinkle != twinkle;
}
