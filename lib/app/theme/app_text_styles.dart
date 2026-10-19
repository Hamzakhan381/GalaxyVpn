import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions corresponding exactly to the Stitch 'Quiet Bastion' design system.
/// Utilizes Inter font across all tiers with strict weight and tracking pairings.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.64,
        color: AppColors.navy100,
      );

  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 32 / 26,
        letterSpacing: -0.39,
        color: AppColors.navy100,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 28 / 22,
        letterSpacing: -0.22,
        color: AppColors.navy100,
      );

  static TextStyle get headlineSm => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 24 / 18,
        letterSpacing: -0.09,
        color: AppColors.navy100,
      );

  static TextStyle get metricLg => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 32 / 28,
        letterSpacing: -0.56,
        color: AppColors.navy100,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        letterSpacing: 0.0,
        color: AppColors.navy70,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        letterSpacing: 0.14,
        color: AppColors.navy70,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.14,
        color: AppColors.navy100,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.24,
        color: AppColors.navy70,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
        letterSpacing: 0.44,
        color: AppColors.navy45,
      );
}
