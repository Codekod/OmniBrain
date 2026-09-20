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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softGreen.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.softGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Text('☕', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Text(
            'Mola Zamanı',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.softGreen,
            ),
          ),
          Text(
            'Zihnini tazele...',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
          ),
        ],
      );
    }

    final String emoji;
    final String stageName;
    final String stageDesc;
    final Color glowColor;
    final Color badgeBgColor;
    final Widget? stageBadge;

    switch (treeType) {
      case FocusTreeType.sakura:
        glowColor = const Color(0xFFFF69B4); // Pink glow
        badgeBgColor = const Color(0x28FF69B4);
        if (progress < 0.25) {
          emoji = '🌸'; // Sakura tohumu: açan çiçek tomurcuğu
          stageName = 'Sakura Tohumu';
          stageDesc = 'Pembe tomurcuk uyanıyor...';
          stageBadge = const Text('🌸', style: TextStyle(fontSize: 10));
        } else if (progress < 0.55) {
          emoji = '💮'; // Pembe çiçek rozeti
          stageName = 'Pembe Filiz';
          stageDesc = 'Dallar çiçekleniyor...';
          stageBadge = const Text('✨', style: TextStyle(fontSize: 10));
        } else if (progress < 0.85) {
          emoji = '🌺'; // Canlı açan çiçek
          stageName = 'Açan Sakura';
          stageDesc = 'Zen dinginliği ve huzur!';
          stageBadge = const Text('🌸', style: TextStyle(fontSize: 10));
        } else {
          emoji = '🌸'; // Ulu sakura
          stageName = 'Ulu Sakura Ağacı';
          stageDesc = 'Çiçekler saçılıyor ✨';
          stageBadge = const Text('👑', style: TextStyle(fontSize: 10));
        }
        break;

      case FocusTreeType.bonsai:
        glowColor = AppColors.amber;
        badgeBgColor = AppColors.amber.withValues(alpha: 0.18);
        if (progress < 0.25) {
          emoji = '🪴'; // Saksıda tohum
          stageName = 'Bonsai Saksısı';
          stageDesc = 'Sabırla kök salıyor...';
          stageBadge = const Text('🌱', style: TextStyle(fontSize: 10));
        } else if (progress < 0.55) {
          emoji = '🎍'; // Zen bambu fidanı
          stageName = 'Zen Fidanı';
          stageDesc = 'Zarafetle şekilleniyor...';
          stageBadge = const Text('🎋', style: TextStyle(fontSize: 10));
        } else if (progress < 0.85) {
          emoji = '🪴'; // Usta bonsai saksısı
          stageName = 'Usta Bonsai';
          stageDesc = 'Derin odak ve denge!';
          stageBadge = const Text('✨', style: TextStyle(fontSize: 10));
        } else {
          emoji = '🎋'; // Usta zen
          stageName = 'İmparatorluk Bonsai';
          stageDesc = 'Kusursuz konsantrasyon ✨';
          stageBadge = const Text('🏆', style: TextStyle(fontSize: 10));
        }
        break;

      case FocusTreeType.pine:
        glowColor = AppColors.softGreen;
        badgeBgColor = AppColors.softGreen.withValues(alpha: 0.18);
        if (progress < 0.25) {
          emoji = '🌰'; // Çam kozalağı / tohumu
          stageName = 'Çam Kozalağı';
          stageDesc = 'Odak tohumu ekildi...';
          stageBadge = const Text('🌱', style: TextStyle(fontSize: 10));
        } else if (progress < 0.55) {
          emoji = '🌿'; // Genç çam fidanı
          stageName = 'Genç Çam Sürgünü';
          stageDesc = 'İğne yapraklar beliriyor...';
          stageBadge = const Text('🌲', style: TextStyle(fontSize: 10));
        } else if (progress < 0.85) {
          emoji = '🌲'; // Orman çamı
          stageName = 'Orman Çamı';
          stageDesc = 'Derin dağ konsantrasyonu!';
          stageBadge = const Text('✨', style: TextStyle(fontSize: 10));
        } else {
          emoji = '🌲'; // Ulu çam
          stageName = 'Ulu Çam Ağacı';
          stageDesc = 'Zirve verimlilik ✨';
          stageBadge = const Text('⭐', style: TextStyle(fontSize: 10));
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
            // Ambient glowing circle based on tree theme
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: isRunning ? 0.35 : 0.18),
                    glowColor.withValues(alpha: 0.0),
                  ],
                ),
                border: Border.all(
                  color: glowColor.withValues(alpha: isRunning ? 0.6 : 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: isRunning ? 0.4 : 0.2),
                    blurRadius: isRunning ? 28 : 16,
                    spreadRadius: isRunning ? 4 : 1,
                  ),
                ],
              ),
            ),

            // Pulsing animation when running
            if (isRunning)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor.withValues(alpha: 0.1),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.15, 1.15), duration: 2000.ms),

            // Emoji icon container with smooth transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Text(
                emoji,
                key: ValueKey('$treeType-$progress'),
                style: const TextStyle(fontSize: 38),
              ),
            ),

            // Corner stage badge
            Positioned(
              top: 0,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeBgColor,
                  border: Border.all(color: glowColor.withValues(alpha: 0.5), width: 1),
                ),
                child: stageBadge,
              ),
            ),

            // Crown sparkle when fully grown
            if (isFullyGrown)
              const Positioned(
                top: -2,
                left: 2,
                child: Text('✨', style: TextStyle(fontSize: 14)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          stageName,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stageDesc,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
