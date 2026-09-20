import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/features/pomodoro/providers/pomodoro_providers.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with WidgetsBindingObserver {
  final TextEditingController _taskController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(pomodoroProvider.notifier).syncFromBackground();
    }
  }

  Future<void> _askAiForSuggestion() async {
    final task = _taskController.text.trim();
    if (task.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final aiRepo = ref.read(aiCommandRepositoryProvider);
      final responseStr = await aiRepo.getPomodoroSuggestion(task);

      final cleanJson = responseStr.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanJson);

      final int focus = data['focusMinutes'] ?? 25;
      final int breakMins = data['breakMinutes'] ?? 5;
      final String msg = data['message'] ?? 'Odaklanma zamanı!';

      ref.read(pomodoroProvider.notifier).setAiSuggestion(focus, breakMins, msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    final minutes = (pomodoroState.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (pomodoroState.remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = pomodoroState.totalSeconds > 0
        ? pomodoroState.remainingSeconds / pomodoroState.totalSeconds
        : 0.0;

    final primaryColor = pomodoroState.isBreak ? AppColors.softGreen : AppColors.neonPurple;
    final modeText = pomodoroState.isBreak ? "MOLA ZAMANI" : "ODAKLANMA";

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Odaklanma & Pomodoro',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            // Daily session count pill
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.softGreen.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.softGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${pomodoroState.completedSessionsToday} Seans',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.softGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // AI Task duration coach
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_rounded, color: AppColors.iceBlue, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "Ne yapacaksın? AI süre önersin...",
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _askAiForSuggestion(),
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: AppColors.iceBlue, strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.auto_awesome, color: AppColors.iceBlue, size: 20),
                          tooltip: 'AI ile Süre Planla',
                          onPressed: _askAiForSuggestion,
                        ),
                    ],
                  ),
                ),
              ),

              // Preset Duration Pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _buildPresetChip(
                      label: '25 dk',
                      focus: 25,
                      breakMins: 5,
                      title: 'Klasik Pomodoro',
                      notifier: notifier,
                      isSelected: pomodoroState.focusMinutes == 25 && !pomodoroState.isBreak,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      label: '45 dk',
                      focus: 45,
                      breakMins: 10,
                      title: 'Derin Çalışma',
                      notifier: notifier,
                      isSelected: pomodoroState.focusMinutes == 45 && !pomodoroState.isBreak,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      label: '60 dk',
                      focus: 60,
                      breakMins: 15,
                      title: 'Maraton',
                      notifier: notifier,
                      isSelected: pomodoroState.focusMinutes == 60 && !pomodoroState.isBreak,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      label: '5 dk Mola',
                      focus: pomodoroState.focusMinutes,
                      breakMins: 5,
                      title: 'Hızlı Mola',
                      isBreakPreset: true,
                      notifier: notifier,
                      isSelected: pomodoroState.isBreak,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Mode Badge (Odaklanma vs. Mola)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  modeText,
                  style: GoogleFonts.inter(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
              ).animate(target: pomodoroState.isRunning ? 1 : 0).shimmer(duration: 2.seconds),

              const SizedBox(height: 24),

              // Circular Countdown Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 270,
                    height: 270,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.darkNavy,
                      color: primaryColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$minutes:$seconds',
                        style: GoogleFonts.montserrat(
                          fontSize: 62,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                      if (!pomodoroState.isRunning &&
                          pomodoroState.remainingSeconds < pomodoroState.totalSeconds)
                        Text(
                          "DURAKLATILDI",
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            letterSpacing: 2,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (pomodoroState.isRunning)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pomodoroState.isBreak ? "DİNLENME" : "ODAKLANILIYOR",
                              style: GoogleFonts.inter(
                                color: primaryColor,
                                letterSpacing: 1.5,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Timer Controls (Reset - Play/Pause - Skip)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: Icons.refresh_rounded,
                    color: Colors.white54,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      notifier.resetTimer();
                    },
                  ),
                  const SizedBox(width: 28),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      notifier.toggleTimer();
                    },
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(
                        pomodoroState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  _buildControlButton(
                    icon: Icons.skip_next_rounded,
                    color: Colors.white54,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      notifier.skipSession();
                    },
                  ),
                ],
              ),

              const Spacer(),

              // Session Status Message (Clean, non-redundant)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pomodoroState.isBreak ? Icons.coffee_rounded : Icons.flare_rounded,
                        color: pomodoroState.isBreak ? AppColors.softGreen : AppColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pomodoroState.isRunning
                              ? (pomodoroState.isBreak
                                  ? "Gözlerini dinlendir, derin nefes al..."
                                  : "Odaklanma aktif. Süre bitince seni sesle uyaracağız 🔔")
                              : pomodoroState.message,
                          style: AppTextStyles.bodyText.copyWith(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required int focus,
    required int breakMins,
    required String title,
    required PomodoroNotifier notifier,
    required bool isSelected,
    bool isBreakPreset = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (isBreakPreset) {
            notifier.setPresetDuration(focus, breakMins, title);
          } else {
            notifier.setPresetDuration(focus, breakMins, title);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isBreakPreset ? AppColors.softGreen.withValues(alpha: 0.25) : AppColors.neonPurple.withValues(alpha: 0.25))
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? (isBreakPreset ? AppColors.softGreen : AppColors.neonPurple)
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? (isBreakPreset ? AppColors.softGreen : Colors.white)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
