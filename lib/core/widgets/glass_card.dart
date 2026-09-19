import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/constants/app_sizes.dart';
import 'package:omnibrain_ai/core/widgets/animated_press.dart';

/// A reusable frosted-glass card following the OmniBrain glassmorphism spec.
///
/// Combines [ClipRRect] → [BackdropFilter] → decorated [Container] so
/// callers only need to supply a [child] and optionally tweak visual params.
///
/// Tappable: provide [onTap] / [onLongPress] to wrap the card in an
/// [AnimatedPress] with scale feedback and haptics.
///
/// ```dart
/// GlassCard(
///   onTap: () => …,
///   child: Text('Hello'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.borderRadius = AppSizes.radiusLg,
    this.blur = 20,
    this.opacity = 0.15,
    this.borderColor,
    this.width,
    this.height,
    this.neonBorder = false,
    this.gradient,
    super.key,
  });

  /// The card content.
  final Widget child;

  /// Tap callback – enables the press animation when non-null.
  final VoidCallback? onTap;

  /// Long-press callback.
  final VoidCallback? onLongPress;

  /// Inner padding. Defaults to [AppSizes.cardPaddingAll].
  final EdgeInsetsGeometry? padding;

  /// Corner radius. Defaults to 24 px.
  final double borderRadius;

  /// Backdrop blur sigma. Defaults to 20.
  final double blur;

  /// White-fill opacity. Defaults to 0.15.
  final double opacity;

  /// Border colour override. Defaults to [AppColors.cardBorder].
  final Color? borderColor;

  /// Fixed width (leave null for intrinsic / parent-constrained).
  final double? width;

  /// Fixed height (leave null for intrinsic / parent-constrained).
  final double? height;

  /// When true, renders a glowing neon-purple border instead of the default.
  final bool neonBorder;

  /// Optional gradient overlay on the card surface.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final resolvedBorderColor = neonBorder
        ? AppColors.neonPurple.withValues(alpha: 0.5)
        : (borderColor ?? AppColors.cardBorder);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? AppSizes.cardPaddingAll,
          decoration: BoxDecoration(
            color: gradient == null
                ? Colors.white.withValues(alpha: opacity)
                : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: resolvedBorderColor,
              width: neonBorder ? 1.5 : 1,
            ),
            boxShadow: neonBorder
                ? [
                    BoxShadow(
                      color: AppColors.neonPurpleGlow,
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
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
}
