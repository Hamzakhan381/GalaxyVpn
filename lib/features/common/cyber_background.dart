import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../domain/entities/vpn_connection_state.dart';
import 'motion.dart';

/// Premium dark background featuring deep obsidian black (#090909), subtle
/// charcoal surface depth, and dynamic VPN network stream & tunnel video animation.
class CyberBackground extends StatefulWidget {
  final Widget child;
  final bool showAmbientGlow;
  final bool animateGlow;
  final Color? glowAccentColor;
  final VpnConnectionState? vpnState;
  final bool enableVpnVideoEffect;

  const CyberBackground({
    super.key,
    required this.child,
    this.showAmbientGlow = true,
    this.animateGlow = true,
    this.glowAccentColor,
    this.vpnState,
    this.enableVpnVideoEffect = true,
  });

  @override
  State<CyberBackground> createState() => _CyberBackgroundState();
}

class _CyberBackgroundState extends State<CyberBackground>
    with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late AnimationController _videoCtrl;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _videoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoops();
  }

  @override
  void didUpdateWidget(covariant CyberBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLoops();
  }

  /// The glow and network effect loop forever behind every screen, so they
  /// only run at full animation quality; otherwise the backdrop is still.
  void _syncLoops() {
    final animate = !_isTestEnvironment && !Motion.isLite(context);
    void sync(AnimationController ctrl, bool on, {bool reverse = false}) {
      if (on && !ctrl.isAnimating) {
        ctrl.repeat(reverse: reverse);
      } else if (!on && ctrl.isAnimating) {
        ctrl.stop();
      }
    }

    sync(_animCtrl, animate && widget.animateGlow, reverse: true);
    sync(_videoCtrl, animate && widget.enableVpnVideoEffect);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnectedGlow =
        widget.glowAccentColor == AppColors.connectedStatus;

    return Container(
      color: AppColors.primaryBackground,
      child: Stack(
        children: [
          // 1. Base obsidian to rich black gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.secondaryBackground, // #121212
                    AppColors.primaryBackground, // #090909
                  ],
                ),
              ),
            ),
          ),

          // 2. Micro-subtle minimal dot matrix grid (cybersecurity geometry)
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _MinimalGridPainter()),
            ),
          ),

          // 3. Dynamic VPN Network Stream & Tunnel Video Animation Layer
          if (widget.enableVpnVideoEffect)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _videoCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _VpnDynamicNetworkVideoPainter(
                        progress: _videoCtrl.value,
                        vpnState: widget.vpnState,
                        glowAccentColor: widget.glowAccentColor,
                      ),
                    );
                  },
                ),
              ),
            ),

          // 4. Restrained status ambient lighting (active only for real states)
          if (widget.showAmbientGlow && widget.glowAccentColor != null)
            Positioned(
              top: -120,
              left: 0,
              right: 0,
              height: 280,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, _) {
                    final pulse =
                        0.85 + (0.15 * math.sin(_animCtrl.value * math.pi));
                    final double baseAlpha = isConnectedGlow
                        ? 0.05
                        : (widget.glowAccentColor == AppColors.errorStatus
                              ? 0.04
                              : 0.025);
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.glowAccentColor!.withValues(
                              alpha: baseAlpha * pulse,
                            ),
                            Colors.transparent,
                          ],
                          radius: 0.8,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 5. Foreground page content
          widget.child,
        ],
      ),
    );
  }
}

/// Subtle hairline dot grid for high-end technical depth
class _MinimalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.015)
      ..style = PaintingStyle.fill;

    const double spacing = 32.0;
    const double radius = 0.75;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dynamic procedural cybersecurity stream & tunnel animation that simulates a high-tech
/// VPN motion-graphic video loop at 60fps with zero asset overhead.
class _VpnDynamicNetworkVideoPainter extends CustomPainter {
  final double progress;
  final VpnConnectionState? vpnState;
  final Color? glowAccentColor;

  _VpnDynamicNetworkVideoPainter({
    required this.progress,
    this.vpnState,
    this.glowAccentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final center = Offset(w * 0.5, h * 0.35);

    final isConnecting =
        vpnState == VpnConnectionState.connecting ||
        vpnState == VpnConnectionState.checking;
    final isConnected = vpnState == VpnConnectionState.connected;

    // ── 1. Perspective 3D Cybersecurity Horizon Lines ────────────────────────
    final horizonPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final vanishingPoint = Offset(w * 0.5, -40);
    for (int i = 0; i <= 8; i++) {
      final spreadX = (i / 8.0) * w * 1.5 - (w * 0.25);
      canvas.drawLine(vanishingPoint, Offset(spreadX, h), horizonPaint);
    }

    // Horizontal scanning arcs (latitude lines)
    for (int j = 1; j <= 5; j++) {
      final y = math.pow(j / 5.0, 1.8) * (h * 0.75);
      final arcPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.012 + (j * 0.003))
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(w, y.toDouble()),
        arcPaint,
      );
    }

    // ── 2. Encrypted Tunnel Topological Paths (Bezier Curves) ────────────────
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final List<Path> tunnels = [];

    // Tunnel 1: Top-left entering center
    final p1 = Path()
      ..moveTo(-20, h * 0.15)
      ..cubicTo(w * 0.2, h * 0.18, w * 0.3, h * 0.30, center.dx, center.dy);
    tunnels.add(p1);

    // Tunnel 2: Bottom-left curving up to center
    final p2 = Path()
      ..moveTo(-30, h * 0.70)
      ..cubicTo(w * 0.15, h * 0.60, w * 0.25, h * 0.45, center.dx, center.dy);
    tunnels.add(p2);

    // Tunnel 3: Top-right entering center
    final p3 = Path()
      ..moveTo(w + 20, h * 0.18)
      ..cubicTo(w * 0.8, h * 0.22, w * 0.7, h * 0.30, center.dx, center.dy);
    tunnels.add(p3);

    // Tunnel 4: Bottom-right curving up to center
    final p4 = Path()
      ..moveTo(w + 30, h * 0.72)
      ..cubicTo(w * 0.85, h * 0.62, w * 0.75, h * 0.45, center.dx, center.dy);
    tunnels.add(p4);

    // Tunnel 5: Vertical spine down towards server card
    final p5 = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(center.dx, h * 0.52, center.dx, h * 0.65, center.dx, h * 0.88);
    tunnels.add(p5);

    // Draw the subtle tunnel guides
    for (final p in tunnels) {
      pathPaint.color = isConnected
          ? AppColors.connectedStatus.withValues(alpha: 0.04)
          : isConnecting
          ? const Color(0xFFFFFFFF).withValues(alpha: 0.05)
          : const Color(0xFFFFFFFF).withValues(alpha: 0.022);
      canvas.drawPath(p, pathPaint);
    }

    // ── 3. Flowing Data Packets Along Tunnels ─────────────────────────────────
    final speedMultiplier = isConnecting ? 2.6 : (isConnected ? 1.4 : 1.0);
    final packetColor = isConnected
        ? AppColors.connectedStatus
        : isConnecting
        ? AppColors.pureWhite
        : AppColors.secondaryText;

    for (int tIdx = 0; tIdx < tunnels.length; tIdx++) {
      final path = tunnels[tIdx];
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;
      final metric = metrics.first;
      final totalLen = metric.length;

      // 2 packets per tunnel with staggered offsets
      for (int k = 0; k < 2; k++) {
        final phaseOffset = (k * 0.5) + (tIdx * 0.17);
        final rawT = (progress * speedMultiplier + phaseOffset) % 1.0;
        final dist = rawT * totalLen;
        final tangent = metric.getTangentForOffset(dist);
        if (tangent == null) continue;

        final pos = tangent.position;
        final v = tangent.vector;
        final vLen = v.distance;
        final dir = vLen > 0
            ? Offset(v.dx / vLen, v.dy / vLen)
            : const Offset(1, 0);

        final packetAlpha = isConnected
            ? 0.45
            : isConnecting
            ? 0.60
            : 0.18;

        // Packet core dot
        final dotPaint = Paint()
          ..color = packetColor.withValues(alpha: packetAlpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, isConnecting ? 2.4 : 1.8, dotPaint);

        // Motion trail dash behind packet
        final trailPaint = Paint()
          ..color = packetColor.withValues(alpha: packetAlpha * 0.4)
          ..strokeWidth = isConnecting ? 2.0 : 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          pos,
          pos - (dir * (isConnecting ? 14.0 : 8.0)),
          trailPaint,
        );

        // Soft glow halo around packet
        final glowPaint = Paint()
          ..color = packetColor.withValues(alpha: packetAlpha * 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 5.0, glowPaint);
      }
    }

    // ── 4. Constellation Relay Nodes (Cyber Gateways) ─────────────────────────
    final List<Offset> nodes = [
      Offset(w * 0.18, h * 0.16),
      Offset(w * 0.82, h * 0.19),
      Offset(w * 0.12, h * 0.64),
      Offset(w * 0.88, h * 0.66),
      Offset(w * 0.32, h * 0.84),
      Offset(w * 0.68, h * 0.82),
    ];

    // Interconnect lines between nearby nodes
    final linkPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.02)
      ..strokeWidth = 0.8;
    canvas.drawLine(nodes[0], nodes[1], linkPaint);
    canvas.drawLine(nodes[0], nodes[2], linkPaint);
    canvas.drawLine(nodes[1], nodes[3], linkPaint);
    canvas.drawLine(nodes[2], nodes[4], linkPaint);
    canvas.drawLine(nodes[3], nodes[5], linkPaint);
    canvas.drawLine(nodes[4], nodes[5], linkPaint);

    final nodePaint = Paint()..style = PaintingStyle.fill;
    final nodeRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < nodes.length; i++) {
      final nPos = nodes[i];
      final nodePulse =
          0.6 + 0.4 * math.sin((progress * 2 * math.pi) + (i * 1.1));

      final nodeColor = isConnected
          ? AppColors.connectedStatus
          : isConnecting
          ? AppColors.pureWhite
          : AppColors.secondaryText;

      final nodeAlpha = isConnected
          ? 0.35 * nodePulse
          : isConnecting
          ? 0.45 * nodePulse
          : 0.15;

      nodePaint.color = nodeColor.withValues(alpha: nodeAlpha);
      nodeRingPaint.color = nodeColor.withValues(alpha: nodeAlpha * 0.5);

      canvas.drawCircle(nPos, 1.8, nodePaint);
      canvas.drawCircle(nPos, 5.5 + (nodePulse * 2.5), nodeRingPaint);
    }

    // ── 5. Drifting Cryptographic Telemetry Indicators ───────────────────────
    final List<_TelemetryTag> telemetryTags = [
      _TelemetryTag('[TLS_1.3]', Offset(w * 0.08, h * 0.28)),
      _TelemetryTag('[AES_256_GCM]', Offset(w * 0.74, h * 0.25)),
      _TelemetryTag('[SHA_512]', Offset(w * 0.06, h * 0.52)),
      _TelemetryTag('[TUNNEL_OK]', Offset(w * 0.76, h * 0.55)),
      _TelemetryTag('[IPV6_ROUTED]', Offset(w * 0.10, h * 0.78)),
      _TelemetryTag('[ZERO_LEAK]', Offset(w * 0.72, h * 0.76)),
    ];

    for (int i = 0; i < telemetryTags.length; i++) {
      final tag = telemetryTags[i];
      final driftY = math.sin((progress * 2 * math.pi) + (i * 1.3)) * 6.0;
      final tagAlpha = isConnected
          ? 0.065
          : isConnecting
          ? 0.09
          : 0.035;

      final textSpan = TextSpan(
        text: tag.label,
        style: TextStyle(
          color:
              (isConnected ? AppColors.connectedStatus : AppColors.primaryText)
                  .withValues(alpha: tagAlpha),
          fontSize: 8.5,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      );

      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();

      tp.paint(canvas, Offset(tag.pos.dx, tag.pos.dy + driftY));
    }
  }

  @override
  bool shouldRepaint(_VpnDynamicNetworkVideoPainter old) =>
      old.progress != progress ||
      old.vpnState != vpnState ||
      old.glowAccentColor != glowAccentColor;
}

class _TelemetryTag {
  final String label;
  final Offset pos;
  const _TelemetryTag(this.label, this.pos);
}

/// Refined entrance animation providing subtle vertical slide and opacity fade-in.
///
/// Replays whenever an enclosing [EntranceReplay] fires, and renders instantly
/// when the user has asked for reduced motion.
class AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration? delay;
  final int? delayMs;
  final Duration duration;
  final Offset offset;
  final double beginScale;

  const AnimatedFadeSlide({
    super.key,
    required this.child,
    this.delay,
    this.delayMs,
    this.duration = const Duration(milliseconds: 350),
    this.offset = const Offset(0.0, 0.08),
    this.beginScale = 1.0,
  });

  @override
  State<AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  ValueNotifier<int>? _replay;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = curve;
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curve);
    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final replay = EntranceReplay.maybeOf(context);
    if (replay != _replay) {
      _replay?.removeListener(_replayEntrance);
      _replay = replay?..addListener(_replayEntrance);
    }
    if (_generation == 0) _play();
  }

  /// Below full quality only the first entrance plays: fading every card in
  /// again on each tab switch made low-end phones stutter.
  void _replayEntrance() {
    if (Motion.isLite(context)) return;
    _play();
  }

  void _play() {
    final generation = ++_generation;
    if (Motion.isReduced(context)) {
      _controller.value = 1.0;
      return;
    }
    final effectiveDelay =
        widget.delay ?? Duration(milliseconds: widget.delayMs ?? 0);
    if (Motion.isTestEnvironment || effectiveDelay == Duration.zero) {
      _controller.forward(from: 0.0);
      return;
    }
    _controller.value = 0.0;
    Future.delayed(effectiveDelay, () {
      if (mounted && generation == _generation) {
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _replay?.removeListener(_replayEntrance);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SlideTransition(
      position: _slideAnimation,
      child: widget.child,
    );
    if (widget.beginScale != 1.0) {
      child = ScaleTransition(scale: _scaleAnimation, child: child);
    }
    return FadeTransition(opacity: _fadeAnimation, child: child);
  }
}
