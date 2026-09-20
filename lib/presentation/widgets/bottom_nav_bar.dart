import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omnibrain_ai/l10n/app_localizations.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/presentation/providers/navigation_provider.dart';

/// Custom bottom navigation bar with glassmorphism styling.
class OmniBrainBottomNav extends ConsumerWidget {
  final ValueChanged<int>? onTabChanged;

  const OmniBrainBottomNav({super.key, this.onTabChanged});

  List<_NavItem> _getItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _NavItem(icon: Icons.home_rounded, label: l10n.tabDashboard),
      _NavItem(icon: Icons.grid_view_rounded, label: l10n.tabTools),
      _NavItem(icon: Icons.auto_awesome, label: 'Brain'),
      _NavItem(icon: Icons.note_alt_rounded, label: l10n.tabNotes),
      _NavItem(icon: Icons.person_rounded, label: l10n.tabProfile),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);
    final items = _getItems(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = index == currentIndex;
                final isBrain = index == 2;

                if (isBrain) {
                  return _BrainButton(
                    isActive: isActive,
                    onTap: () => _onTap(ref, index),
                  );
                }

                return _NavBarItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => _onTap(ref, index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(WidgetRef ref, int index) {
    HapticFeedback.lightImpact();
    ref.read(currentTabIndexProvider.notifier).state = index;
    onTabChanged?.call(index);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Icon(
                item.icon,
                size: isActive ? 26 : 24,
                color: isActive
                    ? AppColors.neonPurple
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.neonPurple
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              width: isActive ? 24 : 0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.neonPurple, AppColors.iceBlue],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrainButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _BrainButton({required this.isActive, required this.onTap});

  @override
  State<_BrainButton> createState() => _BrainButtonState();
}

class _BrainButtonState extends State<_BrainButton> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9B30FF),
              AppColors.neonPurple,
              Color(0xFF6A1FB5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonPurple.withValues(alpha: 0.5),
              blurRadius: widget.isActive ? 18 : 10,
              spreadRadius: widget.isActive ? 2 : 0,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final value = _shimmerController.value;
            // Shimmer happens in the first 25% of the 8-second animation (2 seconds)
            final shimmerValue = (value < 0.25) ? (value / 0.25) : 1.0;
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-2.0 + (shimmerValue * 4), 0),
                  end: Alignment(-1.0 + (shimmerValue * 4), 0),
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    Colors.white,
                    Colors.white.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: child,
            );
          },
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
