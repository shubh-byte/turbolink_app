import 'package:flutter/material.dart';

/// Extension to hold semantic custom colors for the UI, decoupled from fixed constants.
class TurboColors extends ThemeExtension<TurboColors> {
  final Color primaryGlow;
  final Color primaryGlowDim;
  final Color secondaryGlow;
  final Color secondaryGlowDim;
  final Color radarRing;
  final Color radarSweep;
  final Color success;
  final Color error;
  final Color errorDim;

  const TurboColors({
    required this.primaryGlow,
    required this.primaryGlowDim,
    required this.secondaryGlow,
    required this.secondaryGlowDim,
    required this.radarRing,
    required this.radarSweep,
    required this.success,
    required this.error,
    required this.errorDim,
  });

  @override
  ThemeExtension<TurboColors> copyWith({
    Color? primaryGlow,
    Color? primaryGlowDim,
    Color? secondaryGlow,
    Color? secondaryGlowDim,
    Color? radarRing,
    Color? radarSweep,
    Color? success,
    Color? error,
    Color? errorDim,
  }) {
    return TurboColors(
      primaryGlow: primaryGlow ?? this.primaryGlow,
      primaryGlowDim: primaryGlowDim ?? this.primaryGlowDim,
      secondaryGlow: secondaryGlow ?? this.secondaryGlow,
      secondaryGlowDim: secondaryGlowDim ?? this.secondaryGlowDim,
      radarRing: radarRing ?? this.radarRing,
      radarSweep: radarSweep ?? this.radarSweep,
      success: success ?? this.success,
      error: error ?? this.error,
      errorDim: errorDim ?? this.errorDim,
    );
  }

  @override
  ThemeExtension<TurboColors> lerp(
    covariant ThemeExtension<TurboColors>? other,
    double t,
  ) {
    if (other is! TurboColors) {
      return this;
    }
    return TurboColors(
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      primaryGlowDim: Color.lerp(primaryGlowDim, other.primaryGlowDim, t)!,
      secondaryGlow: Color.lerp(secondaryGlow, other.secondaryGlow, t)!,
      secondaryGlowDim: Color.lerp(secondaryGlowDim, other.secondaryGlowDim, t)!,
      radarRing: Color.lerp(radarRing, other.radarRing, t)!,
      radarSweep: Color.lerp(radarSweep, other.radarSweep, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorDim: Color.lerp(errorDim, other.errorDim, t)!,
    );
  }
}
