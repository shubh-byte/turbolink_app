import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_engine/base_theme.dart';
import '../theme_engine/turbo_colors.dart';

class OceanTheme {
  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF02101D) : const Color(0xFFF0F8FF);
    final surfaceAlt = isDark ? const Color(0xFF061A2E) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF0F3255) : const Color(0xFFB8D8F0);
    final textPrimary = isDark ? const Color(0xFFE6F3FF) : const Color(0xFF002244);
    final textSecondary = isDark ? const Color(0xFF7B9EBF) : const Color(0xFF4A7094);
    
    final primary = isDark ? const Color(0xFF00A2FF) : const Color(0xFF0066CC);
    final secondary = isDark ? const Color(0xFF4EE6B1) : const Color(0xFF009966);

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

    return BaseTheme.build(
      brightness, 
      surface, 
      surfaceAlt, 
      border, 
      textPrimary, 
      textSecondary, 
      primary, 
      secondary, 
      turboColors, 
      GoogleFonts.outfit(), 
      GoogleFonts.dmSans()
    );
  }
}
