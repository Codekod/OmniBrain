import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/services/ambient_sound_service.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/widgets/premium_card.dart';
import 'package:omnibrain_ai/features/pomodoro/providers/pomodoro_providers.dart';
import 'package:omnibrain_ai/features/pomodoro/widgets/ambient_visual_layer.dart';
import 'package:omnibrain_ai/features/pomodoro/widgets/focus_tree_view.dart';
import 'package:omnibrain_ai/features/pomodoro/widgets/forest_garden_sheet.dart';
import 'package:omnibrain_ai/features/pomodoro/widgets/zen_focus_mode_view.dart';
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
            // Zen Mode button
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded, color: AppColors.iceBlue),
              tooltip: 'Zen Modu',
              onPressed: () => ZenFocusModeView.open(context),
            ),
            // Forest Garden Sheet button
            IconButton(
              icon: const Icon(Icons.park_rounded, color: AppColors.softGreen),
              tooltip: 'Bugünkü Ormanım',
              onPressed: () => ForestGardenSheet.show(context),
            ),
            // Daily session count pill
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => ForestGardenSheet.show(context),
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
                        const Icon(Icons.eco_rounded, color: AppColors.softGreen, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${pomodoroState.completedSessionsToday} Ağaç',
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
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient sound 60fps dynamic visual background
              const AmbientVisualLayer(),

              // Main Pomodoro Content
              CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                  // AI Task duration coach
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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

                  // Category Selector Chips
                  _buildCategorySelector(pomodoroState.selectedCategory, notifier),

                  // Focus Tree Selector Chips (Pine, Sakura, Bonsai)
                  _buildTreeTypeSelector(pomodoroState.selectedTreeType, ref.watch(isProProvider), notifier),

                  // 4-Round Pomodoro Cycle Indicator
                  _buildCycleIndicator(pomodoroState),

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

                  const SizedBox(height: 16),

                  // Circular Countdown Timer with Animated Focus Tree
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 270,
                        height: 270,
                        child: CustomPaint(
                          painter: _TimerRingPainter(
                            progress: progress,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FocusTreeView(
                            progress: pomodoroState.totalSeconds > 0
                                ? (pomodoroState.totalSeconds - pomodoroState.remainingSeconds) / pomodoroState.totalSeconds
                                : 0.0,
                            isRunning: pomodoroState.isRunning,
                            isBreak: pomodoroState.isBreak,
                            treeType: pomodoroState.selectedTreeType,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$minutes:$seconds',
                            style: AppTextStyles.timerDisplay.copyWith(
                              color: Colors.white,
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

                  const SizedBox(height: 32),

                  // Timer Controls (Reset - Play/Pause - Skip)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: Icons.refresh_rounded,
                        color: Colors.white54,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _handleReset(context, notifier, pomodoroState.isRunning);
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
                            gradient: pomodoroState.isBreak 
                                ? const LinearGradient(colors: [AppColors.softGreen, AppColors.amber])
                                : const LinearGradient(colors: [AppColors.neonPurple, AppColors.iceBlue]),
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
                      ).animate(
                        onPlay: (controller) => controller.repeat(),
                        target: pomodoroState.isRunning ? 1 : 0,
                      ).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.03, 1.03),
                        duration: 1.seconds,
                        curve: Curves.easeInOut,
                      ).then().scale(
                        begin: const Offset(1.03, 1.03),
                        end: const Offset(1, 1),
                        duration: 1.seconds,
                        curve: Curves.easeInOut,
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

                  // Ambient Sounds Selector (Rain, Forest, Campfire, Waves, White Noise)
                  _buildAmbientSoundsBar(context, ref),

                  // Session Status Message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          ],
        ),
      ],
    ),
        ),
      ),
    );
  }

  Future<void> _handleReset(BuildContext context, PomodoroNotifier notifier, bool isRunning) async {
    if (!isRunning) {
      notifier.resetTimer();
      return;
    }

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            const Text('🌱 ', style: TextStyle(fontSize: 22)),
            Text(
              'Ağacın Solmasın!',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Odaklanma seansını şimdi sıfırlarsan büyümekte olan ağacın kuruyacak. Emin misin?',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Vazgeç',
              style: GoogleFonts.inter(color: AppColors.softGreen, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralRed.withValues(alpha: 0.2),
              foregroundColor: AppColors.coralRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Ağacı Feda Et',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      notifier.resetTimer();
    }
  }

  Widget _buildCategorySelector(FocusCategory selectedCategory, PomodoroNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: FocusCategory.values.map((cat) {
            final isSelected = cat == selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.setCategory(cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? cat.color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? cat.color : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 12, color: isSelected ? cat.color : Colors.white60),
                      const SizedBox(width: 5),
                      Text(
                        cat.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCycleIndicator(PomodoroState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: List.generate(state.totalRounds, (index) {
              final roundNum = index + 1;
              final isPassed = roundNum < state.currentRound;
              final isCurrent = roundNum == state.currentRound;

              if (isCurrent) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: state.totalSeconds > 0 
                        ? (state.totalSeconds - state.remainingSeconds) / state.totalSeconds
                        : 0.0,
                    strokeWidth: 2.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    color: state.isBreak ? AppColors.softGreen : AppColors.neonPurple,
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed ? AppColors.softGreen : Colors.transparent,
                  border: Border.all(
                    color: isPassed ? AppColors.softGreen : Colors.white24,
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            state.isLongBreak
                ? '🎉 15 dk Uzun Mola!'
                : 'Döngü ${state.currentRound}/${state.totalRounds}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeTypeSelector(FocusTreeType currentType, bool isPro, PomodoroNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTreeChip(
            type: FocusTreeType.pine,
            label: '🌲 Çam',
            isProOnly: false,
            isPro: isPro,
            currentType: currentType,
            notifier: notifier,
          ),
          const SizedBox(width: 8),
          _buildTreeChip(
            type: FocusTreeType.sakura,
            label: '🌸 Sakura',
            isProOnly: true,
            isPro: isPro,
            currentType: currentType,
            notifier: notifier,
          ),
          const SizedBox(width: 8),
          _buildTreeChip(
            type: FocusTreeType.bonsai,
            label: '🪴 Bonsai',
            isProOnly: true,
            isPro: isPro,
            currentType: currentType,
            notifier: notifier,
          ),
        ],
      ),
    );
  }

  Widget _buildTreeChip({
    required FocusTreeType type,
    required String label,
    required bool isProOnly,
    required bool isPro,
    required FocusTreeType currentType,
    required PomodoroNotifier notifier,
  }) {
    final isSelected = currentType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (isProOnly && !isPro) {
          context.push(RoutePaths.paywall);
          return;
        }
        notifier.setTreeType(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softGreen.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.softGreen
                : (isProOnly && !isPro
                    ? AppColors.amber.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            if (isProOnly && !isPro) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: AppColors.amber),
                ),
              ),
            ],
          ],
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
    return PremiumCard(
      variant: PremiumCardVariant.standard,
      borderRadius: 999,
      width: 52,
      height: 52,
      onTap: onTap,
      child: Center(
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildAmbientSoundsBar(BuildContext context, WidgetRef ref) {
    final ambientState = ref.watch(ambientSoundProvider);
    final isPro = ref.watch(isProProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones_rounded, color: AppColors.iceBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                'Odaklanma Doğa Sesleri',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (ambientState.isPlaying)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(ambientSoundProvider.notifier).pause();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up_rounded, color: AppColors.iceBlue, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Çalıyor',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.iceBlue),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ambientTracks.map((track) {
                final isSelected = ambientState.activeTrackId == track.id;
                final isTrackPlaying = isSelected && ambientState.isPlaying;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (track.isPro && !isPro) {
                        context.push(RoutePaths.paywall);
                      } else {
                        ref.read(ambientSoundProvider.notifier).toggleTrack(track);
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final chip = PremiumCard(
                          variant: isTrackPlaying ? PremiumCardVariant.neonBorder : PremiumCardVariant.standard,
                          borderRadius: 16,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(track.icon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  track.name,
                                  style: AppTextStyles.bodyText.copyWith(
                                    fontSize: 12,
                                    fontWeight: isTrackPlaying ? FontWeight.bold : FontWeight.w500,
                                    color: isTrackPlaying ? Colors.white : Colors.white70,
                                  ),
                                ),
                                if (track.isPro && !isPro) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.amber),
                                    ),
                                  ),
                                ] else if (isTrackPlaying) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.graphic_eq_rounded, color: AppColors.iceBlue, size: 14),
                                ],
                              ],
                            ),
                          ),
                        );
                        return isTrackPlaying 
                            ? chip.animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.6, end: 1.0, duration: 1500.ms)
                            : chip;
                      }
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (ambientState.isPlaying) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.volume_down_rounded, color: Colors.white38, size: 16),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [AppColors.neonPurple, AppColors.iceBlue],
                          ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                          thumbColor: AppColors.iceBlue,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: ambientState.volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) {
                            ref.read(ambientSoundProvider.notifier).setVolume(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${(ambientState.volume * 100).round()}%',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _TimerRingPainter({required this.progress, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;
    final startAngle = -math.pi / 2;

    final isBreak = primaryColor == AppColors.softGreen;
    final colors = isBreak 
        ? [AppColors.softGreen, AppColors.amber] 
        : [AppColors.neonPurple, AppColors.iceBlue];

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      colors: colors,
      transform: const GradientRotation(-math.pi / 2),
    );

    final rect = Rect.fromCircle(center: center, radius: radius);

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    final dotX = center.dx + radius * math.cos(startAngle + sweepAngle);
    final dotY = center.dy + radius * math.sin(startAngle + sweepAngle);
    
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
    
    final dotGlowPaint = Paint()
      ..color = colors.last.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(dotX, dotY), 8, dotGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.primaryColor != primaryColor;
  }
}
