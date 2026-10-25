import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography definitions corresponding exactly to the Stitch 'Quiet Bastion' design system.
///
/// Uses the platform's system font (Roboto on Android). The styles are
/// constants: loading Inter through google_fonts at runtime failed on every
/// device (no bundled files, network fetching off) and retried on every build,
/// which kept the UI thread busy enough to make the app unresponsive.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.navy100,
  );

  static const TextStyle headlineLg = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 32 / 26,
    letterSpacing: -0.39,
    color: AppColors.navy100,
  );

  static const TextStyle headlineMd = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    letterSpacing: -0.22,
    color: AppColors.navy100,
  );

  static const TextStyle headlineSm = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 24 / 18,
    letterSpacing: -0.09,
    color: AppColors.navy100,
  );

  static const TextStyle metricLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 32 / 28,
    letterSpacing: -0.56,
    color: AppColors.navy100,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0.0,
    color: AppColors.navy70,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.14,
    color: AppColors.navy70,
  );

  static const TextStyle labelLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.14,
    color: AppColors.navy100,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.24,
    color: AppColors.navy70,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.44,
    color: AppColors.navy45,
  );
}
