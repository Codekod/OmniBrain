import 'package:flutter/material.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';

/// A full-screen gradient background used as the base layer for every page.
///
/// Renders a [LinearGradient] from [AppColors.deepNightBlue] (top) to
/// [AppColors.darkNavy] (bottom) behind its [child].
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
    super.key,
  });

  /// The content rendered on top of the gradient.
  final Widget child;

  /// Optional padding applied inside the gradient container.
  final EdgeInsetsGeometry? padding;

  /// Custom gradient override. Defaults to [AppColors.backgroundGradient].
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.backgroundGradient,
      ),
      child: child,
    );
  }
}
