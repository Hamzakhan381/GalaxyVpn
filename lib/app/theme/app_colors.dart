import 'package:flutter/material.dart';

/// Design tokens from the Stitch 'Quiet Bastion' design system.
///
/// Palette operates under strict volumetric discipline:
/// - Ink Navy (55–65%): Structural core, typography, primary buttons
/// - Mist Canvas (30–40%): Atmospheric backdrop, calm baseline
/// - Signal Lime (<= 5%): Rare accent strictly for state verification
class AppColors {
  AppColors._();

  // Core Anchors
  static const Color inkNavy = Color(0xFF172B4D);
  static const Color mistBase = Color(0xFFF6F8FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color signalLime = Color(0xFFC7F000);

  // Ink Navy Opacity Tiers
  static const Color navy100 = Color(0xFF172B4D);
  static const Color navy70 = Color(0xB3172B4D); // rgba(23, 43, 77, 0.70)
  static const Color navy45 = Color(0x73172B4D); // rgba(23, 43, 77, 0.45)
  static const Color navy12 = Color(0x1F172B4D); // rgba(23, 43, 77, 0.12)
  static const Color navy06 = Color(0x0F172B4D); // rgba(23, 43, 77, 0.06)

  // Feedback & Alert
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF1B5E20);

  // Surface Tiers
  static const Color surfaceCanvas = mistBase;
  static const Color surfaceElevated = pureWhite;
  static const Color surfaceBorder = navy12;
  static const Color scrim = Color(0x66172B4D); // rgba(23, 43, 77, 0.40)

  // Dark Splash / Premium Theme
  static const Color deepNavy = Color(0xFF0A0E1A);
  static const Color darkNavyMid = Color(0xFF0D1526);
  static const Color navyPurple = Color(0xFF1A1040);
  static const Color glowCyan = Color(0xFF00D4FF);
  static const Color glowCyanDim = Color(0x3300D4FF); // 20% opacity cyan
}
