import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TurboLink design system.
///
/// Aesthetic direction: Dark industrial-tech. The vibe is a military-grade
/// file transfer tool — deep charcoal surfaces, electric cyan for active
/// connections, warm amber for transfer activity, and crisp typography
/// that feels like reading a cockpit HUD.
class AppTheme {
  AppTheme._();

  // ── Core palette ─────────────────────────────────────────────────────
  static const Color surface = Color(0xFF0D0D0F);        // Near-black base
  static const Color surfaceAlt = Color(0xFF161619);      // Card surfaces
  static const Color surfaceElevated = Color(0xFF1E1E23); // Elevated panels
  static const Color border = Color(0xFF2A2A32);          // Subtle borders
  static const Color textPrimary = Color(0xFFF0EDE6);     // Warm off-white
  static const Color textSecondary = Color(0xFF8A8690);   // Muted lavender-grey
  static const Color textTertiary = Color(0xFF5A5660);    // Very muted

  // ── Accent colors ────────────────────────────────────────────────────
  static const Color cyan = Color(0xFF00E5CC);            // Active/connected
  static const Color cyanDim = Color(0xFF0A3D37);         // Cyan background glow
  static const Color amber = Color(0xFFFFAA2B);           // Transfer/activity
  static const Color amberDim = Color(0xFF3D2E0A);        // Amber background glow
  static const Color red = Color(0xFFFF4D6A);             // Error/failed
  static const Color redDim = Color(0xFF3D0A1A);          // Error background
  static const Color green = Color(0xFF2EE67A);           // Success/completed

  // ── Radar-specific colors ────────────────────────────────────────────
  static const Color radarRing = Color(0xFF1A3A38);       // Dim ring stroke
  static const Color radarSweep = Color(0xFF00E5CC);      // Sweep line
  static const Color radarDot = Color(0xFF00E5CC);        // Peer dot

  // ── Gradients ────────────────────────────────────────────────────────
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00E5CC), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFFAA2B), Color(0xFFFF6B2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF0D0D0F), Color(0xFF141418)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Spacing ──────────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ── Border radius ────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ── Theme data ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: cyan,
        secondary: amber,
        error: red,
        onSurface: textPrimary,
        onPrimary: surface,
        onSecondary: surface,
      ),
      textTheme: _buildTextTheme(),
      cardTheme: CardThemeData(
        color: surfaceAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.unbounded(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceAlt,
        selectedItemColor: cyan,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceAlt,
        indicatorColor: cyanDim,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.sourceCodePro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cyan,
              letterSpacing: 1.2,
            );
          }
          return GoogleFonts.sourceCodePro(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: textTertiary,
            letterSpacing: 1.0,
          );
        }),
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 22),
      dividerColor: border,
    );
  }

  static TextTheme _buildTextTheme() {
    // Unbounded for display/headline — bold, technical, memorable.
    // Source Code Pro for body/data — monospaced readability.
    return TextTheme(
      displayLarge: GoogleFonts.unbounded(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.unbounded(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
      ),
      headlineLarge: GoogleFonts.unbounded(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      headlineMedium: GoogleFonts.unbounded(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.3,
      ),
      titleLarge: GoogleFonts.unbounded(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      titleMedium: GoogleFonts.sourceCodePro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.3,
      ),
      titleSmall: GoogleFonts.sourceCodePro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
      bodyLarge: GoogleFonts.sourceCodePro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.sourceCodePro(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.sourceCodePro(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      ),
      labelLarge: GoogleFonts.sourceCodePro(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: cyan,
        letterSpacing: 1.5,
      ),
      labelMedium: GoogleFonts.sourceCodePro(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 1.0,
      ),
      labelSmall: GoogleFonts.sourceCodePro(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }
}
