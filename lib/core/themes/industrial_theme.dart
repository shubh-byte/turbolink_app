import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_engine/base_theme.dart';
import '../theme_engine/turbo_colors.dart';

class IndustrialTheme {
  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0D0D0F) : const Color(0xFFF2F4F7);
    final surfaceAlt = isDark ? const Color(0xFF161619) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF2A2A32) : const Color(0xFFD1D1D6);
    final textPrimary = isDark ? const Color(0xFFF0EDE6) : const Color(0xFF090A0B);
    final textSecondary = isDark ? const Color(0xFF8A8690) : const Color(0xFF6B7280);
    
    final primary = isDark ? const Color(0xFF00E5CC) : const Color(0xFF1A4BFF);
    final secondary = isDark ? const Color(0xFFFFAA2B) : const Color(0xFFFF5500);

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
      GoogleFonts.unbounded(), 
      GoogleFonts.sourceCodePro()
    );
  }
}
