import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_engine/base_theme.dart';
import '../theme_engine/turbo_colors.dart';

class CyberpunkTheme {
  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF050511) : const Color(0xFFFAFAFA);
    final surfaceAlt = isDark ? const Color(0xFF0A0A1F) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF2E004F) : const Color(0xFFE0E0E0);
    final textPrimary = isDark ? const Color(0xFFFF003C) : const Color(0xFF111111);
    final textSecondary = isDark ? const Color(0xFFB188CE) : const Color(0xFF555555);
    
    final primary = isDark ? const Color(0xFF00FFCC) : const Color(0xFFFF0055);
    final secondary = isDark ? const Color(0xFFFCEE09) : const Color(0xFF7000FF);

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
      GoogleFonts.rajdhani(), 
      GoogleFonts.shareTechMono()
    );
  }
}
