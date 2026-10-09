import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/preferences_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_view.dart';
import '../auth/signup_view.dart';
import '../common/app_logo.dart';
import '../common/primary_button.dart';
import '../common/secondary_button.dart';
import 'vpn_disclosure_view.dart';

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
      duration: const Duration(milliseconds: 600),
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
    final auth = context.read<AuthService>();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.mistBase, Color(0xFFECF2FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: const AppLogo(size: 88, showBadge: true),
                ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.navy100,
                    fontSize: 30,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Quiet, disciplined network encryption engineered for academic privacy and mobile security.',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.navy70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 3),
                // Feature pills
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border(
                      top: const BorderSide(
                          color: AppColors.signalLime, width: 2.5),
                      left: BorderSide(color: AppColors.surfaceBorder, width: 1),
                      right:
                          BorderSide(color: AppColors.surfaceBorder, width: 1),
                      bottom:
                          BorderSide(color: AppColors.surfaceBorder, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            _buildPill(Icons.lock_outline, 'OpenVPN Encrypted'),
                      ),
                      _buildDivider(),
                      Expanded(
                        child: _buildPill(
                            Icons.visibility_off_outlined, 'Zero Payload Logs'),
                      ),
                      _buildDivider(),
                      Expanded(
                        child: _buildPill(Icons.public, 'Public Relays'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Primary Action: Create Account
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.inkNavy.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: PrimaryButton(
                    text: 'Create Account',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignUpView()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary Action: Log In
                SecondaryButton(
                  text: 'Log In',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Guest Action: Continue as Guest
                TextButton(
                  onPressed: () => _handleGuest(context),
                  child: Text(
                    'Continue as Guest',
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.navy70,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guest mode provides complete VPN functionality without an account.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.navy45,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.inkNavy),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.navy70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.navy12,
    );
  }
}
