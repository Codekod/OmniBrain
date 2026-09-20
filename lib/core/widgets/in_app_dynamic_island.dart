import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/features/pomodoro/providers/pomodoro_providers.dart';

class InAppDynamicIsland extends ConsumerWidget {
  const InAppDynamicIsland({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro = ref.watch(pomodoroProvider);

    // Only display if pomodoro timer is active
    if (!pomodoro.isRunning) {
      return const SizedBox.shrink();
    }

    final minutes = (pomodoro.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (pomodoro.remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = pomodoro.totalSeconds > 0
        ? (pomodoro.totalSeconds - pomodoro.remainingSeconds) / pomodoro.totalSeconds
        : 0.0;

    final primaryColor = pomodoro.isBreak ? AppColors.softGreen : AppColors.neonPurple;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(RoutePaths.pomodoro);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing activity indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 2.2,
                          color: primaryColor,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      Icon(
                        pomodoro.isBreak ? Icons.coffee_rounded : Icons.timer_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    pomodoro.isBreak ? 'Mola' : 'Odak',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.white30,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$minutes:$seconds',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.iceBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.3, end: 0);
  }
}
