import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/platform/android_system.dart';
import '../../core/platform/haptics.dart';
import '../../core/storage/preferences_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../presentation/controllers/vpn_controller.dart';
import '../common/app_switch.dart';
import '../common/cyber_background.dart';
import '../common/ip_rotation_card.dart';
import '../common/motion.dart';
import '../common/settings_row.dart';
import '../privacy/legal_views.dart';
import '../privacy/privacy_center_view.dart';
import '../support/about_view.dart';
import '../support/faq_view.dart';
import '../support/report_problem_view.dart';
import 'profile_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider),
        ),
        title: Text(
          'Delete Account?',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          'This will permanently delete your profile, clear all saved favorites, erase session logs, and revoke VPN consent.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final auth = context.read<AuthRepository>();
              await auth.deleteAccount();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/welcome', (_) => false);
              }
            },
            child: Text(
              'Delete Forever',
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.errorStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, VpnController vpnRepo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider),
        ),
        title: Text(
          'Clear Local History?',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          'All session metrics and timestamps stored on this device will be erased.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              vpnRepo.clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Local history cleared'),
                  backgroundColor: AppColors.cardBackground,
                ),
              );
            },
            child: Text(
              'Clear',
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.errorStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    // Outside the app's MotionScope (tests) a local copy still saves the choice.
    final motion = MotionScope.settingsOf(context) ?? MotionSettings(prefs);
    final vpnRepo = context.read<VpnController>();
    final auth = context.watch<AuthRepository>();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: CyberBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // CONNECTION SECTION
              AnimatedFadeSlide(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('CONNECTION'),
                    _buildCard([
                      SettingsRow(
                        icon: Icons.flash_on_outlined,
                        title: 'Auto-connect on Launch',
                        subtitle: 'Establish tunnel immediately when opened',
                        trailing: AppSwitch(
                          value: prefs.autoConnect,
                          onChanged: (val) async {
                            await prefs.setAutoConnect(val);
                            setState(() {});
                          },
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.wifi_protected_setup_outlined,
                        title: 'Reconnect on Network Change',
                        subtitle:
                            'Retry the selected relay when internet returns',
                        trailing: AppSwitch(
                          value: prefs.reconnectOnNetworkChange,
                          onChanged: (val) async {
                            await prefs.setReconnectOnNetworkChange(val);
                            setState(() {});
                          },
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.autorenew_rounded,
                        title: 'Auto IP Rotation',
                        subtitle:
                            'Switch to the fastest server with a new IP '
                            'every ${vpnRepo.ipRotationMinutes} min',
                        trailing: AppSwitch(
                          value: vpnRepo.ipRotationEnabled,
                          onChanged: (val) async {
                            await vpnRepo.setIpRotationEnabled(val);
                            setState(() {});
                          },
                        ),
                      ),
                      if (vpnRepo.ipRotationEnabled) ...[
                        SettingsRow(
                          icon: Icons.timer_outlined,
                          title: 'Rotation Interval',
                          subtitle: vpnRepo.ipRotationMinutes == 1
                              ? 'Every minute'
                              : 'Every ${vpnRepo.ipRotationMinutes} minutes',
                          onTap: () async {
                            await showIpRotationIntervalPicker(
                              context,
                              vpnRepo,
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                        SettingsRow(
                          icon: Icons.flag_outlined,
                          title: 'Keep Same Country',
                          subtitle:
                              'Rotate only between servers in the current '
                              'country',
                          trailing: AppSwitch(
                            value: vpnRepo.ipRotationSameCountry,
                            onChanged: (val) async {
                              await vpnRepo.setIpRotationSameCountry(val);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                      SettingsRow(
                        icon: Icons.gpp_good_outlined,
                        title: 'Kill Switch',
                        subtitle:
                            'Block internet whenever the VPN is off, using '
                            "Android's Always-on VPN",
                        onTap: () => _showKillSwitchDialog(context),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // RELAY APIS & PERFORMANCE SECTION
              AnimatedFadeSlide(
                delayMs: Motion.staggerStepMs,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('RELAY APIS & PERFORMANCE'),
                    _buildCard([
                      SettingsRow(
                        icon: Icons.speed_rounded,
                        title: 'Auto-Detect Fastest Server',
                        subtitle:
                            "Test each country's servers from your network",
                        trailing: AppSwitch(
                          value: prefs.autoFastestServer,
                          onChanged: (val) async {
                            await prefs.setAutoFastestServer(val);
                            if (val) {
                              vpnRepo.detectFastestServer(forceProbe: true);
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.bolt_outlined,
                        title: 'Turbo Speed Optimization',
                        subtitle: 'TCP/UDP socket buffers and conservative packet sizing',
                        trailing: AppSwitch(
                          value: prefs.turboSpeedMode,
                          onChanged: (val) async {
                            await prefs.setTurboSpeedMode(val);
                            setState(() {});
                          },
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.public_outlined,
                        title: 'Relay API Region',
                        subtitle: prefs.apiRegion,
                        onTap: () =>
                            _showApiRegionDialog(context, prefs, vpnRepo),
                      ),
                      SettingsRow(
                        icon: Icons.key_outlined,
                        title: 'Custom Relay API',
                        subtitle:
                            prefs.customApiUrl != null &&
                                prefs.customApiUrl!.isNotEmpty
                            ? 'HTTPS endpoint configured'
                            : 'Use the official VPN Gate registry',
                        showDivider: false,
                        onTap: () =>
                            _showCustomApiDialog(context, prefs, vpnRepo),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // APPEARANCE SECTION
              AnimatedFadeSlide(
                delayMs: Motion.staggerStepMs * 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('APPEARANCE & FEEL'),
                    _buildCard([
                      SettingsRow(
                        icon: Icons.animation_rounded,
                        title: 'Animations',
                        subtitle: _motionLabels[motion.level]!.$1,
                        onTap: () => _showMotionDialog(context, motion),
                      ),
                      SettingsRow(
                        icon: Icons.vibration_rounded,
                        title: 'Haptic Feedback',
                        subtitle: 'Vibrate lightly on taps, connect and errors',
                        showDivider: false,
                        trailing: AppSwitch(
                          value: prefs.hapticsEnabled,
                          onChanged: (val) async {
                            Haptics.enabled = val;
                            await prefs.setHapticsEnabled(val);
                            setState(() {});
                          },
                        ),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // PRIVACY SECTION
              AnimatedFadeSlide(
                delayMs: Motion.staggerStepMs * 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('PRIVACY & DATA'),
                    _buildCard([
                      SettingsRow(
                        icon: Icons.shield_outlined,
                        title: 'Privacy Center',
                        subtitle: 'Transparent disclosures and data boundaries',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyCenterView(),
                            ),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.policy_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyView(),
                            ),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsView(),
                            ),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.delete_outline_rounded,
                        title: 'Clear Local History',
                        subtitle: 'Purge duration and session logs',
                        showDivider: false,
                        onTap: () => _confirmClearHistory(context, vpnRepo),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ACCOUNT SECTION
              AnimatedFadeSlide(
                delayMs: Motion.staggerStepMs * 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('ACCOUNT & SUBSCRIPTION'),
                    _buildCard([
                      SettingsRow(
                        icon: Icons.person_outline,
                        title: 'User Profile & Subscription',
                        subtitle: auth.currentUser?.name ?? 'Guest User',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileView(),
                            ),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        onTap: () async {
                          await auth.signOut();
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/welcome', (_) => false);
                          }
                        },
                      ),
                      SettingsRow(
                        icon: Icons.person_remove_outlined,
                        title: 'Delete Account',
                        isDestructive: true,
                        showDivider: false,
                        onTap: () => _confirmDeleteAccount(context),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SUPPORT SECTION
              AnimatedFadeSlide(
                delayMs: Motion.staggerStepMs * 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('SUPPORT & ACADEMIC INFO'),
                    _buildCard([
                      SettingsRow(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & FAQ',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FaqView()),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.feedback_outlined,
                        title: 'Report a Problem',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReportProblemView(),
                            ),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: 'About Galaxy VPN',
                        subtitle: 'Version 1.0.0 (Build 1)',
                        showDivider: false,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutView(),
                            ),
                          );
                        },
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primaryText,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.secondaryText,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDivider, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  static const Map<MotionLevel, (String, String)> _motionLabels = {
    MotionLevel.full: ('Full', 'Every effect, including the star field'),
    MotionLevel.lite: (
      'Lite (for low-end phones)',
      'Still backgrounds and stars, smoother and lighter on battery',
    ),
    MotionLevel.off: ('Off', 'No animations'),
  };

  void _showMotionDialog(BuildContext context, MotionSettings motion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider),
        ),
        title: Text(
          'Animations',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final level in MotionLevel.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _motionLabels[level]!.$1,
                  style: TextStyle(
                    color: motion.level == level
                        ? AppColors.primaryText
                        : AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _motionLabels[level]!.$2,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  motion.level == level
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: motion.level == level
                      ? AppColors.primaryText
                      : AppColors.mutedText,
                ),
                onTap: () async {
                  Haptics.tick();
                  await motion.setLevel(level);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Android only lets the system enforce a kill switch, so this explains the
  /// two toggles and opens the screen that has them.
  void _showKillSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider),
        ),
        title: Text(
          'Kill Switch',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          'Android enforces the kill switch itself. On the next screen, tap '
          'the gear next to Galaxy VPN and turn on:\n\n'
          '• Always-on VPN\n'
          '• Block connections without VPN\n\n'
          'Your internet is then blocked whenever the VPN is down, and Galaxy '
          'VPN reconnects automatically to your last VPN Gate server. '
          'Turn Always-on off there to stop it.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final opened = await AndroidSystem.openVpnSettings();
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Open Settings › Network › VPN on your phone to turn '
                      'on Always-on VPN.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Open VPN settings',
              style: TextStyle(color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiRegionDialog(
    BuildContext context,
    PreferencesService prefs,
    VpnController vpnRepo,
  ) {
    const regions = ['Global (Auto)', 'Asia / Pacific', 'Americas', 'Europe'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider),
        ),
        title: Text(
          'Relay API Region',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: regions.map((r) {
            final isSelected = prefs.apiRegion == r;
            return ListTile(
              title: Text(
                r,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryText
                      : AppColors.secondaryText,
                ),
              ),
              trailing: isSelected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primaryText,
                    )
                  : const Icon(
                      Icons.circle_outlined,
                      color: AppColors.mutedText,
                    ),
              onTap: () async {
                Haptics.tick();
                await prefs.setApiRegion(r);
                if (ctx.mounted) Navigator.of(ctx).pop();
                setState(() {});
                await vpnRepo.loadServers(forceRefresh: true);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCustomApiDialog(
    BuildContext context,
    PreferencesService prefs,
    VpnController vpnRepo,
  ) {
    final urlController = TextEditingController(text: prefs.customApiUrl ?? '');
    final keyController = TextEditingController(text: prefs.customApiKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider),
        ),
        title: Text(
          'Custom Relay API',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use an HTTPS endpoint that returns VPN Gate compatible CSV or relay JSON.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  labelText: 'Custom API Endpoint URL',
                  hintText: 'https://relay-mirror.org/api/iphone/',
                  prefixIcon: Icon(Icons.link, color: AppColors.primaryText),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                obscureText: true,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  labelText: 'API Key (Optional)',
                  hintText: 'sk_open_vpn_...',
                  prefixIcon: Icon(
                    Icons.vpn_key_outlined,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setCustomApiUrl(null);
              await prefs.setCustomApiKey(null);
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
              await vpnRepo.loadServers(forceRefresh: true);
            },
            child: const Text(
              'Reset Default',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              final uri = Uri.tryParse(url);
              if (url.isNotEmpty &&
                  (uri == null || uri.scheme != 'https' || uri.host.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid HTTPS relay API URL.'),
                  ),
                );
                return;
              }
              await prefs.setCustomApiUrl(url.isEmpty ? null : url);
              final key = keyController.text.trim();
              await prefs.setCustomApiKey(key.isEmpty ? null : key);
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
              await vpnRepo.loadServers(forceRefresh: true);
            },
            child: const Text('Save & Fetch'),
          ),
        ],
      ),
    );
  }
}
