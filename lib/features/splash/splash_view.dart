import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/preferences_service.dart';
import '../../data/repositories/vpn_repository.dart';
import '../common/app_logo.dart';
import '../home/main_navigation_shell.dart';
import '../onboarding/welcome_view.dart';
import '../onboarding/vpn_disclosure_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Particle data model
// ─────────────────────────────────────────────────────────────────────────────
class _Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speed;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle painter
// ─────────────────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x40FFFFFF);
    for (final p in particles) {
      final drawnY = (p.y - p.speed * progress) % 1.0;
      canvas.drawCircle(
        Offset(p.x * size.width, drawnY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Glow ring painter
// ─────────────────────────────────────────────────────────────────────────────
class _GlowRingPainter extends CustomPainter {
  final double progress;

  const _GlowRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Ring 1
    final r1 = 70.0 + progress * 60.0;
    final o1 = (1.0 - progress) * 0.5;
    final paint1 = Paint()
      ..color = AppColors.glowCyan.withValues(alpha: o1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r1, paint1);

    // Ring 2
    final p2 = (progress + 0.5) % 1.0;
    final r2 = 70.0 + p2 * 60.0;
    final o2 = (1.0 - p2) * 0.5;
    final paint2 = Paint()
      ..color = AppColors.glowCyan.withValues(alpha: o2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r2, paint2);
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash view
// ─────────────────────────────────────────────────────────────────────────────
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _entranceController;
  late AnimationController _glowPulseController;
  late AnimationController _particleController;
  late AnimationController _loadingDotsController;

  // Entrance animations
  late Animation<double> _shieldScale;
  late Animation<double> _shieldFade;
  late Animation<double> _appNameSlide;
  late Animation<double> _appNameFade;
  late Animation<double> _taglineFade;
  late Animation<double> _dotsAppear;

  // State
  bool _hasNavigated = false;
  Timer? _safetyTimer;
  Timer? _serverTimeoutTimer;
  PreferencesService? _cachedPrefs;

  // Particles
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Build particles
    final rng = math.Random();
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.5 + rng.nextDouble() * 2.0,
        opacity: 0.1 + rng.nextDouble() * 0.3,
        speed: 0.06 + rng.nextDouble() * 0.12,
      ));
    }

    // Entrance controller (plays once)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _shieldScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _shieldFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _appNameSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _appNameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.55, curve: Curves.easeIn),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.72, curve: Curves.easeIn),
      ),
    );
    _dotsAppear = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 0.85, curve: Curves.easeIn),
      ),
    );

    // Glow pulse — repeats
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Particle drift — repeats
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Loading dots — repeats
    _loadingDotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSequence();
    });

    // Safety timer: max 4500ms
    _safetyTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted && !_hasNavigated) _navigateNext();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedPrefs ??= context.read<PreferencesService>();
  }

  Future<void> _startSequence() async {
    final vpnRepo = context.read<VpnRepository>();

    final serverCompleter = Completer<void>();
    _serverTimeoutTimer?.cancel();
    _serverTimeoutTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!serverCompleter.isCompleted) serverCompleter.complete();
    });
    vpnRepo.loadServers().then((_) {
      if (!serverCompleter.isCompleted) serverCompleter.complete();
    }).catchError((_) {
      if (!serverCompleter.isCompleted) serverCompleter.complete();
    });

    await serverCompleter.future;

    if (mounted && !_hasNavigated) _navigateNext();
  }

  void _navigateNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _safetyTimer?.cancel();
    final prefs = _cachedPrefs ?? context.read<PreferencesService>();
    Widget destination;
    if (prefs.isAuthenticated) {
      if (prefs.hasGrantedVpnConsent) {
        destination = const MainNavigationShell();
      } else {
        destination = const VpnDisclosureView();
      }
    } else {
      destination = const WelcomeView();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => destination,
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _serverTimeoutTimer?.cancel();
    _entranceController.dispose();
    _glowPulseController.dispose();
    _particleController.dispose();
    _loadingDotsController.dispose();
    super.dispose();
  }

  // ─── Loading dots ──────────────────────────────────────────────────────────
  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _loadingDotsController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final raw = _loadingDotsController.value * 3 - i;
            final t = raw.clamp(0.0, 1.0);
            final opacity = 0.2 + 0.8 * math.pow(math.sin(math.pi * t), 2);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8.0 : 0),
              child: Opacity(
                opacity: opacity.toDouble(),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Dark gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.deepNavy,
                    AppColors.darkNavyMid,
                    AppColors.navyPurple,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // 2. Floating particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                );
              },
            ),

            // 3. Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // Shield + glow ring
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow rings
                              AnimatedBuilder(
                                animation: _glowPulseController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    size: const Size(220, 220),
                                    painter: _GlowRingPainter(
                                      progress: _glowPulseController.value,
                                    ),
                                  );
                                },
                              ),

                              // Shield logo
                              AnimatedBuilder(
                                animation: _entranceController,
                                builder: (context, child) {
                                  return ScaleTransition(
                                    scale: _shieldScale,
                                    child: FadeTransition(
                                      opacity: _shieldFade,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.glowCyanDim,
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const AppLogo(
                                    size: 96,
                                    showBadge: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App name + tagline
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App name (slide + fade)
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _appNameSlide.value),
                                child: Opacity(
                                  opacity: _appNameFade.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              AppConstants.appName,
                              style: GoogleFonts.inter(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Tagline
                          FadeTransition(
                            opacity: _taglineFade,
                            child: Text(
                              'Secure. Private. Free.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8BA0C8),
                                letterSpacing: 2.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading dots
                    FadeTransition(
                      opacity: _dotsAppear,
                      child: _buildLoadingDots(),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
