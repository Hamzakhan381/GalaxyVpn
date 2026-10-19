import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Full-fidelity VPN Permission Disclosure Component styled with charcoal card and pure white accents.
class PermissionDisclosureCard extends StatelessWidget {
  final bool isConsentChecked;
  final ValueChanged<bool?> onConsentChanged;

  const PermissionDisclosureCard({
    super.key,
    required this.isConsentChecked,
    required this.onConsentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDivider, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDivider, width: 1),
                ),
                child: const Icon(
                  Icons.vpn_lock_outlined,
                  color: AppColors.primaryText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.vpnDisclosureTitle,
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Android VpnService Integration',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.borderDivider),
          const SizedBox(height: 16),
          // Core disclosure text (Mandatory)
          Text(
            AppConstants.vpnDisclosureCore,
            style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildBullet(
            title: 'Why VPN access is needed',
            description: AppConstants.vpnDisclosurePurpose,
          ),
          const SizedBox(height: 14),
          _buildBullet(
            title: 'What traffic is routed',
            description: AppConstants.vpnDisclosureScope,
          ),
          const SizedBox(height: 14),
          _buildBullet(
            title: 'What we DO NOT inspect',
            description: AppConstants.vpnDisclosurePrivacy,
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.borderDivider),
          const SizedBox(height: 14),
          // Unchecked Consent Checkbox (Strict requirement: Never preselected)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onConsentChanged(!isConsentChecked),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isConsentChecked,
                      onChanged: onConsentChanged,
                      activeColor: AppColors.primaryAccent,
                      checkColor: AppColors.primaryBackground,
                      side: const BorderSide(
                        color: AppColors.borderDivider,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppConstants.vpnConsentCheckbox,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet({required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.primaryText,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Text(
            description,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
