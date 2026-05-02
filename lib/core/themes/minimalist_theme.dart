import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_engine/base_theme.dart';
import '../theme_engine/turbo_colors.dart';

class MinimalistTheme {
  static ThemeData build(Brightness brightness) {
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
      success: primary,
      error: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
      errorDim: isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE),
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
      GoogleFonts.inter(), 
      GoogleFonts.inter()
    );
  }
}
