import 'package:flutter/material.dart';
import 'turbo_colors.dart';

/// The core theme builder engine. 
/// Specific aesthetics (Industrial, Cyberpunk, etc.) use this to generate
/// the final ThemeData for the application.
class BaseTheme {
  BaseTheme._();

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  /// Returns the helper colors for gradients, etc.
  static TurboColors colors(BuildContext context) {
    return Theme.of(context).extension<TurboColors>()!;
  }

  static ThemeData build(
    Brightness brightness, 
    Color surface, 
    Color surfaceAlt, 
    Color border, 
    Color textPrimary, 
    Color textSecondary,
    Color primary,
    Color secondary,
    TurboColors turboColors,
    TextStyle displayFont,
    TextStyle bodyFont,
  ) {
    final textTheme = _buildTextTheme(textPrimary, textSecondary, primary, displayFont, bodyFont);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: surface,
      extensions: [turboColors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
        secondary: secondary,
        onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
        error: turboColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surfaceAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border, width: 0.8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: displayFont.copyWith(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceAlt,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceAlt,
        indicatorColor: turboColors.primaryGlowDim,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return bodyFont.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            );
          }
          return bodyFont.copyWith(
            color: textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          );
        }),
      ),
      iconTheme: IconThemeData(color: textPrimary, size: 22),
      dividerColor: border,
    );
  }

  static TextTheme _buildTextTheme(
    Color primary, 
    Color secondary, 
    Color accent,
    TextStyle displayFont,
    TextStyle bodyFont,
  ) {
    return TextTheme(
      displayLarge: displayFont.copyWith(fontSize: 36, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
      displayMedium: displayFont.copyWith(fontSize: 28, fontWeight: FontWeight.w600, color: primary),
      headlineLarge: displayFont.copyWith(fontSize: 22, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.5),
      headlineMedium: displayFont.copyWith(fontSize: 18, fontWeight: FontWeight.w500, color: primary, letterSpacing: 0.3),
      titleLarge: displayFont.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: primary, letterSpacing: 0.5),
      titleMedium: bodyFont.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: primary, letterSpacing: 0.3),
      titleSmall: bodyFont.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.5),
      bodyLarge: bodyFont.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: bodyFont.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: secondary),
      bodySmall: bodyFont.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: secondary.withValues(alpha: 0.7)),
      labelLarge: bodyFont.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: accent, letterSpacing: 1.5),
      labelMedium: bodyFont.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 1.0),
      labelSmall: bodyFont.copyWith(fontSize: 10, fontWeight: FontWeight.w400, color: secondary.withValues(alpha: 0.7), letterSpacing: 1.2),
    );
  }
}
