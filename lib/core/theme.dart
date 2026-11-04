import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand.dart';
import 'i18n.dart';

/// Visual tokens: teal / canvas, 12px radius, 48dp targets, no drop shadow.
abstract final class AppTheme {
  static const double radius = 12;
  static const double hairline = 1;
  static const double touchTarget = 48;
  static const double chargeHeight = 56;
  static const double bodySize = 16;

  static const Color ink = Color(0xFF0F172A);
  static const Color hairlineColor = Color(0xFFD7E0DC);
  static const Color amber = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color onTeal = Color(0xFFFFFFFF);

  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(radius),
  );

  static Future<void> preloadFonts() async {
    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.inter(),
        GoogleFonts.notoSansDevanagari(),
      ]);
    } catch (_) {
      // Offline / tests: engine falls back to the platform font.
    }
  }

  static ThemeData light([AppLocale locale = AppLocale.en]) {
    final colorScheme = ColorScheme.light(
      primary: Brand.themeColor,
      onPrimary: onTeal,
      secondary: Brand.themeColor,
      onSecondary: onTeal,
      surface: Brand.themeBackground,
      onSurface: ink,
      error: error,
      onError: onTeal,
    );

    final textTheme = _textTheme(locale, colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Brand.themeBackground,
      canvasColor: Brand.themeBackground,
      textTheme: textTheme,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: Brand.themeBackground,
        foregroundColor: ink,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: Brand.themeBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: hairlineColor, width: hairline),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Brand.themeBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Brand.themeBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle()),
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle().copyWith(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: const WidgetStatePropertyAll(Brand.themeColor),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Brand.themeColor, width: hairline),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Brand.themeColor,
          minimumSize: const Size(touchTarget, touchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(touchTarget, touchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: hairlineColor,
        thickness: hairline,
        space: hairline,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Brand.themeBackground,
        indicatorColor: Brand.themeColor.withValues(alpha: 0.12),
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Brand.themeBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: hairlineColor, width: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: hairlineColor, width: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Brand.themeColor, width: hairline),
        ),
      ),
    );
  }

  /// POS Charge — at least 56dp, always the primary teal fill.
  static ButtonStyle get charge => _buttonStyle().copyWith(
    minimumSize: const WidgetStatePropertyAll(Size(touchTarget, chargeHeight)),
  );

  static TextStyle rupee(TextStyle base) {
    return base.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  static ButtonStyle _buttonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: Brand.themeColor,
      foregroundColor: onTeal,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: const Size(touchTarget, touchTarget),
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: const RoundedRectangleBorder(borderRadius: borderRadius),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: <String>['Noto Sans Devanagari'],
        fontSize: bodySize,
        letterSpacing: 0,
      ),
    );
  }

  static TextTheme _textTheme(AppLocale locale, ColorScheme colors) {
    final height = locale == AppLocale.hi ? 1.75 : 1.5;
    TextStyle style({
      required double size,
      FontWeight weight = FontWeight.w400,
    }) {
      return TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: const <String>['Noto Sans Devanagari'],
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: 0,
        color: colors.onSurface,
      );
    }

    return TextTheme(
      displaySmall: style(size: 28, weight: FontWeight.w600),
      headlineSmall: style(size: 22, weight: FontWeight.w600),
      titleLarge: style(size: 20, weight: FontWeight.w600),
      titleMedium: style(size: 16, weight: FontWeight.w600),
      titleSmall: style(size: 14, weight: FontWeight.w600),
      bodyLarge: style(size: bodySize),
      bodyMedium: style(size: bodySize),
      bodySmall: style(size: 14),
      labelLarge: style(size: bodySize, weight: FontWeight.w600),
      labelMedium: style(size: 14, weight: FontWeight.w500),
      labelSmall: style(size: 12, weight: FontWeight.w500),
    );
  }
}
