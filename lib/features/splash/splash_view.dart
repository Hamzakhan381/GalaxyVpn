import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/preferences_service.dart';
import '../../data/repositories/vpn_repository.dart';
import '../common/app_logo.dart';
import '../common/cyber_background.dart';
import '../common/motion.dart';
import '../home/main_navigation_shell.dart';
import '../onboarding/vpn_disclosure_view.dart';
import '../onboarding/welcome_view.dart';

/// Animated launch screen for Shark VPN.
///
/// A single intro timeline choreographs the whole sequence:
///   1. radar backdrop fades in while encrypted packets stream toward the core
///   2. the shield outline draws itself with a glowing pen tip
///   3. the fin snaps in and a "lock" shockwave fires
///   4. a light sheen crosses the mark, the title tracks in, the tagline wipes in
///   5. a zoom-through exit hands off to the next screen
/// A second, looping controller drives the ambient radar, orbits and shimmer.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // The intro deliberately runs a little over five seconds so the brand
  // sequence plays in full; the hard timeout is only a safety net.
  static const Duration _introDuration = Duration(milliseconds: 5200);
  static const Duration _loadTimeout = Duration(seconds: 5);
  static const Duration _hardTimeout = Duration(milliseconds: 6500);

  late final AnimationController _intro;
  late final AnimationController _loop;

  // Intro phases, all driven by [_intro].
  late final Animation<double> _backdrop;
  late final Animation<double> _packets;
  late final Animation<double> _ringTrace;
  late final Animation<double> _shieldTrace;
  late final Animation<double> _shieldFill;
  late final Animation<double> _finPop;
  late final Animation<double> _lockBurst;
  late final Animation<double> _sheen;
  late final Animation<double> _sheenEcho;
  late final Animation<double> _logoScale;
  late final Animation<double> _title;
  late final Animation<double> _tagline;
  late final Animation<double> _footer;
  late final Animation<double> _progress;
  late final Animation<double> _exit;

  Timer? _hardTimer;
  bool _navigated = false;
  bool _lockHapticFired = false;
  bool _reduceMotion = false;
  PreferencesService? _cachedPrefs;

  static const List<_BootStep> _steps = [
    _BootStep('Initializing secure core', Icons.memory_rounded),
    _BootStep('Generating session keys', Icons.key_rounded),
    _BootStep('Encrypting tunnel  ·  AES-256', Icons.lock_outline_rounded),
    _BootStep('Scanning for fastest relay', Icons.radar_rounded),
    _BootStep('Protection ready', Icons.verified_user_outlined),
  ];

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(vsync: this, duration: _introDuration)
      ..addListener(_onIntroTick);
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    Animation<double> interval(double a, double b, [Curve c = Curves.linear]) =>
        CurvedAnimation(
          parent: _intro,
          curve: Interval(a, b, curve: c),
        );

    _backdrop = interval(0.00, 0.22, Curves.easeOut);
    _packets = interval(0.06, 0.30, Curves.easeOut);
    _ringTrace = interval(0.02, 0.32, Curves.easeInOutCubic);
    _shieldTrace = interval(0.06, 0.40, Curves.easeInOutCubic);
    _shieldFill = interval(0.30, 0.46, Curves.easeOut);
    _finPop = interval(0.36, 0.58, Curves.elasticOut);
    _lockBurst = interval(0.40, 0.66, Curves.easeOutCubic);
    _sheen = interval(0.50, 0.66, Curves.easeInOutSine);
    _sheenEcho = interval(0.70, 0.84, Curves.easeInOutSine);
    _logoScale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(interval(0.00, 0.46, Curves.easeOutBack));
    _title = interval(0.42, 0.66, Curves.easeOutCubic);
    _tagline = interval(0.52, 0.78, Curves.easeInOutCubic);
    _footer = interval(0.06, 0.24, Curves.easeOut);
    _progress = interval(0.06, 0.86, Curves.easeInOutCubic);
    _exit = interval(0.88, 1.00, Curves.easeInCubic);

    _hardTimer = Timer(_hardTimeout, _navigateNext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _run();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _cachedPrefs ??= context.read<PreferencesService>();
    } catch (_) {}
    _reduceMotion = Motion.isReduced(context);
    if (_reduceMotion) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  void _onIntroTick() {
    if (!_lockHapticFired && _intro.value >= 0.42) {
      _lockHapticFired = true;
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _run() async {
    // Opportunistically preload servers in the background without blocking the intro
    unawaited(_loadServers());

    try {
      await _intro.forward().orCancel;
    } on TickerCanceled {
      return;
    } catch (e) {
      debugPrint('Splash startup error: $e');
    }
    _navigateNext();
  }

  Future<void> _loadServers() async {
    try {
      final repo = context.read<VpnRepository>();
      await repo.loadServers().timeout(_loadTimeout);
    } catch (e) {
      debugPrint('Splash server preload skipped: $e');
    }
  }

  void _navigateNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _hardTimer?.cancel();

    Widget destination;
    String routeName;
    try {
      final prefs = _cachedPrefs ?? context.read<PreferencesService>();
      if (prefs.isAuthenticated) {
        if (prefs.hasGrantedVpnConsent) {
          destination = const MainNavigationShell();
          routeName = AppRouter.home;
        } else {
          destination = const VpnDisclosureView();
          routeName = AppRouter.disclosure;
        }
      } else {
        destination = const WelcomeView();
        routeName = AppRouter.welcome;
      }
    } catch (e) {
      debugPrint('Splash routing fallback: $e');
      destination = const WelcomeView();
      routeName = AppRouter.welcome;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: routeName),
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _hardTimer?.cancel();
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  _BootStep get _step {
    final p = _intro.value;
    if (p < 0.20) return _steps[0];
    if (p < 0.38) return _steps[1];
    if (p < 0.56) return _steps[2];
    if (p < 0.86) return _steps[3];
    return _steps[4];
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.primaryBackground,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          body: CyberBackground(
            showAmbientGlow: false,
            enableVpnVideoEffect: false,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 680;
                  final auraSize = isCompact ? 200.0 : 250.0;
                  final logoSize = isCompact ? 92.0 : 108.0;
                  final titleFontSize = isCompact ? 28.0 : 34.0;
                  final topSpacing = isCompact ? 16.0 : 36.0;

                  return Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      clipBehavior: Clip.none,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_intro, _loop]),
                            builder: (context, _) => _buildContent(
                              auraSize: auraSize,
                              logoSize: logoSize,
                              titleFontSize: titleFontSize,
                              topSpacing: topSpacing,
                              isCompact: isCompact,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required double auraSize,
    required double logoSize,
    required double titleFontSize,
    required double topSpacing,
    required bool isCompact,
  }) {
    final loop = _loop.value;
    final exit = _exit.value;
    final fadeOut = 1.0 - exit;
    final breathe = _reduceMotion
        ? 1.0
        : 1.0 + 0.018 * math.sin(loop * 2 * math.pi) * _shieldFill.value;
    final logoScale = _logoScale.value * breathe * (1.0 + 0.22 * exit);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(height: topSpacing),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: auraSize,
              height: auraSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _SplashBackdropPainter(
                          loop: loop,
                          appear: _backdrop.value,
                          packets: _packets.value * fadeOut,
                          lockBurst: _lockBurst.value,
                          exit: exit,
                          reduceMotion: _reduceMotion,
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: (_backdrop.value * fadeOut).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: logoScale,
                      child: SizedBox.square(
                        dimension: logoSize,
                        child: CustomPaint(
                          painter: _SplashLogoPainter(
                            ringTrace: _ringTrace.value,
                            shieldTrace: _shieldTrace.value,
                            fill: _shieldFill.value,
                            fin: _finPop.value,
                            sheen: _sheen.value > 0 && _sheen.value < 1
                                ? _sheen.value
                                : _sheenEcho.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isCompact ? 16 : 22),
            _buildTitle(titleFontSize, loop, fadeOut),
            const SizedBox(height: 10),
            _buildTagline(isCompact, fadeOut),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(bottom: isCompact ? 24.0 : 40.0),
          child: Opacity(
            opacity: (_footer.value * fadeOut).clamp(0.0, 1.0),
            child: _ProgressFooter(
              progress: _progress.value,
              loop: loop,
              step: _step,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(double fontSize, double loop, double fadeOut) {
    final t = _title.value;
    // Shimmer highlight sweeps across the wordmark on every loop.
    final shimmerX = lerpDouble(-0.4, 1.4, loop)!;

    return Opacity(
      opacity: (t * fadeOut).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, lerpDouble(16, 0, t)!),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: const [
                AppColors.secondaryText,
                AppColors.primaryText,
                AppColors.secondaryText,
              ],
              stops: [
                (shimmerX - 0.22).clamp(0.0, 1.0),
                shimmerX.clamp(0.0, 1.0),
                (shimmerX + 0.22).clamp(0.0, 1.0),
              ],
            ).createShader(bounds),
            child: Text(
              AppConstants.appName,
              style: AppTextStyles.displayLg.copyWith(
                fontSize: fontSize,
                letterSpacing: lerpDouble(14, 0.6, t),
                color: AppColors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagline(bool isCompact, double fadeOut) {
    final reveal = _tagline.value * 1.2;

    return Opacity(
      opacity: fadeOut,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, (reveal - 0.2).clamp(0.0, 1.0), reveal.clamp(0.0, 1.0)],
        ).createShader(bounds),
        child: Text(
          'SECURE  •  PRIVATE  •  FAST',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.secondaryText,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 10 : 11,
          ),
        ),
      ),
    );
  }
}

class _BootStep {
  final String label;
  final IconData icon;

  const _BootStep(this.label, this.icon);
}

class _ProgressFooter extends StatelessWidget {
  final double progress;
  final double loop;
  final _BootStep step;

  const _ProgressFooter({
    required this.progress,
    required this.loop,
    required this.step,
  });

  static const double _barWidth = 200;
  static const double _labelWidth = 44;

  @override
  Widget build(BuildContext context) {
    final fillWidth = _barWidth * progress.clamp(0.03, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Balances the percentage label so the bar stays centred.
            const SizedBox(width: _labelWidth),
            _buildBar(fillWidth),
            SizedBox(
              width: _labelWidth,
              child: Text(
                '${(progress * 100).round()}%',
                textAlign: TextAlign.right,
                maxLines: 1,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  step.icon,
                  key: ValueKey(step.icon),
                  size: 14,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.6),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    step.label,
                    key: ValueKey(step.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double fillWidth) {
    return SizedBox(
      width: _barWidth,
      height: 10,
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Filled portion with a travelling highlight.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              width: fillWidth,
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryText.withValues(alpha: 0.35),
                      AppColors.primaryText,
                      AppColors.primaryText.withValues(alpha: 0.6),
                      AppColors.primaryText,
                    ],
                    stops: [0.0, 0.55, (loop * 1.2).clamp(0.6, 0.98), 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Glowing head
          Positioned(
            left: fillWidth - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryText,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryText.withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ambient layer around the logo: glow, radar sweep, tick ring, pulse rings,
/// orbiting nodes and encrypted packets converging on the core.
/// Intentionally paints beyond its bounds so the effect fills the screen.
class _SplashBackdropPainter extends CustomPainter {
  final double loop;
  final double appear;
  final double packets;
  final double lockBurst;
  final double exit;
  final bool reduceMotion;

  _SplashBackdropPainter({
    required this.loop,
    required this.appear,
    required this.packets,
    required this.lockBurst,
    required this.exit,
    required this.reduceMotion,
  });

  static const int _tickCount = 48;
  static const int _packetCount = 18;

  @override
  void paint(Canvas canvas, Size size) {
    if (appear <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final fade = appear * (1.0 - exit);
    final wave = math.sin(loop * 2 * math.pi);

    // 1. Ambient glow behind the mark
    final glowRadius = r * 1.5;
    canvas.drawCircle(
      c,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primaryText.withValues(
              alpha: (0.07 + 0.02 * wave) * fade,
            ),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: glowRadius)),
    );

    // 2. Static hairline orbit rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final (factor, alpha) in const [(0.62, 0.07), (0.82, 0.05)]) {
      ringPaint.color = AppColors.primaryText.withValues(alpha: alpha * fade);
      canvas.drawCircle(c, r * factor, ringPaint);
    }

    // 3. Rotating tick ring (rotation is a multiple of the tick pattern's
    //    symmetry, so the loop wraps seamlessly)
    final tickRadius = r * 1.0;
    final rotation = reduceMotion ? 0.0 : loop * (2 * math.pi / 12);
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < _tickCount; i++) {
      final major = i % 4 == 0;
      final a = rotation + i * 2 * math.pi / _tickCount;
      final dir = Offset(math.cos(a), math.sin(a));
      tickPaint
        ..strokeWidth = major ? 1.4 : 0.8
        ..color = AppColors.primaryText.withValues(
          alpha: (major ? 0.22 : 0.09) * fade,
        );
      canvas.drawLine(
        c + dir * tickRadius,
        c + dir * (tickRadius - (major ? 7 : 4)),
        tickPaint,
      );
    }

    if (!reduceMotion) {
      // 4. Radar sweep wedge with a leading edge
      final sweepAngle = loop * 2 * math.pi - math.pi / 2;
      const wedge = math.pi * 0.4;
      final rect = Rect.fromCircle(center: c, radius: tickRadius);
      canvas.drawArc(
        rect,
        sweepAngle - wedge,
        wedge,
        true,
        Paint()
          ..shader = SweepGradient(
            colors: [
              Colors.transparent,
              AppColors.primaryText.withValues(alpha: 0.11 * fade),
            ],
            endAngle: wedge,
            transform: GradientRotation(sweepAngle - wedge),
          ).createShader(rect),
      );
      canvas.drawLine(
        c,
        c + Offset(math.cos(sweepAngle), math.sin(sweepAngle)) * tickRadius,
        Paint()
          ..strokeWidth = 1
          ..color = AppColors.primaryText.withValues(alpha: 0.28 * fade),
      );

      // 5. Expanding pulse rings
      for (int i = 0; i < 3; i++) {
        final phase = (loop + i / 3) % 1.0;
        final radius = lerpDouble(r * 0.42, r * 1.3, phase)!;
        final a = math.pow(1 - phase, 2).toDouble() * 0.2 * fade;
        canvas.drawCircle(
          c,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = AppColors.primaryText.withValues(alpha: a),
        );
      }

      // 6. Orbiting nodes on the outer ring (integer speeds keep the loop seamless)
      for (final (speed, offset) in const [(1, 0.0), (-1, 2.1), (2, 4.2)]) {
        final a = offset + loop * 2 * math.pi * speed;
        final p = c + Offset(math.cos(a), math.sin(a)) * (r * 0.82);
        canvas.drawCircle(
          p,
          6,
          Paint()
            ..color = AppColors.primaryText.withValues(alpha: 0.12 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          p,
          1.8,
          Paint()..color = AppColors.primaryText.withValues(alpha: 0.8 * fade),
        );
      }

      // 7. Encrypted packets converging on the core
      if (packets > 0) {
        final packetPaint = Paint()..strokeCap = StrokeCap.round;
        for (int i = 0; i < _packetCount; i++) {
          final seed = (i * 0.618034) % 1.0;
          final speed = i.isEven ? 1 : 2;
          final phase = (loop * speed + seed) % 1.0;
          final a = i * 2 * math.pi / _packetCount + seed * 0.6;
          final dir = Offset(math.cos(a), math.sin(a));
          final dist = lerpDouble(
            r * 2.4,
            r * 0.55,
            Curves.easeInQuad.transform(phase),
          )!;
          final alpha = math.sin(phase * math.pi) * 0.55 * packets;
          final head = c + dir * dist;
          packetPaint
            ..strokeWidth = 1.4
            ..color = AppColors.primaryText.withValues(alpha: alpha * 0.45);
          canvas.drawLine(head, head + dir * 14, packetPaint);
          canvas.drawCircle(
            head,
            1.6,
            Paint()..color = AppColors.primaryText.withValues(alpha: alpha),
          );
        }
      }
    }

    // 8. Lock shockwave when the fin snaps in, and a final one on exit
    void shockwave(double t, double maxFactor, double strength) {
      if (t <= 0 || t >= 1) return;
      final radius = lerpDouble(r * 0.35, r * maxFactor, t)!;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - t) + 0.5
          ..color = AppColors.primaryText.withValues(alpha: (1 - t) * strength),
      );
    }

    shockwave(lockBurst, 1.6, 0.55 * appear);
    shockwave(exit, 2.4, 0.45);
  }

  @override
  bool shouldRepaint(_SplashBackdropPainter old) =>
      old.loop != loop ||
      old.appear != appear ||
      old.packets != packets ||
      old.lockBurst != lockBurst ||
      old.exit != exit ||
      old.reduceMotion != reduceMotion;
}

/// Draws the Shark VPN mark progressively: ring arc, shield outline with a
/// glowing pen tip, charcoal fill, elastic fin, then a diagonal light sheen.
class _SplashLogoPainter extends CustomPainter {
  final double ringTrace;
  final double shieldTrace;
  final double fill;
  final double fin;
  final double sheen;

  _SplashLogoPainter({
    required this.ringTrace,
    required this.shieldTrace,
    required this.fill,
    required this.fin,
    required this.sheen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = size.center(Offset.zero);
    final shield = SharkLogoGeometry.shield(size);

    // Outer ring arc
    if (ringTrace > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: w * 0.48),
        -math.pi / 2,
        2 * math.pi * ringTrace,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = AppColors.borderDivider,
      );
    }

    // Charcoal body + soft inner light
    if (fill > 0) {
      canvas.drawPath(
        shield,
        Paint()..color = AppColors.cardBackground.withValues(alpha: fill),
      );
      canvas.drawPath(
        shield,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.3),
            colors: [
              AppColors.primaryText.withValues(alpha: 0.10 * fill),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & size),
      );
    }

    // Shield outline, drawn progressively
    if (shieldTrace > 0) {
      final strokePaint = Paint()
        ..color = AppColors.primaryText.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (shieldTrace >= 1) {
        canvas.drawPath(shield, strokePaint);
      } else {
        for (final metric in shield.computeMetrics()) {
          final length = metric.length * shieldTrace;
          canvas.drawPath(metric.extractPath(0, length), strokePaint);

          final tangent = metric.getTangentForOffset(length);
          if (tangent != null) {
            canvas.drawCircle(
              tangent.position,
              w * 0.07,
              Paint()
                ..color = AppColors.primaryText.withValues(alpha: 0.55)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
            );
            canvas.drawCircle(
              tangent.position,
              w * 0.025,
              Paint()..color = AppColors.primaryText,
            );
          }
        }
      }
    }

    // Fin snaps in with an elastic scale around its base
    if (fin > 0) {
      final anchor = Offset(w * 0.5, size.height * 0.62);
      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.scale(fin.clamp(0.0, 1.4));
      canvas.translate(-anchor.dx, -anchor.dy);
      canvas.drawPath(
        SharkLogoGeometry.fin(size),
        Paint()..color = AppColors.primaryText,
      );
      final (slitStart, slitEnd) = SharkLogoGeometry.slit(size);
      canvas.drawLine(
        slitStart,
        slitEnd,
        Paint()
          ..color = AppColors.cardBackground
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.025
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    // Diagonal light sheen clipped to the shield
    if (sheen > 0 && sheen < 1) {
      canvas.save();
      canvas.clipPath(shield);
      final x = lerpDouble(-w * 0.8, w * 1.4, sheen)!;
      final band = Rect.fromLTWH(
        x,
        -size.height * 0.2,
        w * 0.4,
        size.height * 1.4,
      );
      canvas.translate(band.center.dx, band.center.dy);
      canvas.rotate(math.pi / 8);
      canvas.translate(-band.center.dx, -band.center.dy);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.primaryText.withValues(alpha: 0.35),
              Colors.transparent,
            ],
          ).createShader(band),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SplashLogoPainter old) =>
      old.ringTrace != ringTrace ||
      old.shieldTrace != shieldTrace ||
      old.fill != fill ||
      old.fin != fin ||
      old.sheen != sheen;
}
