import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/constants/app_strings.dart';
import 'package:omnibrain_ai/core/providers/streak_provider.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/features/dashboard/widgets/ai_command_bar.dart';
import 'package:omnibrain_ai/features/dashboard/widgets/smart_tool_grid.dart';
import 'package:omnibrain_ai/features/dashboard/widgets/focus_zone.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showStreakDetails(BuildContext context, StreakState streak) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.deepNightBlue.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Flame icon with animated glow
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.amber.withValues(alpha: 0.25),
                          AppColors.coralRed.withValues(alpha: 0.25),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.amber,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '${streak.currentStreak} Günlük Seri!',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Her gün bir not al, odaklan veya bir hesap yap; serini koru!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly activity pill days
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'].map((day) {
                      final isActive = streak.weeklyActivityDays.contains(day);
                      return Column(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isActive
                                  ? const LinearGradient(
                                      colors: [AppColors.amber, AppColors.coralRed],
                                    )
                                  : null,
                              color: isActive ? null : Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.amber
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Icon(
                              isActive ? Icons.check_rounded : Icons.circle_outlined,
                              color: isActive ? Colors.black87 : AppColors.textSecondary.withValues(alpha: 0.4),
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            day,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              color: isActive ? AppColors.amber : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Best streak stats card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: AppColors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'En İyi Seri',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${streak.bestStreak} Gün',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);

    return GradientBackground(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.deepNightBlue.withValues(alpha: 0.85),
            pinned: true,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.neonPurple, AppColors.iceBlue],
              ).createShader(bounds),
              child: Text(
                AppStrings.appName,
                style: AppTextStyles.largeTitle.copyWith(color: Colors.white),
              ),
            ),
            actions: [
              // Streak badge in app bar
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => _showStreakDetails(context, streak),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${streak.currentStreak}',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          // Personalized greeting section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer(
                builder: (context, ref, child) {
                  final hour = DateTime.now().hour;
                  final greeting = hour < 12 ? 'Günaydın! 👋' : (hour < 18 ? 'Tünaydın! ☀️' : 'İyi Akşamlar! 🌙');
                  final dateStr = DateFormat('d MMMM yyyy, EEEE', 'tr').format(DateTime.now());
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTextStyles.pageTitle.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AiCommandBar(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Animated gradient divider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.borderHighlight,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SmartToolGrid(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(
            child: FocusZone(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
