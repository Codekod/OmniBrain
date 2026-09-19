import 'package:flutter/material.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/constants/app_sizes.dart';

/// Configuration object for glassmorphism effects.
///
/// Provides sensible defaults that match the OmniBrain design language;
/// override individual fields when you need a variant.
class GlassmorphismConfig {
  const GlassmorphismConfig({
    this.blur = 20,
    this.opacity = 0.15,
    this.borderRadius = AppSizes.radiusLg,
    this.borderColor,
    this.gradient,
  });

  /// Backdrop blur sigma (applied to both X and Y).
  final double blur;

  /// White-fill opacity for the frosted surface.
  final double opacity;

  /// Corner radius of the glass surface.
  final double borderRadius;

  /// Border colour. Defaults to [AppColors.cardBorder].
  final Color? borderColor;

  /// Optional gradient overlay on the glass surface.
  final Gradient? gradient;

  /// Resolved border colour – falls back to [AppColors.cardBorder].
  Color get resolvedBorderColor => borderColor ?? AppColors.cardBorder;

  /// Returns a copy with selected fields replaced.
  GlassmorphismConfig copyWith({
    double? blur,
    double? opacity,
    double? borderRadius,
    Color? borderColor,
    Gradient? gradient,
  }) {
    return GlassmorphismConfig(
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      gradient: gradient ?? this.gradient,
    );
  }
}

/// Helper class that builds [BoxDecoration] instances styled with a
/// glassmorphism (frosted-glass) aesthetic.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: GlassmorphismDecoration.build(),
///   child: …,
/// )
/// ```
///
/// For the full frosted-glass effect you also need to wrap the container
/// in a [ClipRRect] + [BackdropFilter] – see [GlassCard] for a turnkey
/// widget that does this automatically.
abstract final class GlassmorphismDecoration {
  /// Builds a [BoxDecoration] with the frosted-glass look.
  ///
  /// All parameters are optional and default to values from
  /// [GlassmorphismConfig].
  static BoxDecoration build({
    double opacity = 0.15,
    double borderRadius = AppSizes.radiusLg,
    Color? borderColor,
    Gradient? gradient,
  }) {
    final resolvedBorder = borderColor ?? AppColors.cardBorder;

    return BoxDecoration(
      color: gradient == null
          ? Colors.white.withValues(alpha: opacity)
          : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: resolvedBorder, width: 1),
    );
  }

  /// Convenience: builds a decoration directly from a [GlassmorphismConfig].
  static BoxDecoration fromConfig(GlassmorphismConfig config) {
    return build(
      opacity: config.opacity,
      borderRadius: config.borderRadius,
      borderColor: config.resolvedBorderColor,
      gradient: config.gradient,
    );
  }

  /// A prominent variant with a neon-purple border glow.
  static BoxDecoration neonGlow({
    double opacity = 0.15,
    double borderRadius = AppSizes.radiusLg,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.neonPurple.withValues(alpha: 0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.neonPurpleGlow,
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ],
    );
  }
}
