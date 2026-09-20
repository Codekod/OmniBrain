import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/animated_press.dart';

/// Visual variant for [PremiumCard].
enum PremiumCardVariant {
  /// Standard glassmorphic surface (default).
  standard,

  /// Elevated surface with stronger blur and border.
  elevated,

  /// Neon-purple glowing border accent.
  neonBorder,

  /// Hero card with higher opacity and prominent shadow.
  hero,
}

/// A premium glassmorphic card with specular border highlights, ambient
/// shadows, and optional press animation.
///
/// Replaces ad-hoc `Container` + `BackdropFilter` combos across the app with
/// a single, consistent, polished surface component.
///
/// ```dart
/// PremiumCard(
///   variant: PremiumCardVariant.elevated,
///   onTap: () => …,
///   child: Text('Hello'),
/// )
/// ```
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    required this.child,
    this.variant = PremiumCardVariant.standard,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.borderRadius = 20,
    this.accentColor,
    this.width,
    this.height,
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Visual variant controlling blur, opacity, and border treatment.
  final PremiumCardVariant variant;

  /// Tap callback – enables press animation when non-null.
  final VoidCallback? onTap;

  /// Long-press callback.
  final VoidCallback? onLongPress;

  /// Inner padding. Defaults to `EdgeInsets.all(16)`.
  final EdgeInsetsGeometry? padding;

  /// Corner radius. Defaults to 20.
  final double borderRadius;

  /// Optional accent color for the card border/glow (e.g. category color).
  final Color? accentColor;

  /// Fixed width (leave null for parent-constrained).
  final double? width;

  /// Fixed height (leave null for intrinsic).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final config = _VariantConfig.fromVariant(variant, accentColor);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: config.blur, sigmaY: config.blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: config.useGradient
                ? AppColors.glassCardGradient
                : null,
            color: config.useGradient
                ? null
                : Colors.white.withValues(alpha: config.fillOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: config.useBorderGradient
                ? _specularBorder(config)
                : Border.all(
                    color: config.borderColor,
                    width: config.borderWidth,
                  ),
            boxShadow: config.shadows,
          ),
          child: child,
        ),
      ),
    );

    // Wrap with press animation when interactive.
    if (onTap != null || onLongPress != null) {
      card = AnimatedPress(
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      );
    }

    return card;
  }

  Border _specularBorder(_VariantConfig config) {
    // Top and left borders brighter (simulating top-left light source)
    return Border(
      top: BorderSide(
        color: AppColors.borderHighlight,
        width: config.borderWidth,
      ),
      left: BorderSide(
        color: Colors.white.withValues(alpha: 0.10),
        width: config.borderWidth,
      ),
      right: BorderSide(
        color: AppColors.borderSubtle,
        width: config.borderWidth,
      ),
      bottom: BorderSide(
        color: AppColors.borderSubtle,
        width: config.borderWidth,
      ),
    );
  }
}

class _VariantConfig {
  final double blur;
  final double fillOpacity;
  final bool useGradient;
  final bool useBorderGradient;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;

  const _VariantConfig({
    required this.blur,
    required this.fillOpacity,
    required this.useGradient,
    required this.useBorderGradient,
    required this.borderColor,
    required this.borderWidth,
    required this.shadows,
  });

  factory _VariantConfig.fromVariant(
    PremiumCardVariant variant,
    Color? accentColor,
  ) {
    switch (variant) {
      case PremiumCardVariant.standard:
        return _VariantConfig(
          blur: 24,
          fillOpacity: 0.10,
          useGradient: true,
          useBorderGradient: true,
          borderColor: AppColors.cardBorder,
          borderWidth: 1,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        );
      case PremiumCardVariant.elevated:
        return _VariantConfig(
          blur: 28,
          fillOpacity: 0.14,
          useGradient: true,
          useBorderGradient: true,
          borderColor: AppColors.cardBorder,
          borderWidth: 1,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 32,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        );
      case PremiumCardVariant.neonBorder:
        final neonColor = accentColor ?? AppColors.neonPurple;
        return _VariantConfig(
          blur: 24,
          fillOpacity: 0.10,
          useGradient: true,
          useBorderGradient: false,
          borderColor: neonColor.withValues(alpha: 0.50),
          borderWidth: 1.5,
          shadows: [
            BoxShadow(
              color: neonColor.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        );
      case PremiumCardVariant.hero:
        return _VariantConfig(
          blur: 32,
          fillOpacity: 0.16,
          useGradient: true,
          useBorderGradient: true,
          borderColor: AppColors.cardBorder,
          borderWidth: 1,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        );
    }
  }
}
