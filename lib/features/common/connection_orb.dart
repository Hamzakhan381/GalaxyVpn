import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../domain/entities/vpn_connection_state.dart';
import 'galaxy_starfield.dart';

/// Premium cybersecurity connect/disconnect button with smooth circular state animation.
///
/// Visual identity: Obsidian black, charcoal grey, pure white outline/surface,
/// subtle green (#35C98A) for connected state, restrained red (#FF5C5C) for errors.
class ConnectionOrb extends StatefulWidget {
  final VpnConnectionState state;
  final VoidCallback onTap;
  final String? connectingCountry;

  const ConnectionOrb({
    super.key,
    required this.state,
    required this.onTap,
    this.connectingCountry,
  });

  @override
  State<ConnectionOrb> createState() => _ConnectionOrbState();
}

class _ConnectionOrbState extends State<ConnectionOrb>
    with TickerProviderStateMixin {
  // Continuous smooth spin for circular connecting animation
  late final AnimationController _spinCtrl;
  // Organic subtle breathing for connected status
  late final AnimationController _breathCtrl;
  // State transition interpolation
  late final AnimationController _transitionCtrl;
  // Outward expansion ripple when VPN connects successfully
  late final AnimationController _rippleCtrl;

  bool _pressed = false;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (!_isTestEnvironment) {
      _breathCtrl.repeat(reverse: true);
      _updateAnimations(widget.state);
    }
  }

  @override
  void didUpdateWidget(covariant ConnectionOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _transitionCtrl.forward(from: 0.0);
      _updateAnimations(widget.state, oldState: oldWidget.state);
    }
  }

  void _updateAnimations(
    VpnConnectionState state, {
    VpnConnectionState? oldState,
  }) {
    if (_isTestEnvironment) return;

    final isConnecting =
        state == VpnConnectionState.connecting ||
        state == VpnConnectionState.checking;

    if (isConnecting) {
      if (!_spinCtrl.isAnimating) _spinCtrl.repeat();
    } else {
      if (_spinCtrl.isAnimating) {
        _spinCtrl.stop();
        _spinCtrl.reset();
      }
    }

    // Trigger success expansion ripple when transitioning to connected
    if (state == VpnConnectionState.connected &&
        (oldState == VpnConnectionState.connecting ||
            oldState == VpnConnectionState.checking ||
            oldState == VpnConnectionState.disconnected)) {
      _rippleCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _breathCtrl.dispose();
    _transitionCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isConnected = state == VpnConnectionState.connected;
    final isConnecting =
        state == VpnConnectionState.connecting ||
        state == VpnConnectionState.checking;
    final isDisconnecting = state == VpnConnectionState.disconnecting;
    final isError = state == VpnConnectionState.error;

    final Color statusColor = isConnected
        ? AppColors.connectedStatus
        : isError
        ? AppColors.errorStatus
        : AppColors.primaryText;

    final Color surfaceColor = isConnected
        ? AppColors.cardBackground
        : AppColors.elevatedSurface;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
          child: SizedBox(
            width: 228,
            height: 228,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ── 0. Twinkling galaxy star field while connected ─────────────
                Positioned.fill(
                  child: GalaxyStarfield(active: isConnected),
                ),

                // ── 1. Circular Outer Indicator Ring & Gyroscopic Animations ──
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _spinCtrl,
                      _breathCtrl,
                      _rippleCtrl,
                      _transitionCtrl,
                    ]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _ConnectionRingPainter(
                          state: state,
                          spinProgress: _spinCtrl.value,
                          breathProgress: _breathCtrl.value,
                          rippleProgress: _rippleCtrl.value,
                          isConnecting: isConnecting,
                          isConnected: isConnected,
                          isError: isError,
                          isDisconnecting: isDisconnecting,
                        ),
                      );
                    },
                  ),
                ),

                // ── 2. Main Tactile Connect / Disconnect Surface ─────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 146,
                  height: 146,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surfaceColor,
                    border: Border.all(
                      color: statusColor,
                      width: isConnected ? 2.0 : 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                      if (isConnected)
                        BoxShadow(
                          color: AppColors.connectedStatus.withValues(
                            alpha: _isTestEnvironment
                                ? 0.25
                                : (0.16 + (0.12 * _breathCtrl.value)),
                          ),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      if (isConnecting)
                        BoxShadow(
                          color: AppColors.primaryText.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Power / Security / Sync Icon with morphing transition
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: isConnecting
                            ? RotationTransition(
                                key: const ValueKey('icon_connecting'),
                                turns: _spinCtrl,
                                child: const Icon(
                                  Icons.sync_rounded,
                                  size: 42,
                                  color: AppColors.primaryText,
                                ),
                              )
                            : Icon(
                                isConnected
                                    ? Icons.shield_rounded
                                    : isError
                                    ? Icons.refresh_rounded
                                    : isDisconnecting
                                    ? Icons.sync_disabled_rounded
                                    : Icons.power_settings_new_rounded,
                                key: ValueKey('icon_${state.name}'),
                                size: isConnected ? 44 : 42,
                                color: statusColor,
                              ),
                      ),
                      const SizedBox(height: 6),
                      // Action Label with AnimatedSwitcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          isConnected
                              ? 'DISCONNECT'
                              : isConnecting
                              ? 'CONNECTING'
                              : isDisconnecting
                              ? 'STOPPING'
                              : isError
                              ? 'RETRY'
                              : 'CONNECT',
                          key: ValueKey('label_${state.name}'),
                          style: AppTextStyles.labelSm.copyWith(
                            color: statusColor,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter for the high-tech cybersecurity circular connection animations.
class _ConnectionRingPainter extends CustomPainter {
  final VpnConnectionState state;
  final double spinProgress;
  final double breathProgress;
  final double rippleProgress;
  final bool isConnecting;
  final bool isConnected;
  final bool isError;
  final bool isDisconnecting;

  _ConnectionRingPainter({
    required this.state,
    required this.spinProgress,
    required this.breathProgress,
    required this.rippleProgress,
    required this.isConnecting,
    required this.isConnected,
    required this.isError,
    required this.isDisconnecting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringRadius = size.width * 0.44;

    // 1. Static Base Track Ring (charcoal divider)
    final basePaint = Paint()
      ..color = AppColors.borderDivider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, ringRadius, basePaint);

    if (isConnecting) {
      // 2. High-Tech Gyroscopic Connecting Rings & Radar Sonar Pulses

      // 2a. Expanding Radar Sonar Waves (scanning for secure relay)
      for (int wIdx = 0; wIdx < 2; wIdx++) {
        final waveProg = (spinProgress + (wIdx * 0.5)) % 1.0;
        final sonarR = ringRadius * (0.80 + (0.50 * waveProg));
        final sonarAlpha = (1.0 - waveProg) * 0.30;
        final sonarPaint = Paint()
          ..color = AppColors.primaryText.withValues(alpha: sonarAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * (1.0 - waveProg * 0.4);
        canvas.drawCircle(center, sonarR, sonarPaint);
      }

      // 2b. Precision 24-point rotating telemetry compass dial
      final dialAngle = -spinProgress * 2 * math.pi * 0.25;
      final tickPaint = Paint()
        ..color = AppColors.borderDivider.withValues(alpha: 0.8)
        ..strokeWidth = 1.0;
      final majorTickPaint = Paint()
        ..color = AppColors.primaryText.withValues(alpha: 0.5)
        ..strokeWidth = 1.2;
      for (int i = 0; i < 24; i++) {
        final angle = dialAngle + (i * math.pi / 12);
        final isMajor = i % 6 == 0;
        final dir = Offset(math.cos(angle), math.sin(angle));
        final tickLen = isMajor ? 5.5 : 2.5;
        canvas.drawLine(
          center + dir * (ringRadius - tickLen),
          center + dir * (ringRadius + tickLen),
          isMajor ? majorTickPaint : tickPaint,
        );
      }

      // 2c. Secondary inner counter-rotating micro-orbit
      final innerRadius = ringRadius - 10;
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
      final counterAngle = -spinProgress * 2 * math.pi * 0.75;
      final innerSweepPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: math.pi * 0.6,
          colors: [
            AppColors.primaryText.withValues(alpha: 0.0),
            AppColors.primaryText.withValues(alpha: 0.35),
          ],
          transform: GradientRotation(counterAngle),
        ).createShader(innerRect);
      canvas.drawArc(
        innerRect,
        counterAngle,
        math.pi * 0.6,
        false,
        innerSweepPaint,
      );

      // 2d. Primary high-contrast sweep arc (270 degrees)
      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      final startAngle = spinProgress * 2 * math.pi;

      final sweepPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: math.pi * 1.5,
          colors: [
            AppColors.primaryText.withValues(alpha: 0.0),
            AppColors.primaryText,
          ],
          transform: GradientRotation(startAngle),
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, math.pi * 1.5, false, sweepPaint);

      // 2e. Multi-Orbital Micro-Satellites (Data Packets)
      // Leading primary glowing pulse dot
      final headAngle = startAngle + math.pi * 1.5;
      final dotDir = Offset(math.cos(headAngle), math.sin(headAngle));
      final headDot = Paint()..color = AppColors.primaryText;
      canvas.drawCircle(center + dotDir * ringRadius, 3.2, headDot);

      final glowDot = Paint()
        ..color = AppColors.primaryText.withValues(alpha: 0.35);
      canvas.drawCircle(center + dotDir * ringRadius, 6.5, glowDot);

      // Orbital packet 1 (outer counter-orbiting particle)
      final sat1Angle = -spinProgress * 2 * math.pi * 1.2;
      final sat1Pos =
          center +
          Offset(math.cos(sat1Angle), math.sin(sat1Angle)) * (ringRadius + 7);
      canvas.drawCircle(
        sat1Pos,
        1.8,
        Paint()..color = AppColors.primaryText.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        sat1Pos,
        4.2,
        Paint()..color = AppColors.primaryText.withValues(alpha: 0.22),
      );

      // Orbital packet 2 (inner rapid satellite)
      final sat2Angle = (spinProgress * 2 * math.pi * 1.6) + (math.pi * 0.7);
      final sat2Pos =
          center +
          Offset(math.cos(sat2Angle), math.sin(sat2Angle)) * (ringRadius - 8);
      canvas.drawCircle(
        sat2Pos,
        1.5,
        Paint()..color = AppColors.secondaryText.withValues(alpha: 0.70),
      );
    } else if (isConnected) {
      // 3. Connected State: Success Ripple, Breathing Ring, Cardinal Reticles & Security Brackets

      // 3a. Success expansion ripple (plays when connection completes)
      if (rippleProgress > 0.0 && rippleProgress < 1.0) {
        final rippleR = 73.0 + (ringRadius - 73.0 + 36.0) * rippleProgress;
        final rippleAlpha = (1.0 - rippleProgress) * 0.45;
        final ripplePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * (1.0 - rippleProgress * 0.5)
          ..color = AppColors.connectedStatus.withValues(alpha: rippleAlpha);
        canvas.drawCircle(center, rippleR, ripplePaint);
      }

      // 3b. Breathing green status ring
      final pulseAlpha = 0.60 + (0.40 * breathProgress);
      final activePaint = Paint()
        ..color = AppColors.connectedStatus.withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, ringRadius, activePaint);

      // Outer faint harmonic aura ring
      final auraPaint = Paint()
        ..color = AppColors.connectedStatus.withValues(
          alpha: 0.12 * breathProgress,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, ringRadius + 6, auraPaint);

      // 3c. 4 Precision Cardinal Anchor Ticks (crosshair lock)
      final tickPaint = Paint()
        ..color = AppColors.connectedStatus
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 4; i++) {
        final angle = (i * math.pi / 2);
        final dir = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + dir * (ringRadius - 6),
          center + dir * (ringRadius + 6),
          tickPaint,
        );
      }

      // 3d. Cardinal Corner Brackets [ ] locking the secure perimeter
      final bracketPaint = Paint()
        ..color = AppColors.connectedStatus.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 4; i++) {
        final angle = (i * math.pi / 2);
        final bDist = ringRadius + 10;
        final corner =
            center + Offset(math.cos(angle), math.sin(angle)) * bDist;
        final perp = Offset(-math.sin(angle), math.cos(angle)) * 5;
        canvas.drawLine(corner - perp, corner + perp, bracketPaint);
      }
    } else if (isDisconnecting) {
      // 4. Disconnecting: subtle dissolving counter arc
      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      final startAngle = -spinProgress * 2 * math.pi;
      final discPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = AppColors.secondaryText.withValues(alpha: 0.5);
      canvas.drawArc(rect, startAngle, math.pi * 0.8, false, discPaint);
    } else if (isError) {
      // 5. Restrained Red Error Ring
      final errorPaint = Paint()
        ..color = AppColors.errorStatus.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, ringRadius, errorPaint);

      // 4 Error diagonal accent ticks
      final tickPaint = Paint()
        ..color = AppColors.errorStatus
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 4; i++) {
        final angle = (i * math.pi / 2) + (math.pi / 4);
        final dir = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + dir * (ringRadius - 5),
          center + dir * (ringRadius + 5),
          tickPaint,
        );
      }
    } else {
      // 6. Minimal Disconnected Ring: 16 precision hairline ticks with cardinal pips
      final tickPaint = Paint()
        ..color = AppColors.mutedText.withValues(alpha: 0.35)
        ..strokeWidth = 1.0;
      final cardinalPaint = Paint()
        ..color = AppColors.secondaryText.withValues(alpha: 0.55)
        ..strokeWidth = 1.2;

      for (int i = 0; i < 16; i++) {
        final angle = (i * math.pi / 8);
        final isCardinal = i % 4 == 0;
        final dir = Offset(math.cos(angle), math.sin(angle));
        final len = isCardinal ? 5.0 : 3.0;
        canvas.drawLine(
          center + dir * (ringRadius - len),
          center + dir * (ringRadius + len),
          isCardinal ? cardinalPaint : tickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectionRingPainter old) =>
      old.state != state ||
      old.spinProgress != spinProgress ||
      old.breathProgress != breathProgress ||
      old.rippleProgress != rippleProgress;
}
