import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/storage/preferences_service.dart';
import '../../presentation/controllers/vpn_controller.dart';
import '../common/cyber_background.dart';
import '../common/permission_disclosure_card.dart';
import '../common/primary_button.dart';
import '../home/main_navigation_shell.dart';

class VpnDisclosureView extends StatefulWidget {
  const VpnDisclosureView({super.key});

  @override
  State<VpnDisclosureView> createState() => _VpnDisclosureViewState();
}

class _VpnDisclosureViewState extends State<VpnDisclosureView> {
  // CRITICAL REQUIREMENT: Checkbox must NEVER be preselected.
  bool _isConsentChecked = false;
  bool _isRequestingPermission = false;

  Future<void> _handleProceed() async {
    if (!_isConsentChecked) return;

    setState(() => _isRequestingPermission = true);

    try {
      final prefs = context.read<PreferencesService>();
      final vpnRepo = context.read<VpnController>();

      // Persist user consent
      await prefs.setVpnConsent(true);

      // Trigger Android VpnService permission flow
      await vpnRepo.vpnService.requestVpnPermission();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isRequestingPermission = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Permission & Privacy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: CyberBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        AnimatedFadeSlide(
                          delay: const Duration(milliseconds: 100),
                          child: PermissionDisclosureCard(
                            isConsentChecked: _isConsentChecked,
                            onConsentChanged: (val) {
                              setState(() {
                                _isConsentChecked = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedFadeSlide(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            'This disclosure complies with Android VpnService guidelines and university privacy standards.',
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
                const SizedBox(height: 16),
                // Continue button is enabled ONLY after user explicitly checks the box
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 250),
                  child: PrimaryButton(
                    text: 'Continue to Galaxy VPN',
                    isLoading: _isRequestingPermission,
                    onPressed: _isConsentChecked ? _handleProceed : null,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
