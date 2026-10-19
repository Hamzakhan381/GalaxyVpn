import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Minimalist Pure White & Obsidian Cybersecurity VPN Logo.
/// Features a precision aerodynamic security shield enclosing an iconic stealth dorsal fin.
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
          CustomPaint(
            size: Size(size, size),
            painter: _MinimalistShieldPainter(),
          ),
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

/// Shared vector geometry of the Shark VPN mark, so animated renderings
/// (e.g. the splash draw-in) stay pixel-identical to the static logo.
class SharkLogoGeometry {
  SharkLogoGeometry._();

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

  static Path fin(Size size) {
    final w = size.width;
    final h = size.height;
    final finBaseLeft = Offset(w * 0.32, h * 0.67);
    final finApex = Offset(w * 0.62, h * 0.28);
    final finNotchUpper = Offset(w * 0.55, h * 0.48);
    final finNotchInner = Offset(w * 0.52, h * 0.50);
    final finTrailingEnd = Offset(w * 0.70, h * 0.65);

    return Path()
      ..moveTo(finBaseLeft.dx, finBaseLeft.dy)
      // Sweeping cutting curve to fin tip
      ..cubicTo(w * 0.36, h * 0.52, w * 0.46, h * 0.34, finApex.dx, finApex.dy)
      // Notch descending
      ..quadraticBezierTo(
        w * 0.58,
        h * 0.39,
        finNotchUpper.dx,
        finNotchUpper.dy,
      )
      ..lineTo(finNotchInner.dx, finNotchInner.dy)
      ..quadraticBezierTo(
        w * 0.61,
        h * 0.57,
        finTrailingEnd.dx,
        finTrailingEnd.dy,
      )
      ..quadraticBezierTo(w * 0.50, h * 0.61, finBaseLeft.dx, finBaseLeft.dy)
      ..close();
  }

  /// Charcoal inset line cut into the fin.
  static (Offset, Offset) slit(Size size) => (
    Offset(size.width * 0.46, size.height * 0.53),
    Offset(size.width * 0.50, size.height * 0.60),
  );
}

class _MinimalistShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, size.height / 2);

    // 1. Subtle Outer Charcoal Glow Ring
    final ringPaint = Paint()
      ..color = AppColors.borderDivider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, w * 0.48, ringPaint);

    // 2. Shield Path
    final shieldPath = SharkLogoGeometry.shield(size);

    // Shield Surface Fill (Charcoal #1A1A1A)
    final shieldFill = Paint()
      ..color = AppColors.cardBackground
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldFill);

    // Shield Pure White Border
    final shieldBorder = Paint()
      ..color = AppColors.primaryText.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(shieldPath, shieldBorder);

    // 3. Iconic Minimalist Dorsal Fin (Pure White)
    final finFill = Paint()
      ..color = AppColors.primaryText
      ..style = PaintingStyle.fill;
    canvas.drawPath(SharkLogoGeometry.fin(size), finFill);

    // Subtle Internal Inset Line (Charcoal negative space)
    final slitPaint = Paint()
      ..color = AppColors.cardBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    final (slitStart, slitEnd) = SharkLogoGeometry.slit(size);
    canvas.drawLine(slitStart, slitEnd, slitPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
