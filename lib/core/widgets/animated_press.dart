import 'package:flutter/material.dart';

import 'package:omnibrain_ai/core/utils/haptic_utils.dart';

/// A wrapper that adds a satisfying "press-down" scale animation to its child.
///
/// When the user touches down the child scales to [scaleDown] (default 0.95)
/// and springs back to 1.0 on release or cancel. A light haptic is fired on
/// each tap-down for tactile feedback.
///
/// ```dart
/// AnimatedPress(
///   onTap: () => print('tapped'),
///   child: MyCard(),
/// )
/// ```
class AnimatedPress extends StatefulWidget {
  const AnimatedPress({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 120),
    this.enabled = true,
    super.key,
  });

  /// The widget to wrap.
  final Widget child;

  /// Called when the user lifts their finger after a tap.
  final VoidCallback? onTap;

  /// Called on a long-press gesture.
  final VoidCallback? onLongPress;

  /// The scale factor applied while the user holds down. Must be ≤ 1.0.
  final double scaleDown;

  /// How long the scale transition takes.
  final Duration duration;

  /// When false the widget ignores gestures and does not animate.
  final bool enabled;

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    HapticUtils.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
  }

  void _handleLongPress() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    HapticUtils.mediumImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
