import 'package:flutter/material.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';

/// A full-screen gradient background with ambient aurora mesh glow orbs.
///
/// Renders a [LinearGradient] base from [AppColors.deepNightBlue] to
/// [AppColors.darkNavy], overlaid with subtle radial purple and cyan
/// ambient orbs that give glassmorphism cards vibrant color to refract.
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return GradientBackground(
///     child: SafeArea(child: …),
///   );
/// }
/// ```
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.child,
    this.padding,
    this.gradient,
    this.showAurora = true,
    super.key,
  });

  /// The content rendered on top of the gradient.
  final Widget child;

  /// Optional padding applied inside the gradient container.
  final EdgeInsetsGeometry? padding;

  /// Custom gradient override. Defaults to [AppColors.backgroundGradient].
  final Gradient? gradient;

  /// Whether to render the ambient aurora glow orbs. Defaults to true.
  final bool showAurora;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.backgroundGradient,
      ),
      child: showAurora
          ? Stack(
              children: [
                // Aurora orb 1 – purple glow (top-left)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: AppColors.auroraOrb1,
                    ),
                  ),
                ),
                // Aurora orb 2 – cyan glow (bottom-right)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: AppColors.auroraOrb2,
                    ),
                  ),
                ),
                // Content layer
                child,
              ],
            )
          : child,
    );
  }
}
