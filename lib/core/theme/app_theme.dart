import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/ui_theme_provider.dart';
import 'turbo_colors.dart';

/// TurboLink multi-aesthetic design system.
class AppTheme {
  AppTheme._();

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

  static ThemeData getTheme(UIAesthetic aesthetic, Brightness brightness) {
    switch (aesthetic) {
      case UIAesthetic.industrial:
        return _buildIndustrialTheme(brightness);
      case UIAesthetic.cyberpunk:
        return _buildCyberpunkTheme(brightness);
      case UIAesthetic.ocean:
        return _buildOceanTheme(brightness);
      case UIAesthetic.minimalist:
        return _buildMinimalistTheme(brightness);
    }
  }

  // ── Industrial Tech (The original, but refined) ──────────────────────────
  static ThemeData _buildIndustrialTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0D0D0F) : const Color(0xFFF2F4F7);
    final surfaceAlt = isDark ? const Color(0xFF161619) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF2A2A32) : const Color(0xFFD1D1D6);
    final textPrimary = isDark ? const Color(0xFFF0EDE6) : const Color(0xFF090A0B);
    final textSecondary = isDark ? const Color(0xFF8A8690) : const Color(0xFF6B7280);
    
    final primary = isDark ? const Color(0xFF00E5CC) : const Color(0xFF1A4BFF); // Cyan / Ultramarine
    final secondary = isDark ? const Color(0xFFFFAA2B) : const Color(0xFFFF5500); // Amber / Orange

    final turboColors = TurboColors(
      primaryGlow: primary,
      primaryGlowDim: isDark ? const Color(0xFF0A3D37) : primary.withValues(alpha: 0.15),
      secondaryGlow: secondary,
      secondaryGlowDim: isDark ? const Color(0xFF3D2E0A) : secondary.withValues(alpha: 0.15),
      radarRing: isDark ? const Color(0xFF1A3A38) : const Color(0xFFE5E7EB),
      radarSweep: primary,
      success: const Color(0xFF2EE67A),
      error: const Color(0xFFFF4D6A),
      errorDim: isDark ? const Color(0xFF3D0A1A) : const Color(0xFFFF4D6A).withValues(alpha: 0.1),
    );

    return _buildBaseTheme(brightness, surface, surfaceAlt, border, textPrimary, textSecondary, primary, secondary, turboColors, GoogleFonts.unbounded(), GoogleFonts.sourceCodePro());
  }

  // ── Cyberpunk (Neon maximalism) ──────────────────────────────────────────
  static ThemeData _buildCyberpunkTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF050511) : const Color(0xFFFAFAFA);
    final surfaceAlt = isDark ? const Color(0xFF0A0A1F) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF2E004F) : const Color(0xFFE0E0E0);
    final textPrimary = isDark ? const Color(0xFFFF003C) : const Color(0xFF111111); // Neon Red / Pitch Black
    final textSecondary = isDark ? const Color(0xFFB188CE) : const Color(0xFF555555);
    
    final primary = isDark ? const Color(0xFF00FFCC) : const Color(0xFFFF0055); // Neon Teal / Hot Pink
    final secondary = isDark ? const Color(0xFFFCEE09) : const Color(0xFF7000FF); // Cyber Yellow / Electric Purple

    final turboColors = TurboColors(
      primaryGlow: primary,
      primaryGlowDim: primary.withValues(alpha: 0.2),
      secondaryGlow: secondary,
      secondaryGlowDim: secondary.withValues(alpha: 0.2),
      radarRing: isDark ? const Color(0xFF1A0A2E) : const Color(0xFFEEEEEE),
      radarSweep: primary,
      success: const Color(0xFF00FF41),
      error: const Color(0xFFFF003C),
      errorDim: const Color(0xFFFF003C).withValues(alpha: 0.2),
    );

    return _buildBaseTheme(brightness, surface, surfaceAlt, border, textPrimary, textSecondary, primary, secondary, turboColors, GoogleFonts.rajdhani(), GoogleFonts.shareTechMono());
  }

  // ── Ocean Depths (Professional & Calming) ────────────────────────────────
  static ThemeData _buildOceanTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF02101D) : const Color(0xFFF0F8FF);
    final surfaceAlt = isDark ? const Color(0xFF061A2E) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF0F3255) : const Color(0xFFB8D8F0);
    final textPrimary = isDark ? const Color(0xFFE6F3FF) : const Color(0xFF002244);
    final textSecondary = isDark ? const Color(0xFF7B9EBF) : const Color(0xFF4A7094);
    
    final primary = isDark ? const Color(0xFF00A2FF) : const Color(0xFF0066CC); // Cerulean
    final secondary = isDark ? const Color(0xFF4EE6B1) : const Color(0xFF009966); // Seafoam

    final turboColors = TurboColors(
      primaryGlow: primary,
      primaryGlowDim: primary.withValues(alpha: 0.2),
      secondaryGlow: secondary,
      secondaryGlowDim: secondary.withValues(alpha: 0.2),
      radarRing: isDark ? const Color(0xFF062340) : const Color(0xFFD6EAF8),
      radarSweep: primary,
      success: const Color(0xFF00CC99),
      error: const Color(0xFFFF6B6B),
      errorDim: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
    );

    return _buildBaseTheme(brightness, surface, surfaceAlt, border, textPrimary, textSecondary, primary, secondary, turboColors, GoogleFonts.outfit(), GoogleFonts.dmSans());
  }

  // ── Minimalist (Clean grayscale) ──────────────────────────────────────────
  static ThemeData _buildMinimalistTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final surfaceAlt = isDark ? const Color(0xFF111111) : const Color(0xFFF9F9F9);
    final border = isDark ? const Color(0xFF222222) : const Color(0xFFEAEAEA);
    final textPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final textSecondary = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    
    final primary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000); 
    final secondary = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF555555);

    final turboColors = TurboColors(
      primaryGlow: primary,
      primaryGlowDim: primary.withValues(alpha: 0.1),
      secondaryGlow: secondary,
      secondaryGlowDim: secondary.withValues(alpha: 0.1),
      radarRing: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
      radarSweep: primary,
      success: isDark ? const Color(0xFFDDDDDD) : const Color(0xFF333333),
      error: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
      errorDim: isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE),
    );

    return _buildBaseTheme(brightness, surface, surfaceAlt, border, textPrimary, textSecondary, primary, secondary, turboColors, GoogleFonts.inter(), GoogleFonts.inter());
  }

  // ── Base Theme Constructor ───────────────────────────────────────────────
  static ThemeData _buildBaseTheme(
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
