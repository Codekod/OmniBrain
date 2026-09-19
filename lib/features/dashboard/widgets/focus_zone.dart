import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/features/pomodoro/providers/pomodoro_providers.dart';
import 'package:omnibrain_ai/features/reminders/reminders_screen.dart';

/// Vertical stacked focus zone with live timer, live reminder, and AI suggestion cards.
class FocusZone extends ConsumerWidget {
  const FocusZone({super.key});

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Live Pomodoro state
    final pomodoroState = ref.watch(pomodoroProvider);
    final isTimerActive = pomodoroState.isRunning || (pomodoroState.remainingSeconds < pomodoroState.totalSeconds);
    final timerTitle = pomodoroState.isBreak
        ? 'Mola Zamanı'
        : (pomodoroState.isRunning ? 'Aktif Odaklanma' : (isTimerActive ? 'Duraklatıldı' : 'Pomodoro Zamanlayıcı'));
    final timerSubtitle = isTimerActive
        ? '${_formatDuration(pomodoroState.remainingSeconds)} kaldı'
        : '${pomodoroState.focusMinutes} dk Odaklanma Seansı';
    final timerLabel = pomodoroState.isRunning ? 'Devam Ediyor' : (isTimerActive ? 'Duraklatıldı' : 'Başlat');

    // 2. Live Reminders state
    final remindersAsync = ref.watch(remindersListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.iceBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Focus Zone',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Pomodoro Card (Live)
          _FocusCard(
            icon: Icons.timer_rounded,
            iconColor: pomodoroState.isRunning ? AppColors.softGreen : AppColors.neonPurple,
            borderColor: pomodoroState.isRunning ? AppColors.softGreen : AppColors.neonPurple,
            title: timerTitle,
            subtitle: timerSubtitle,
            label: timerLabel,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/pomodoro');
            },
          ),
          const SizedBox(height: 12),

          // 2. Reminders Card (Live)
          remindersAsync.when(
            data: (reminders) {
              if (reminders.isNotEmpty) {
                final nextReminder = reminders.first;
                final now = DateTime.now();
                final isToday = nextReminder.dueDate.year == now.year &&
                    nextReminder.dueDate.month == now.month &&
                    nextReminder.dueDate.day == now.day;

                final timeStr = DateFormat('HH:mm').format(nextReminder.dueDate);
                final dateStr = isToday ? 'Bugün $timeStr' : DateFormat('dd MMM, HH:mm', 'tr').format(nextReminder.dueDate);

                return _FocusCard(
                  icon: Icons.notifications_active_rounded,
                  iconColor: AppColors.amber,
                  borderColor: AppColors.amber,
                  title: 'Yaklaşan Hatırlatıcı',
                  subtitle: nextReminder.title,
                  label: dateStr,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/reminders');
                  },
                );
              }
              return _FocusCard(
                icon: Icons.notifications_none_rounded,
                iconColor: AppColors.amber,
                borderColor: AppColors.amber,
                title: 'Hatırlatıcılar',
                subtitle: 'Planlanmış görev yok',
                label: '+ Ekle',
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/reminders');
                },
              );
            },
            loading: () => const _FocusCard(
              icon: Icons.notifications_active_rounded,
              iconColor: AppColors.amber,
              borderColor: AppColors.amber,
              title: 'Hatırlatıcılar',
              subtitle: 'Yükleniyor...',
              label: '',
            ),
            error: (_, _) => _FocusCard(
              icon: Icons.notifications_none_rounded,
              iconColor: AppColors.amber,
              borderColor: AppColors.amber,
              title: 'Hatırlatıcılar',
              subtitle: 'Görev eklemek için dokunun',
              label: '+ Ekle',
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/reminders');
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. AI Suggestion Card
          _FocusCard(
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.iceBlue,
            borderColor: AppColors.iceBlue,
            title: 'AI Günlük Asistan',
            subtitle: 'Bugün odaklanmak için bir hedef belirleyelim mi?',
            label: 'Sor',
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/ai-command');
            },
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final String label;
  final VoidCallback? onTap;

  const _FocusCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left neon accent bar
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        borderColor,
                        borderColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: iconColor, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: borderColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
