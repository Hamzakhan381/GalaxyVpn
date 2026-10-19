import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../common/cyber_background.dart';
import '../common/primary_button.dart';
import '../common/secondary_button.dart';

/// Premium Profile & Cybersecurity Subscription View.
/// Designed with obsidian black and charcoal surfaces, crisp pure white typography,
/// and clear subscription details without excessive gold/clutter.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _nameController = TextEditingController(text: auth.currentUser?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.updateProfile(name: _nameController.text.trim());
      setState(() => _isEditing = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSubscriptionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: AppColors.connectedStatus,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Subscription Active',
              style: AppTextStyles.headlineSm.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are currently enrolled in the Academic Privacy License with full access to all global encrypted relays.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildDialogFeature('Plan', 'CyberShield Academic Pro'),
            const SizedBox(height: 8),
            _buildDialogFeature('Status', 'Active • Full Access'),
            const SizedBox(height: 8),
            _buildDialogFeature('Renewal', 'Lifetime Academic License'),
            const SizedBox(height: 8),
            _buildDialogFeature('Bandwidth', 'Unthrottled'),
          ],
        ),
        actions: [
          PrimaryButton(
            text: 'Close',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  static Widget _buildDialogFeature(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.mutedText,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile & Subscription',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.primaryText,
          ),
        ),
      ),
      body: CyberBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Avatar & Identity
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardBackground,
                    border: Border.all(
                      color: AppColors.primaryText,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 42,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Guest User',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.borderDivider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: user?.isGuest ?? true
                              ? AppColors.mutedText
                              : AppColors.connectedStatus,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user?.isGuest ?? true
                            ? 'GUEST ACCOUNT'
                            : 'VERIFIED ACCOUNT',
                        style: AppTextStyles.labelSm.copyWith(
                          color: user?.isGuest ?? true
                              ? AppColors.secondaryText
                              : AppColors.primaryText,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Subscription & Premium Tier Card ─────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderDivider,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.elevatedSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.borderDivider,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.security_rounded,
                                  size: 16,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'SUBSCRIPTION',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.primaryText,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14241B),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.connectedStatus.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.connectedStatus,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'ACTIVE',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.connectedStatus,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'CyberShield Academic Pro',
                        style: AppTextStyles.headlineSm.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Academic Mobile App Development • Lifetime Research License',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.borderDivider),
                      const SizedBox(height: 14),

                      // Benefits List
                      _buildBenefitItem(
                        'High-Speed Encrypted TUN Encapsulation',
                      ),
                      const SizedBox(height: 10),
                      _buildBenefitItem('Zero-Knowledge DNS & Traffic Routing'),
                      const SizedBox(height: 10),
                      _buildBenefitItem(
                        'Unlimited Bandwidth Across All Public Relays',
                      ),
                      const SizedBox(height: 10),
                      _buildBenefitItem(
                        'Real-Time Packet & Latency Diagnostic HUD',
                      ),

                      const SizedBox(height: 20),
                      PrimaryButton(
                        text: 'Manage Subscription',
                        onPressed: () => _showSubscriptionDetails(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Account Details Card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderDivider,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildRow('Email', user?.email ?? 'Not linked (Guest)'),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.borderDivider),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Display Name',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          if (!_isEditing)
                            Row(
                              children: [
                                Text(
                                  user?.name ?? '',
                                  style: AppTextStyles.labelLg.copyWith(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppColors.primaryText,
                                  ),
                                  onPressed: () =>
                                      setState(() => _isEditing = true),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: 140,
                              child: TextField(
                                controller: _nameController,
                                style: AppTextStyles.labelLg.copyWith(
                                  color: AppColors.primaryText,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'Save Changes',
                          isLoading: _isLoading,
                          onPressed: _saveName,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Out Action
                SecondaryButton(
                  text: 'Sign Out',
                  textColor: AppColors.primaryText,
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/welcome', (_) => false);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.connectedStatus,
          size: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.secondaryText,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.secondaryText),
        ),
        Text(
          value,
          style: AppTextStyles.labelLg.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
