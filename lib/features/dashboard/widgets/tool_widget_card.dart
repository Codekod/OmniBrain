import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';

/// A single tool card for the dashboard grid with a premium Apple Home/Fintech aesthetic.
class ToolWidgetCard extends StatefulWidget {
  final IconData iconData;
  final String name;
  final Color color;
  final VoidCallback? onTap;

  const ToolWidgetCard({
    super.key,
    required this.iconData,
    required this.name,
    required this.color,
    this.onTap,
  });

  @override
  State<ToolWidgetCard> createState() => _ToolWidgetCardState();
}

class _ToolWidgetCardState extends State<ToolWidgetCard> {
  double _scale = 1.0;
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    setState(() {
      _scale = 0.92;
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails _) {
    setState(() {
      _scale = 1.0;
      _isPressed = false;
    });
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                // Koyu arka planın üstüne hafif bir renkli gradient (glow efekti)
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withValues(alpha: _isPressed ? 0.2 : 0.1),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                // Premium ışık yansıması veren ince kenarlık (top-left daha parlak)
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Arka planda devasa silik ikon (Filigran tarzı)
                  Positioned(
                    right: -15,
                    bottom: -15,
                    child: Icon(
                      widget.iconData,
                      size: 80,
                      color: widget.color.withValues(alpha: 0.05),
                    ),
                  ),
                  
                  // Sol üstte parlayan ikon
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: _isPressed ? 0.4 : 0.2),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        ]
                      ),
                      child: Icon(
                        widget.iconData,
                        color: widget.color,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Sol altta metin (Apple tarzı yerleşim)
                  Positioned(
                    bottom: 14,
                    left: 16,
                    right: 8,
                    child: SizedBox(
                      height: 20,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
