import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'crm_colors.dart';

class CrmTheme {
  const CrmTheme._();

  static const double radiusSm = 8;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 18;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CrmColors.background,
      colorScheme: const ColorScheme.light(
        primary: CrmColors.brandPrimary,
        onPrimary: Colors.white,
        surface: CrmColors.card,
        onSurface: CrmColors.foreground,
        outline: CrmColors.border,
        error: CrmColors.error,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: CrmColors.foreground,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: CrmColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: CrmColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: CrmColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: CrmColors.brandPrimary,
            width: 1.4,
          ),
        ),
        hintStyle: const TextStyle(
          color: CrmColors.mutedForeground,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: CrmColors.mutedForeground,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CrmColors.brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: CrmColors.brandPrimary.withValues(
            alpha: 0.5,
          ),
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: CrmColors.foreground,
          side: const BorderSide(color: CrmColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          color: CrmColors.foreground,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleMedium: const TextStyle(
          color: CrmColors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(
          color: CrmColors.foreground,
          fontSize: 15,
          height: 1.45,
        ),
        bodyMedium: const TextStyle(
          color: CrmColors.mutedForeground,
          fontSize: 14,
          height: 1.4,
        ),
        labelSmall: const TextStyle(
          color: CrmColors.mutedForeground,
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
