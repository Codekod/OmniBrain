import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omnibrain_ai/core/widgets/animated_press.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';

/// A single tool card for the dashboard grid with a premium Apple Home/Fintech aesthetic.
class ToolWidgetCard extends StatelessWidget {
  final IconData iconData;
  final String name;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;
  final String? badge;
  final bool isHero;

  const ToolWidgetCard({
    super.key,
    required this.iconData,
    required this.name,
    required this.color,
    this.onTap,
    this.subtitle,
    this.badge,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              // Koyu arka planın üstüne hafif bir renkli gradient (glow efekti)
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              // Premium ışık yansıması veren ince kenarlık (top-left daha parlak)
              border: Border(
                top: BorderSide(color: AppColors.borderHighlight, width: 1.5),
                left: BorderSide(color: AppColors.borderHighlight, width: 1.5),
                right: BorderSide(color: AppColors.borderSubtle, width: 1),
                bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
            ),
            child: Stack(
              children: [
                // Arka planda devasa silik ikon (Filigran tarzı)
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    iconData,
                    size: isHero ? 100 : 80,
                    color: color.withValues(alpha: 0.05),
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
                      color: color.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    ),
                    child: Icon(
                      iconData,
                      color: color,
                      size: isHero ? 32 : 24,
                    ),
                  ),
                ),

                // Sağ üstte optional badge
                if (badge != null)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.badge.copyWith(color: color),
                      ),
                    ),
                  ),
                
                // Sol altta metin (Apple tarzı yerleşim)
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 20,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            name,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.microText.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
