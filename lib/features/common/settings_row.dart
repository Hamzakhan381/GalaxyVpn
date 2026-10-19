import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showDivider;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.errorContainer
                    : AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDestructive
                      ? AppColors.errorStatus.withValues(alpha: 0.3)
                      : AppColors.borderDivider,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDestructive
                    ? AppColors.errorStatus
                    : AppColors.primaryText,
              ),
            ),
            title: Text(
              title,
              style: AppTextStyles.labelLg.copyWith(
                color: isDestructive
                    ? AppColors.errorStatus
                    : AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing:
                trailing ??
                (onTap != null
                    ? const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.mutedText,
                        size: 20,
                      )
                    : null),
            onTap: onTap,
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.borderDivider),
          ),
      ],
    );
  }
}
