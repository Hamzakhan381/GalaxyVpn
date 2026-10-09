import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../services/vpn_service.dart';

/// Central 112dp Connection Trigger conforming to Stitch specification
class ConnectionOrb extends StatefulWidget {
  final VpnConnectionState state;
  final VoidCallback onTap;

  const ConnectionOrb({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  State<ConnectionOrb> createState() => _ConnectionOrbState();
}

class _ConnectionOrbState extends State<ConnectionOrb>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _glowController;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.state == VpnConnectionState.connecting ||
        widget.state == VpnConnectionState.checking) {
      _animController.repeat();
    }
    if (widget.state == VpnConnectionState.connected) {
      _glowController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ConnectionOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == VpnConnectionState.connecting ||
        widget.state == VpnConnectionState.checking) {
      if (!_animController.isAnimating) {
        _animController.repeat();
      }
    } else {
      if (_animController.isAnimating) {
        _animController.stop();
        _animController.reset();
      }
    }

    if (widget.state == VpnConnectionState.connected) {
      if (!_glowController.isAnimating) {
        _glowController.repeat();
      }
    } else {
      if (_glowController.isAnimating) {
        _glowController.stop();
        _glowController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double orbSize = 112.0;
    const double outerCushion = 136.0;

    final isConnected = widget.state == VpnConnectionState.connected;
    final isConnecting = widget.state == VpnConnectionState.connecting ||
        widget.state == VpnConnectionState.checking;
    final isDisconnecting = widget.state == VpnConnectionState.disconnecting;

    return Semantics(
      button: true,
      label: isConnected
          ? 'Connected and Protected. Tap to disconnect.'
          : isConnecting
              ? 'Connecting to VPN. Tap to cancel.'
              : 'Disconnected. Tap to connect to VPN.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTapped = true),
        onTapUp: (_) => setState(() => _isTapped = false),
        onTapCancel: () => setState(() => _isTapped = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isTapped ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final pulse = isConnected
                  ? 1.0 + 0.015 * math.sin(_glowController.value * 2 * math.pi)
                  : 1.0;
              return Transform.scale(
                scale: pulse,
                child: child,
              );
            },
            child: SizedBox(
              width: outerCushion,
              height: outerCushion,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 12dp Outer cushion ring in Navy 6%
                  Container(
                    width: outerCushion,
                    height: outerCushion,
                    decoration: const BoxDecoration(
                      color: AppColors.navy06,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Connecting 360-degree sweep spinner
                  if (isConnecting || isDisconnecting)
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _animController.value * 2 * math.pi,
                          child: CustomPaint(
                            size: const Size(124, 124),
                            painter: _SweepBorderPainter(),
                          ),
                        );
                      },
                    ),

                  // Core 112dp Orb
                  Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: BoxDecoration(
                      gradient: isConnected
                          ? const RadialGradient(
                              colors: [Color(0xFF1E3A1E), AppColors.inkNavy],
                              radius: 1.2,
                            )
                          : null,
                      color: isConnected ? null : AppColors.inkNavy,
                      shape: BoxShape.circle,
                      boxShadow: [
                        const BoxShadow(
                          color: AppColors.navy06,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                        if (isConnected)
                          BoxShadow(
                            color: AppColors.signalLime.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isConnected
                              ? Icons.shield
                              : isConnecting
                                  ? Icons.sync
                                  : Icons.power_settings_new,
                          color: isConnected
                              ? AppColors.signalLime
                              : AppColors.pureWhite,
                          size: 38,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isConnected
                              ? 'DISCONNECT'
                              : isConnecting
                                  ? 'CANCEL'
                                  : 'CONNECT',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.pureWhite,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 10dp Signal Lime status pip on Connected state
                  if (isConnected)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.signalLime,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.pureWhite, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SweepBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.signalLime.withValues(alpha: 0.0),
          AppColors.signalLime,
        ],
        stops: const [0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: (size.width - 4) / 2,
      ),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
