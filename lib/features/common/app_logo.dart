import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Galaxy VPN brand mark: a security shield holding a deep-space nebula,
/// a ringed planet and sparkling stars.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBadge;
  final bool useImage;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showBadge = false,
    this.useImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _GalaxyShieldPainter()),
          if (showBadge)
            Positioned(
              right: size * 0.04,
              bottom: size * 0.04,
              child: Container(
                width: size * 0.22,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: AppColors.connectedStatus,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBackground,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: size * 0.08,
                    height: size * 0.08,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryText,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared vector geometry and paint routines of the Galaxy VPN mark, so
/// animated renderings (e.g. the splash draw-in) stay identical to the
/// static logo.
class GalaxyLogoGeometry {
  GalaxyLogoGeometry._();

  /// Tilt of the planet's ring, in radians.
  static const double ringTilt = -0.36;

  static Path shield(Size size) {
    final w = size.width;
    final h = size.height;
    final left = w * 0.20;
    final right = w * 0.80;
    final top = h * 0.16;
    final shoulderY = h * 0.25;
    final midY = h * 0.58;
    final bottomY = h * 0.86;
    final centerX = w * 0.50;

    return Path()
      ..moveTo(centerX, top)
      ..lineTo(right, shoulderY)
      ..lineTo(right, midY)
      ..quadraticBezierTo(right, bottomY * 0.96, centerX, bottomY)
      ..quadraticBezierTo(left, bottomY * 0.96, left, midY)
      ..lineTo(left, shoulderY)
      ..close();
  }

  static Offset planetCenter(Size size) =>
      Offset(size.width * 0.5, size.height * 0.53);

  static double planetRadius(Size size) => size.width * 0.115;

  /// (center, radius) of each sparkle star, tucked into the shield's corners.
  static List<(Offset, double)> stars(Size size) {
    final w = size.width;
    final h = size.height;
    return [
      (Offset(w * 0.33, h * 0.34), w * 0.045),
      (Offset(w * 0.67, h * 0.33), w * 0.030),
      (Offset(w * 0.36, h * 0.71), w * 0.025),
      (Offset(w * 0.64, h * 0.72), w * 0.035),
    ];
  }

  /// Four-pointed sparkle.
  static Path sparkle(Offset c, double r) {
    final i = r * 0.22;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + i, c.dy - i, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + i, c.dy + i, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - i, c.dy + i, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - i, c.dy - i, c.dx, c.dy - r)
      ..close();
  }

  /// Charcoal body with a violet nebula glow and faint star dust.
  static void paintNebula(Canvas canvas, Size size, {double opacity = 1}) {
    if (opacity <= 0) return;
    final shieldPath = shield(size);
    final w = size.width;

    canvas.drawPath(
      shieldPath,
      Paint()..color = AppColors.cardBackground.withValues(alpha: opacity),
    );
    canvas.drawPath(
      shieldPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.15, -0.05),
          radius: 0.62,
          colors: [
            AppColors.galaxyNebula.withValues(alpha: 0.6 * opacity),
            AppColors.galaxyNebulaDeep.withValues(alpha: 0.7 * opacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Deterministic star dust (golden-ratio scatter).
    canvas.save();
    canvas.clipPath(shieldPath);
    final dust = Paint()
      ..color = AppColors.primaryText.withValues(alpha: 0.35 * opacity);
    for (int i = 0; i < 14; i++) {
      final x = 0.30 + ((i * 0.618034) % 1.0) * 0.40;
      final y = 0.28 + ((i * 0.381966 + 0.13) % 1.0) * 0.48;
      canvas.drawCircle(
        Offset(w * x, size.height * y),
        w * (0.003 + 0.002 * (i % 3)),
        dust,
      );
    }
    canvas.restore();
  }

  /// Ringed planet and sparkle stars.
  ///
  /// [scale] grows the planet around its centre, [stars] fades the
  /// sparkles in, and a non-zero [twinkle] (0..1, looping) makes them shimmer.
  static void paintCore(
    Canvas canvas,
    Size size, {
    double scale = 1,
    double stars = 1,
    double twinkle = 0,
  }) {
    final w = size.width;
    final c = planetCenter(size);
    final r = planetRadius(size);

    if (scale > 0) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(scale);
      canvas.translate(-c.dx, -c.dy);

      _paintRing(canvas, size, front: false);

      // Planet glow, body and terminator shadow.
      canvas.drawCircle(
        c,
        r * 1.5,
        Paint()
          ..color = AppColors.galaxyStarGlow.withValues(alpha: 0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
      final planetRect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.35, -0.35),
            colors: [AppColors.primaryText, AppColors.galaxyStarGlow],
          ).createShader(planetRect),
      );
      canvas.save();
      canvas.clipPath(Path()..addOval(planetRect));
      canvas.drawCircle(
        c + Offset(r * 0.55, r * 0.45),
        r * 1.05,
        Paint()
          ..color = AppColors.galaxyNebulaDeep.withValues(alpha: 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
      );
      canvas.restore();

      _paintRing(canvas, size, front: true);
      canvas.restore();
    }

    if (stars > 0) {
      final list = GalaxyLogoGeometry.stars(size);
      for (int i = 0; i < list.length; i++) {
        final (p, radius) = list[i];
        final shimmer = twinkle == 0
            ? 1.0
            : 0.65 + 0.35 * math.sin(twinkle * 2 * math.pi + i * 1.7);
        final starR = radius * stars * shimmer;
        if (starR <= 0) continue;
        canvas.drawCircle(
          p,
          starR * 0.9,
          Paint()
            ..color = AppColors.galaxyStarGlow.withValues(alpha: 0.35 * stars)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02),
        );
        canvas.drawPath(
          sparkle(p, starR),
          Paint()
            ..color = AppColors.primaryText.withValues(
              alpha: stars.clamp(0.0, 1.0),
            ),
        );
      }
    }
  }

  /// The far half of the ring is drawn before the planet and dimmed; the near
  /// half is drawn after it, with a dark gap so it reads as passing in front.
  static void _paintRing(Canvas canvas, Size size, {required bool front}) {
    final w = size.width;
    final c = planetCenter(size);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.50,
      height: w * 0.15,
    );
    final start = front ? 0.0 : math.pi;

    if (front) {
      // Carve a thin shadow into the planet where the ring crosses it.
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: c, radius: planetRadius(size))),
      );
      canvas.translate(c.dx, c.dy);
      canvas.rotate(ringTilt);
      canvas.drawArc(
        rect,
        start,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.05
          ..color = AppColors.galaxyNebulaDeep,
      );
      canvas.restore();
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(ringTilt);
    canvas.drawArc(
      rect,
      start,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.028
        ..color = AppColors.primaryText.withValues(alpha: front ? 1.0 : 0.55),
    );
    canvas.restore();
  }
}

class _GalaxyShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, size.height / 2);

    // 1. Subtle outer orbit ring
    canvas.drawCircle(
      center,
      w * 0.48,
      Paint()
        ..color = AppColors.borderDivider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2. Nebula-filled shield with a pure white border
    GalaxyLogoGeometry.paintNebula(canvas, size);
    canvas.drawPath(
      GalaxyLogoGeometry.shield(size),
      Paint()
        ..color = AppColors.primaryText.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeJoin = StrokeJoin.round,
    );

    // 3. Ringed planet and stars
    GalaxyLogoGeometry.paintCore(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
