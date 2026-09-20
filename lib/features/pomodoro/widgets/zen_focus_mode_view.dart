import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/services/ambient_sound_service.dart';
import 'package:omnibrain_ai/features/pomodoro/providers/pomodoro_providers.dart';
import 'package:omnibrain_ai/features/pomodoro/widgets/focus_tree_view.dart';

class ZenFocusModeView extends ConsumerStatefulWidget {
  const ZenFocusModeView({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, _, _) => const ZenFocusModeView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<ZenFocusModeView> createState() => _ZenFocusModeViewState();
}

class _ZenFocusModeViewState extends ConsumerState<ZenFocusModeView> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Hide controls after 3 seconds for complete immersion
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final ambientState = ref.watch(ambientSoundProvider);

    final minutes = (pomodoroState.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (pomodoroState.remainingSeconds % 60).toString().padLeft(2, '0');
    final primaryColor = pomodoroState.isBreak ? AppColors.softGreen : AppColors.neonPurple;

    return Scaffold(
      backgroundColor: Colors.black, // Pure OLED black
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle background glow
              Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: pomodoroState.isRunning ? 0.08 : 0.03),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Main Zen Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category & Round Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pomodoroState.selectedCategory.icon,
                            size: 14,
                            color: pomodoroState.selectedCategory.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pomodoroState.selectedCategory.label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            'Döngü ${pomodoroState.currentRound}/${pomodoroState.totalRounds}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Growing Tree Preview
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: FocusTreeView(
                        progress: pomodoroState.totalSeconds > 0
                            ? (pomodoroState.totalSeconds - pomodoroState.remainingSeconds) / pomodoroState.totalSeconds
                            : 0.0,
                        isRunning: pomodoroState.isRunning,
                        isBreak: pomodoroState.isBreak,
                        treeType: pomodoroState.selectedTreeType,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Massive Breathing Digital Timer
                    Text(
                      '$minutes:$seconds',
                      style: GoogleFonts.montserrat(
                        fontSize: 84,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        letterSpacing: -3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Zen status message
                    Text(
                      pomodoroState.isRunning
                          ? (pomodoroState.isBreak ? 'Mola Vakti • Derin Nefes Al' : 'Derin Odak • Bildirimler Sessizde')
                          : 'DURAKLATILDI',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: pomodoroState.isRunning ? primaryColor : Colors.white38,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Zen Mode Controls (revealed on tap or toggle)
                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 28),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                notifier.resetTimer();
                              },
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                notifier.toggleTimer();
                              },
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.4),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  pomodoroState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white54, size: 28),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                notifier.skipSession();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Top Bar (Exit Zen Mode & Sound Indicator)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: _showControls ? 16 : -60,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Çıkış',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (ambientState.isPlaying)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.headphones_rounded, color: AppColors.iceBlue, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Ses Aktif',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.iceBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Tap hint at the bottom
              if (!_showControls)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Kontroller için ekrana dokun',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
