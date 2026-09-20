import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/premium_card.dart';
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
            accentColor: pomodoroState.isRunning ? AppColors.softGreen : AppColors.neonPurple,
            title: timerTitle,
            subtitle: timerSubtitle,
            label: timerLabel,
            variant: pomodoroState.isRunning ? PremiumCardVariant.neonBorder : PremiumCardVariant.standard,
            trailing: pomodoroState.isRunning
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.softGreen,
                      strokeWidth: 2,
                      value: pomodoroState.remainingSeconds / pomodoroState.totalSeconds,
                    ),
                  )
                : null,
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
                  accentColor: AppColors.amber,
                  title: 'Yaklaşan Hatırlatıcı',
                  subtitle: nextReminder.title,
                  label: dateStr,
                  surfaceGradient: LinearGradient(
                    colors: [
                      AppColors.amber.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/reminders');
                  },
                );
              }
              return _FocusCard(
                icon: Icons.notifications_none_rounded,
                iconColor: AppColors.amber,
                accentColor: AppColors.amber,
                title: 'Hatırlatıcılar',
                subtitle: 'Planlanmış görev yok',
                label: '+ Ekle',
                surfaceGradient: LinearGradient(
                  colors: [
                    AppColors.amber.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/reminders');
                },
              );
            },
            loading: () => const _FocusCard(
              icon: Icons.notifications_active_rounded,
              iconColor: AppColors.amber,
              accentColor: AppColors.amber,
              title: 'Hatırlatıcılar',
              subtitle: 'Yükleniyor...',
              label: '',
            ),
            error: (_, _) => _FocusCard(
              icon: Icons.notifications_none_rounded,
              iconColor: AppColors.amber,
              accentColor: AppColors.amber,
              title: 'Hatırlatıcılar',
              subtitle: 'Görev eklemek için dokunun',
              label: '+ Ekle',
              surfaceGradient: LinearGradient(
                colors: [
                  AppColors.amber.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
            accentColor: AppColors.iceBlue,
            title: 'AI Günlük Asistan',
            subtitle: 'Bugün odaklanmak için bir hedef belirleyelim mi?',
            label: 'Sor',
            surfaceGradient: LinearGradient(
              colors: [
                AppColors.iceBlue.withValues(alpha: 0.15),
                Colors.transparent,
                AppColors.iceBlue.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
  final Color accentColor;
  final String title;
  final String subtitle;
  final String label;
  final VoidCallback? onTap;
  final PremiumCardVariant variant;
  final Widget? trailing;
  final Gradient? surfaceGradient;

  const _FocusCard({
    required this.icon,
    required this.iconColor,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.label,
    this.onTap,
    this.variant = PremiumCardVariant.standard,
    this.trailing,
    this.surfaceGradient,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      variant: variant,
      accentColor: accentColor,
      onTap: onTap,
      padding: EdgeInsets.zero, // We will handle padding inside for gradient
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: surfaceGradient,
        ),
        padding: const EdgeInsets.all(16),
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
                    accentColor,
                    accentColor.withValues(alpha: 0.2),
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
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
            if (label.isNotEmpty && trailing == null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
