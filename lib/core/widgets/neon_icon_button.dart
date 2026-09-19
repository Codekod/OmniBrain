import 'package:flutter/material.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/constants/app_sizes.dart';
import 'package:omnibrain_ai/core/utils/haptic_utils.dart';

/// A circular icon button with a neon glow effect.
///
/// Designed for toolbars, FABs, and action rows in the OmniBrain UI.
///
/// ```dart
/// NeonIconButton(
///   icon: Icons.add,
///   onTap: () => …,
/// )
/// ```
class NeonIconButton extends StatelessWidget {
  const NeonIconButton({
    required this.icon,
    this.onTap,
    this.size = AppSizes.iconButtonSize,
    this.iconSize = AppSizes.iconMd,
    this.color,
    this.iconColor,
    this.glowColor,
    this.tooltip,
    this.enabled = true,
    super.key,
  });

  /// The icon to display.
  final IconData icon;

  /// Called when the button is tapped.
  final VoidCallback? onTap;

  /// Outer diameter of the button. Defaults to 48 px.
  final double size;

  /// Size of the inner icon. Defaults to 26 px.
  final double iconSize;

  /// Background fill colour. Defaults to [AppColors.neonPurple].
  final Color? color;

  /// Icon tint. Defaults to [AppColors.textPrimary].
  final Color? iconColor;

  /// Glow shadow colour. Defaults to [AppColors.neonPurpleGlow].
  final Color? glowColor;

  /// Optional tooltip shown on long-press.
  final String? tooltip;

  /// When false the button is visually dimmed and ignores taps.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.neonPurple;
    final fgColor = iconColor ?? AppColors.textPrimary;
    final glow = glowColor ?? AppColors.neonPurpleGlow;

    final effectiveOpacity = enabled ? 1.0 : 0.4;

    Widget button = Opacity(
      opacity: effectiveOpacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: glow,
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticUtils.lightImpact();
                    onTap?.call();
                  }
                : null,
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Center(
              child: Icon(icon, size: iconSize, color: fgColor),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
