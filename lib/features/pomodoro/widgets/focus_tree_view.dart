import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';

class FocusTreeView extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final bool isRunning;
  final bool isBreak;

  const FocusTreeView({
    super.key,
    required this.progress,
    required this.isRunning,
    this.isBreak = false,
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
            'Dinlenme Zamanı',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.softGreen,
            ),
          ),
        ],
      );
    }

    final String emoji;
    final String stageName;
    final String stageDesc;

    if (progress < 0.25) {
      emoji = '🌱';
      stageName = 'Tohum / Filiz';
      stageDesc = 'Odak tohumu ekildi...';
    } else if (progress < 0.55) {
      emoji = '🌿';
      stageName = 'Genç Fidan';
      stageDesc = 'Dallar filizleniyor...';
    } else if (progress < 0.85) {
      emoji = '🪴';
      stageName = 'Odak Ağacı';
      stageDesc = 'Derin konsantrasyon!';
    } else {
      emoji = '🌳';
      stageName = 'Ulu Odak Ağacı';
      stageDesc = 'Zirve verimlilik!';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isRunning)
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.softGreen.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.softGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 2000.ms),
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
