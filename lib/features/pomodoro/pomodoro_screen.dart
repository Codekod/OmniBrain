import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  final TextEditingController _taskController = TextEditingController();
  bool _isLoading = false;

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
  Widget build(BuildContext context) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    final minutes = (pomodoroState.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (pomodoroState.remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = pomodoroState.totalSeconds > 0 
        ? pomodoroState.remainingSeconds / pomodoroState.totalSeconds 
        : 0.0;

    final primaryColor = pomodoroState.isBreak ? AppColors.softGreen : AppColors.neonPurple;
    final modeText = pomodoroState.isBreak ? "MOLA" : "ODAK";

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Zamanın Efendisi'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // AI Komut Alanı
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Ne yapacaksın? (Örn: Kod yazacağım)",
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _askAiForSuggestion(),
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: AppColors.iceBlue, strokeWidth: 2),
                        )
                      else
                        GestureDetector(
                          onTap: _askAiForSuggestion,
                          child: const Icon(Icons.auto_awesome, color: AppColors.iceBlue),
                        ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Mod Etiketi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                ),
                child: Text(
                  modeText,
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ).animate(target: pomodoroState.isRunning ? 1 : 0).shimmer(duration: 2.seconds),

              const SizedBox(height: 30),

              // Dairesel Sayaç
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
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
                        style: const TextStyle(
                          fontSize: 64, 
                          fontWeight: FontWeight.w200, 
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (!pomodoroState.isRunning && pomodoroState.remainingSeconds < pomodoroState.totalSeconds)
                        Text("DURAKLATILDI", style: TextStyle(color: Colors.white54, letterSpacing: 2))
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Kontroller
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: Icons.refresh,
                    color: Colors.white54,
                    onTap: notifier.resetTimer,
                  ),
                  const SizedBox(width: 30),
                  GestureDetector(
                    onTap: notifier.toggleTimer,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(
                        pomodoroState.isRunning ? Icons.pause : Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  _buildControlButton(
                    icon: Icons.skip_next,
                    color: Colors.white54,
                    onTap: notifier.skipSession,
                  ),
                ],
              ),

              const Spacer(),

              // AI Mesajı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates, color: AppColors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pomodoroState.message,
                          style: AppTextStyles.bodyText.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkNavy,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
