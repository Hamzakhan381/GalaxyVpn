import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'motion.dart';

/// Country badge that displays a Unicode emoji flag with ISO-2 fallback code.
/// Styled in premium charcoal with subtle border.
class CountryBadge extends StatelessWidget {
  final String countryCode;
  final double size;
  final bool darkMode;

  const CountryBadge({
    super.key,
    required this.countryCode,
    this.size = 40,
    this.darkMode = false,
  });

  static String? emojiFlag(String code) {
    if (code.length != 2) return null;
    final upper = code.toUpperCase();
    final a = upper.codeUnitAt(0);
    final b = upper.codeUnitAt(1);
    if (a < 65 || a > 90 || b < 65 || b > 90) return null;
    return String.fromCharCodes([0x1F1E6 + (a - 65), 0x1F1E6 + (b - 65)]);
  }

  @override
  Widget build(BuildContext context) {
    final code = countryCode.length >= 2
        ? countryCode.substring(0, 2).toUpperCase()
        : 'UN';
    final flag = emojiFlag(code);

    return Tooltip(
      message: code,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: AppColors.borderDivider, width: 1.0),
          boxShadow: Motion.shadows(context, [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]),
        ),
        child: flag != null
            ? Text(
                flag,
                style: TextStyle(fontSize: size * 0.52),
                textAlign: TextAlign.center,
              )
            : Text(
                code,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
