import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/preferences_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth/login_view.dart';
import '../auth/signup_view.dart';
import '../common/app_logo.dart';
import '../common/primary_button.dart';
import '../common/secondary_button.dart';
import 'vpn_disclosure_view.dart';

import '../common/cyber_background.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleGuest(BuildContext context) async {
    final auth = context.read<AuthRepository>();
    final prefs = context.read<PreferencesService>();
    await auth.continueAsGuest();

    if (!context.mounted) return;

    if (prefs.hasGrantedVpnConsent) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VpnDisclosureView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CyberBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 50),
                            child: Center(
                              child: ScaleTransition(
                                scale: _scaleAnim,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 36,
                                            spreadRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const AppLogo(size: 88, showBadge: true),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 120),
                            child: Column(
                              children: [
                                Text(
                                  AppConstants.appName,
                                  style: AppTextStyles.displayLg.copyWith(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Quiet, disciplined network encryption engineered for academic privacy and mobile security.',
                                  style: AppTextStyles.bodyLg.copyWith(
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 3),
                          // Feature pills
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 200),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildPill(
                                      Icons.lock_outline,
                                      'OpenVPN Encrypted',
                                    ),
                                  ),
                                  _buildDivider(),
                                  Expanded(
                                    child: _buildPill(
                                      Icons.visibility_off_outlined,
                                      'Zero Payload Logs',
                                    ),
                                  ),
                                  _buildDivider(),
                                  Expanded(
                                    child: _buildPill(
                                      Icons.public,
                                      'Public Relays',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Primary Action: Create Account
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 260),
                            child: PrimaryButton(
                              text: 'Create Account',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpView(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Secondary Action: Log In
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 320),
                            child: SecondaryButton(
                              text: 'Log In',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginView(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Guest Action: Continue as Guest
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 380),
                            child: TextButton(
                              onPressed: () => _handleGuest(context),
                              child: Text(
                                'Continue as Guest',
                                style: AppTextStyles.labelLg.copyWith(
                                  color: AppColors.primaryAccent,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 420),
                            child: Text(
                              'Guest mode provides complete VPN functionality without an account.',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.mutedText,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryAccent),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 28, color: AppColors.border);
  }
}
