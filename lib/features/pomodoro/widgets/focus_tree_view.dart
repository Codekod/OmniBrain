import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';

enum FocusTreeType {
  pine,
  sakura,
  bonsai,
}

class FocusTreeView extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final bool isRunning;
  final bool isBreak;
  final FocusTreeType treeType;

  const FocusTreeView({
    super.key,
    required this.progress,
    required this.isRunning,
    this.isBreak = false,
    this.treeType = FocusTreeType.pine,
  });

  @override
  Widget build(BuildContext context) {
    if (isBreak) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('☕', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 6),
          Text(
            'Mola Zamanı',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.softGreen,
            ),
          ),
          Text(
            'Zihnini tazele...',
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
          ),
        ],
      );
    }

    final String emoji;
    final String stageName;
    final String stageDesc;
    final Color glowColor;

    switch (treeType) {
      case FocusTreeType.sakura:
        glowColor = const Color(0xFFFF69B4); // Pink glow
        if (progress < 0.25) {
          emoji = '🌱';
          stageName = 'Sakura Tohumu';
          stageDesc = 'Toprak canlanıyor...';
        } else if (progress < 0.55) {
          emoji = '🌿';
          stageName = 'Pembe Filiz';
          stageDesc = 'Tomurcuklar oluşuyor...';
        } else if (progress < 0.85) {
          emoji = '🌺';
          stageName = 'Açan Sakura';
          stageDesc = 'Zen dinginliği!';
        } else {
          emoji = '🌸';
          stageName = 'Ulu Sakura Ağacı';
          stageDesc = 'Çiçekler saçılıyor ✨';
        }
        break;

      case FocusTreeType.bonsai:
        glowColor = AppColors.amber;
        if (progress < 0.25) {
          emoji = '🌱';
          stageName = 'Bonsai Tohumu';
          stageDesc = 'Sabırla kök salıyor...';
        } else if (progress < 0.55) {
          emoji = '🌿';
          stageName = 'Zen Fidanı';
          stageDesc = 'Zarafetle şekilleniyor...';
        } else if (progress < 0.85) {
          emoji = '🎋';
          stageName = 'Altın Bambu';
          stageDesc = 'Derin odak modu!';
        } else {
          emoji = '🪴';
          stageName = 'Usta Bonsai Ağacı';
          stageDesc = 'Kusursuz konsantrasyon ✨';
        }
        break;

      case FocusTreeType.pine:
        glowColor = AppColors.softGreen;
        if (progress < 0.25) {
          emoji = '🌱';
          stageName = 'Tohum / Filiz';
          stageDesc = 'Odak tohumu ekildi...';
        } else if (progress < 0.55) {
          emoji = '🌿';
          stageName = 'Genç Çam';
          stageDesc = 'Dallar uzuyor...';
        } else if (progress < 0.85) {
          emoji = '🌲';
          stageName = 'Orman Çamı';
          stageDesc = 'Derin odaklanma!';
        } else {
          emoji = '🌳';
          stageName = 'Ulu Çam Ağacı';
          stageDesc = 'Zirve verimlilik ✨';
        }
        break;
    }

    final isFullyGrown = progress >= 0.98;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isRunning)
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.18, 1.18), duration: 2200.ms),

            if (isFullyGrown)
              const Positioned(
                top: 0,
                right: 0,
                child: Text('✨', style: TextStyle(fontSize: 14)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),

            Text(
              emoji,
              style: const TextStyle(fontSize: 38),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          stageName,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          stageDesc,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
