import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/presentation/providers/navigation_provider.dart';

/// Glassmorphism command bar with search input, mic, and camera buttons.
class AiCommandBar extends ConsumerStatefulWidget {
  const AiCommandBar({super.key});

  @override
  ConsumerState<AiCommandBar> createState() => _AiCommandBarState();
}

class _AiCommandBarState extends ConsumerState<AiCommandBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.neonPurple.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _isFocused ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFocused
                    ? AppColors.neonPurple.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: _isFocused
                        ? AppColors.neonPurple
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Belgeyi hesapla, zamanı planla, notu özetle...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) {
                      HapticFeedback.mediumImpact();
                      // Navigate to AI command tab
                      ref.read(currentTabIndexProvider.notifier).state = 2;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _ActionIcon(
                  icon: Icons.mic_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                ),
                const SizedBox(width: 8),
                _ActionIcon(
                  icon: Icons.camera_alt_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}
