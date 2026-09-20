import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/streak_provider.dart';
import 'package:omnibrain_ai/features/pomodoro/providers/pomodoro_providers.dart';
import 'package:omnibrain_ai/features/pomodoro/widgets/focus_tree_view.dart';

class ForestGardenSheet extends ConsumerWidget {
  const ForestGardenSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ForestGardenSheet(),
    );
  }

  void _shareGarden(BuildContext context, PomodoroState state, int streakDays) {
    HapticFeedback.mediumImpact();
    final treeCount = state.grownTreesToday.length;
    final minutes = state.todayFocusMinutes;

    final treeEmojis = state.grownTreesToday.map((t) {
      switch (t.treeType) {
        case FocusTreeType.pine:
          return '🌲';
        case FocusTreeType.sakura:
          return '🌸';
        case FocusTreeType.bonsai:
          return '🪴';
      }
    }).join(' ');

    final text = '''
🌲 Bugünkü OmniBrain Odak Ormanım:
⏱️ Toplam Odak: $minutes dakika
🌳 Büyütülen Ağaç: $treeCount adet
🔥 Günlük Seri: $streakDays gün
${treeEmojis.isNotEmpty ? 'Ormanım: $treeEmojis\n' : ''}
Odaklanmanı zirveye taşımak için sen de katıl! #OmniBrain #Pomodoro #Focus
''';

    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'OmniBrain Odak Ormanım',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final streakState = ref.watch(streakProvider);
    final streakDays = streakState.currentStreak;
    final trees = pomodoroState.grownTreesToday;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.softGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.park_rounded, color: AppColors.softGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugünkü Odak Ormanım',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Top Stat Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatCard(
                  title: 'Toplam Odak',
                  value: '${pomodoroState.todayFocusMinutes}',
                  unit: 'dk',
                  icon: Icons.timer_outlined,
                  color: AppColors.iceBlue,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: 'Yetişen Ağaç',
                  value: '${trees.length}',
                  unit: 'adet',
                  icon: Icons.forest_rounded,
                  color: AppColors.softGreen,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: 'Günlük Seri',
                  value: '$streakDays',
                  unit: 'gün',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.amber,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Main Garden Grid or Empty State
          Expanded(
            child: trees.isEmpty
                ? _buildEmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: trees.length,
                      itemBuilder: (context, index) {
                        final tree = trees[index];
                        return _buildTreeCard(tree);
                      },
                    ),
                  ),
          ),

          // Share Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E17),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softGreen,
                      foregroundColor: const Color(0xFF0A0E17),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF0A0E17)),
                    label: Text(
                      'Ormanımı Paylaş',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _shareGarden(context, pomodoroState, streakDays),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeCard(GrownTree tree) {
    String typeName;
    switch (tree.treeType) {
      case FocusTreeType.pine:
        typeName = 'Çam Ağacı';
        break;
      case FocusTreeType.sakura:
        typeName = 'Sakura Ağacı';
        break;
      case FocusTreeType.bonsai:
        typeName = 'Bonsai';
        break;
    }

    final timeStr = DateFormat('HH:mm').format(tree.completedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual tree render
          SizedBox(
            width: 76,
            height: 76,
            child: FocusTreeView(
              progress: 1.0,
              isRunning: false,
              isBreak: false,
              treeType: tree.treeType,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            typeName,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tree.category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tree.category.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tree.category.icon, size: 10, color: tree.category.color),
                const SizedBox(width: 4),
                Text(
                  tree.category.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tree.category.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_rounded, size: 11, color: Colors.white38),
              const SizedBox(width: 3),
              Text(
                '$timeStr • ${tree.focusMinutes} dk',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softGreen.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.softGreen.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.softGreen, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Ormanın Henüz Boş',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk odaklanma seansını tamamladığında burada yemyeşil bir ağaç büyüyecek!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
