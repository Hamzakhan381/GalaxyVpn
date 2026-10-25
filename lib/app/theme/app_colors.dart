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


  // ── Galaxy Brand Mark (logo & launcher icon only) ──────────────────────────
  static const Color galaxyNebula     = Color(0xFF5B45B0); // violet nebula core
  static const Color galaxyNebulaDeep = Color(0xFF1C1733); // deep-space edge
  static const Color galaxyStarGlow   = Color(0xFFC9BCFF); // lavender starlight


  // ── Aliases ────────────────────────────────────────────────────────────────
  static const Color pureWhite        = primaryText;         // #FFFFFF
  static const Color navy100          = primaryText;         // #FFFFFF
  static const Color navy70           = secondaryText;       // #B3B3B3
  static const Color navy45           = mutedText;           // #777777
  static const Color errorContainer   = Color(0x24FF5C5C);
  static const Color surfaceElevated  = elevatedSurface;
}
