import 'package:flutter/material.dart';

/// Premium Obsidian, Charcoal Grey, and Pure White Visual Identity.
///
/// Designed as a high-end cybersecurity product: minimal, sophisticated,
/// trustworthy, smooth, and modern.
///
/// Palette Specification:
/// - Primary Background:   #090909 — deep obsidian black
/// - Secondary Background: #121212 — rich black
/// - Card Background:      #1A1A1A — premium charcoal
/// - Elevated Surface:     #242424 — slightly lighter charcoal
/// - Primary Text:         #FFFFFF — pure white
/// - Secondary Text:       #B3B3B3 — soft silver grey
/// - Muted Text:           #777777 — subtle grey
/// - Borders and Dividers: #2D2D2D
/// - Primary Accent:       #F5F5F5 — clean white
/// - Connected Status:     #35C98A — subtle green, used ONLY for successful VPN connections
/// - Error Status:         #FF5C5C — restrained red, used ONLY for errors
class AppColors {
  AppColors._();

  // ── Core Palette Tokens ─────────────────────────────────────────────────────
  static const Color primaryBackground   = Color(0xFF090909); // deep obsidian black
  static const Color secondaryBackground = Color(0xFF121212); // rich black
  static const Color cardBackground      = Color(0xFF1A1A1A); // premium charcoal
  static const Color elevatedSurface     = Color(0xFF242424); // slightly lighter charcoal
  static const Color primaryText         = Color(0xFFFFFFFF); // pure white
  static const Color secondaryText       = Color(0xFFB3B3B3); // soft silver grey
  static const Color mutedText           = Color(0xFF777777); // subtle grey
  static const Color borderDivider       = Color(0xFF2D2D2D); // borders and dividers
  static const Color border              = borderDivider;     // #2D2D2D
  static const Color primaryAccent       = Color(0xFFF5F5F5); // clean white
  static const Color connectedStatus     = Color(0xFF35C98A); // subtle green (successful VPN)
  static const Color errorStatus         = Color(0xFFFF5C5C); // restrained red (errors)


  // ── Fundamental Aliases ────────────────────────────────────────────────────
  static const Color pureBlack        = primaryBackground;   // #090909
  static const Color richCharcoal     = secondaryBackground; // #121212
  static const Color charcoalCard     = cardBackground;      // #1A1A1A
  static const Color charcoalElevated = elevatedSurface;     // #242424
  static const Color charcoalHover    = Color(0xFF2E2E2E);

  static const Color darkGrayBorder   = borderDivider;       // #2D2D2D
  static const Color darkGraySubtle   = Color(0xFF383838);
  static const Color darkGrayMuted    = mutedText;           // #777777

  static const Color pureWhite        = primaryText;         // #FFFFFF
  static const Color silverBright     = primaryAccent;       // #F5F5F5
  static const Color silverText       = secondaryText;       // #B3B3B3
  static const Color slateMuted       = mutedText;           // #777777
  static const Color slateDisabled    = Color(0xFF4A4A4A);

  // ── Accent & State Colors (Monochrome White & Restrained Status) ───────────
  static const Color accent           = primaryAccent;       // #F5F5F5
  static const Color accentLight      = pureWhite;           // #FFFFFF
  static const Color accentDark       = secondaryText;       // #B3B3B3
  static const Color accentGlow       = Color(0x33FFFFFF);   // 20% white glow
  static const Color accentGlowDim    = Color(0x1AFFFFFF);   // 10% white halo
  static const Color accentHalo       = Color(0x0FFFFFFF);   // 6% white ambient
  static const Color accentBorder     = borderDivider;       // #2D2D2D

  // ── Legacy Compatibility Mappings ──────────────────────────────────────────
  static const Color inkNavy          = cardBackground;
  static const Color mistBase         = primaryBackground;
  static const Color signalLime       = connectedStatus;     // subtle green

  static const Color navy100          = primaryText;         // #FFFFFF
  static const Color navy70           = secondaryText;       // #B3B3B3
  static const Color navy45           = mutedText;           // #777777
  static const Color navy12           = borderDivider;       // #2D2D2D
  static const Color navy06           = Color(0x0FFFFFFF);   // 6% white fill

  static const Color textPrimary      = primaryText;
  static const Color textSecondary    = secondaryText;
  static const Color textMuted        = mutedText;
  static const Color textDisabled     = slateDisabled;

  static const Color error            = errorStatus;         // #FF5C5C
  static const Color errorContainer   = Color(0x24FF5C5C);
  static const Color onError          = pureWhite;
  static const Color success          = connectedStatus;     // #35C98A
  static const Color warning          = Color(0xFFE5A93C);   // restrained amber for warning

  static const Color surfaceCanvas        = primaryBackground;
  static const Color surfaceElevated      = elevatedSurface;
  static const Color surfaceElevatedLight = elevatedSurface;
  static const Color surfaceBorder        = borderDivider;
  static const Color scrim                = Color(0xCC000000);

  // ── Cyber / State Aliases Unified to Obsidian & Pure White ─────────────────
  static const Color deepNavy         = primaryBackground;
  static const Color darkNavyMid      = secondaryBackground;
  static const Color darkNavyCard     = cardBackground;
  static const Color darkNavyElevated = elevatedSurface;
  static const Color navyPurple       = charcoalHover;

  static const Color glowCyan         = pureWhite;
  static const Color glowCyanDim      = Color(0x22FFFFFF);
  static const Color cyanAccent       = pureWhite;
  static const Color cyanNeon         = pureWhite;
  static const Color purpleNeon       = secondaryText;
  static const Color cyanAccentDim    = Color(0x1FFFFFFF);
  static const Color cyanAccentGlow   = Color(0x0FFFFFFF);

  static const Color emeraldGlow      = connectedStatus;     // #35C98A
  static const Color emeraldGlowDim   = Color(0x2635C98A);
  static const Color amberGlow        = Color(0xFFD49B35);
  static const Color amberGlowDim     = Color(0x26D49B35);
  static const Color errorGlow        = errorStatus;         // #FF5C5C
  static const Color errorGlowDim     = Color(0x26FF5C5C);
  static const Color disconnectRing   = borderDivider;
  static const Color particleTrail    = Color(0x33FFFFFF);
  static const Color connectedBg      = secondaryBackground;

  // ── Dark Glass Tokens ──────────────────────────────────────────────────────
  static const Color glassSurface      = Color(0x0DFFFFFF); // 5% white frosted
  static const Color glassSurfaceHover = Color(0x1AFFFFFF); // 10% white hover
  static const Color glassBorder       = borderDivider;
  static const Color glassBorderGlow   = Color(0x26FFFFFF);

  // ── Subtle Sophisticated Monochrome Gradients ──────────────────────────────
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1E1E),
      Color(0xFF161616),
    ],
  );

  static const LinearGradient elevatedCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF282828),
      Color(0xFF202020),
    ],
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1F2D2D2D),
      Color(0x0A242424),
    ],
  );

  static const LinearGradient cyanBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x80FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x40FFFFFF),
    ],
  );

  static const LinearGradient emeraldBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x8035C98A),
      Color(0x2635C98A),
      Color(0x4035C98A),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF121212),
      Color(0xFF090909),
    ],
  );

  static const LinearGradient connectedBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F1411),
      Color(0xFF090909),
    ],
  );
}
