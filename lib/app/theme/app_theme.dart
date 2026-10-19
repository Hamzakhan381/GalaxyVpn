import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/common/motion.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Premium Material 3 Theme for Obsidian Black, Charcoal Grey, and Pure White.
/// High-end cybersecurity visual identity: minimal, sophisticated, trustworthy.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryBackground, // #090909
      primaryColor: AppColors.primaryAccent,                // #F5F5F5
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GalaxyPageTransitionsBuilder(),
          TargetPlatform.iOS: GalaxyPageTransitionsBuilder(),
          TargetPlatform.fuchsia: GalaxyPageTransitionsBuilder(),
          TargetPlatform.linux: GalaxyPageTransitionsBuilder(),
          TargetPlatform.macOS: GalaxyPageTransitionsBuilder(),
          TargetPlatform.windows: GalaxyPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryAccent,                   // #F5F5F5
        onPrimary: AppColors.primaryBackground,             // #090909
        secondary: AppColors.elevatedSurface,               // #242424
        onSecondary: AppColors.primaryText,                 // #FFFFFF
        error: AppColors.errorStatus,                       // #FF5C5C
        onError: AppColors.pureWhite,
        surface: AppColors.cardBackground,                  // #1A1A1A
        onSurface: AppColors.primaryText,                   // #FFFFFF
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        titleTextStyle: AppTextStyles.headlineSm.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.primaryBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground, // #1A1A1A
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderDivider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent, // Pure white
          foregroundColor: AppColors.primaryBackground, // Dark obsidian text
          disabledBackgroundColor: AppColors.cardBackground,
          disabledForegroundColor: AppColors.mutedText,
          minimumSize: const Size(64, 52),
          elevation: 0,
          textStyle: AppTextStyles.labelLg.copyWith(
            color: AppColors.primaryBackground,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          backgroundColor: AppColors.cardBackground,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: AppColors.borderDivider, width: 1.2),
          textStyle: AppTextStyles.labelLg.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          textStyle: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground, // #1A1A1A
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
        labelStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.secondaryText),
        prefixIconColor: AppColors.secondaryText,
        suffixIconColor: AppColors.secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderDivider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorStatus, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorStatus, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground, // #121212
        selectedItemColor: AppColors.primaryText,        // #FFFFFF
        unselectedItemColor: AppColors.mutedText,       // #777777
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevatedSurface,     // #242424
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDivider, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.elevatedSurface,     // #242424
        modalBackgroundColor: AppColors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDivider,                 // #2D2D2D
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBackground;
          }
          return AppColors.secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.connectedStatus; // subtle green when enabled
          }
          return AppColors.cardBackground;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.borderDivider),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(AppColors.primaryBackground),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.borderDivider, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
