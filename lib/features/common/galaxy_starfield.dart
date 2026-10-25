import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'motion.dart';

/// Tilted spiral galaxy of round, twinkling stars orbiting the connect orb.
///
/// When [active] turns on (the tunnel is up) a burst of green shooting stars
/// flies out of the orb and fades away, while the galaxy stars arrive tinted
/// green and cool to white. The galaxy then slowly rotates while active and
/// fades back out when [active] turns off. Everything is painted outside this
/// widget's bounds, so size it to the orb.
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

  /// Entrance / exit of the galaxy, including its green-to-white cool down.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
    reverseDuration: const Duration(milliseconds: 450),
    value: widget.active ? 1.0 : 0.0,
  );

  /// One-shot green shooting-star burst played on connect.
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  static final List<_Star> _stars = _Star.generate();
  static final List<_ShootingStar> _shootingStars = _ShootingStar.generate();

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
        if (!Motion.isReduced(context)) _burst.forward(from: 0);
      }
    } else if (Motion.isTestEnvironment) {
      _reveal.value = 0.0;
    } else {
      _burst.reset();
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
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.isReduced(context);
    if (reduced && _orbit.isAnimating) _orbit.stop();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_orbit, _reveal, _burst]),
        builder: (context, _) => CustomPaint(
          painter: _GalaxyPainter(
            stars: _stars,
            shootingStars: _shootingStars,
            time: reduced ? 0.0 : _orbit.value,
            reveal: _reveal.value,
            burst: _burst.value,
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

    Color pickColor() => rnd.nextDouble() < 0.6
        ? AppColors.primaryText
        : AppColors.galaxyStarGlow;

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

/// A green star launched from the orb's ring during the connect burst.
class _ShootingStar {
  final double angle;

  /// How far past the galaxy's outer edge it travels before vanishing.
  final double reach;
  final double radius;

  /// 0..1 launch delay within the burst.
  final double delay;

  const _ShootingStar({
    required this.angle,
    required this.reach,
    required this.radius,
    required this.delay,
  });

  static const int _count = 28;

  static List<_ShootingStar> generate() {
    final rnd = math.Random(11);
    return List.generate(_count, (i) {
      return _ShootingStar(
        angle: i * 2 * math.pi / _count + (rnd.nextDouble() - 0.5) * 0.3,
        reach: 0.75 + rnd.nextDouble() * 0.5,
        radius: 1.2 + rnd.nextDouble() * 1.4,
        delay: rnd.nextDouble() * 0.3,
      );
    });
  }
}

class _GalaxyPainter extends CustomPainter {
  final List<_Star> stars;
  final List<_ShootingStar> shootingStars;

  /// 0..1 progress through one galaxy revolution.
  final double time;
  final double reveal;
  final double burst;
  final bool twinkle;

  _GalaxyPainter({
    required this.stars,
    required this.shootingStars,
    required this.time,
    required this.reveal,
    required this.burst,
    required this.twinkle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final s = size.shortestSide;

    // The disk is an ellipse (wider than tall, like a tilted galaxy) whose
    // inner edge clears the orb's ring brackets on every side.
    final inner = Offset(s * 0.57, s * 0.55);
    final outer = Offset(s * 0.76, s * 0.63);

    if (reveal > 0) _paintGalaxy(canvas, center, inner, outer);
    if (burst > 0 && burst < 1) _paintBurst(canvas, center, s * 0.44, outer);
  }

  void _paintGalaxy(Canvas canvas, Offset center, Offset inner, Offset outer) {
    final spread = Curves.easeOutCubic.transform(reveal);
    _paintNebula(canvas, center, outer, spread);

    final rotation = time * 2 * math.pi;
    final glow = Paint();
    final core = Paint();
    final sparkle = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8;

    for (final star in stars) {
      // Each star lands during the first half of the reveal...
      final local = ((reveal - star.delay * 0.4) / 0.4).clamp(0.0, 1.0);
      if (local <= 0) continue;
      // ...and its green arrival tint cools to its own color in the second.
      final cool = ((reveal - 0.35 - star.delay * 0.3) / 0.35).clamp(0.0, 1.0);
      final color = Color.lerp(
        AppColors.connectedStatus,
        star.color,
        Curves.easeInOut.transform(cool),
      )!;

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
        ..color = color.withValues(alpha: 0.45 * brightness)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.radius * 1.6);
      canvas.drawCircle(pos, star.radius * 1.8, glow);

      core.color = color.withValues(alpha: brightness.clamp(0.0, 1.0));
      canvas.drawCircle(pos, star.radius * (0.85 + 0.25 * blink), core);

      // The brightest stars flash a four-point sparkle at the peak of a blink.
      if (star.radius >= 2.0 && blink > 0.8) {
        final flash = ((blink - 0.8) / 0.2) * brightness;
        final arm = star.radius * 2.6 * flash + star.radius;
        sparkle.color = color.withValues(alpha: 0.7 * flash);
        canvas.drawLine(pos - Offset(arm, 0), pos + Offset(arm, 0), sparkle);
        canvas.drawLine(pos - Offset(0, arm), pos + Offset(0, arm), sparkle);
      }
    }
  }

  /// Green stars shoot out of the orb with short comet tails, curling with
  /// the galaxy's spin, then fade out past its outer edge.
  void _paintBurst(Canvas canvas, Offset center, double start, Offset outer) {
    final glow = Paint();
    final core = Paint();
    final tail = Paint()..strokeCap = StrokeCap.round;
    final coreColor = Color.lerp(
      AppColors.connectedStatus,
      AppColors.primaryText,
      0.45,
    )!;

    Offset at(_ShootingStar star, double t) {
      final travel = Curves.easeOutCubic.transform(t);
      final a = star.angle + 0.45 * travel;
      final r = Offset(
        start + (outer.dx * star.reach - start) * travel,
        start + (outer.dy * star.reach - start) * travel,
      );
      return center + Offset(math.cos(a) * r.dx, math.sin(a) * r.dy);
    }

    for (final star in shootingStars) {
      final t = ((burst - star.delay) / (1 - star.delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;

      // Quick flare in, then a long fade so they gently disappear.
      final alpha = t < 0.12 ? t / 0.12 : 1 - ((t - 0.12) / 0.88);
      final eased = Curves.easeIn.transform(alpha.clamp(0.0, 1.0));
      final pos = at(star, t);
      final from = at(star, (t - 0.12).clamp(0.0, 1.0));

      tail
        ..strokeWidth = star.radius * 1.1
        ..shader = LinearGradient(
          colors: [
            AppColors.connectedStatus.withValues(alpha: 0.0),
            AppColors.connectedStatus.withValues(alpha: 0.55 * eased),
          ],
        ).createShader(Rect.fromPoints(from, pos));
      canvas.drawLine(from, pos, tail);

      final size = star.radius * (1.0 - 0.35 * t);
      glow
        ..color = AppColors.connectedStatus.withValues(alpha: 0.6 * eased)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 2.2);
      canvas.drawCircle(pos, size * 2.0, glow);

      core.color = coreColor.withValues(alpha: eased);
      canvas.drawCircle(pos, size, core);
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
      old.time != time ||
      old.reveal != reveal ||
      old.burst != burst ||
      old.twinkle != twinkle;
}
