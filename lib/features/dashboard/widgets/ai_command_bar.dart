import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/gemini_provider.dart';

/// Glassmorphism command bar with search input, active mic, and camera shortcut buttons.
class AiCommandBar extends ConsumerStatefulWidget {
  const AiCommandBar({super.key});

  @override
  ConsumerState<AiCommandBar> createState() => _AiCommandBarState();
}

class _AiCommandBarState extends ConsumerState<AiCommandBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _submitCommand(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _controller.clear();
    _focusNode.unfocus();
    HapticFeedback.mediumImpact();

    // Send query to Gemini Chat & navigate to AI tab
    ref.read(geminiChatProvider.notifier).sendMessage(query);
    context.go('/ai-command');
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_controller.text.trim().isNotEmpty) {
        _submitCommand(_controller.text);
      }
    } else {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            if (_controller.text.trim().isNotEmpty) {
              _submitCommand(_controller.text);
            }
          }
        },
        onError: (_) {
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            localeId: 'tr_TR',
          ),
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon erişimi başlatılamadı.')),
          );
        }
      }
    }
  }

  void _openScanner() {
    HapticFeedback.lightImpact();
    context.push('/document_scanner');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isFocused || _isListening
            ? [
                BoxShadow(
                  color: (_isListening ? AppColors.softGreen : AppColors.neonPurple)
                      .withValues(alpha: 0.35),
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
              color: Colors.white.withValues(alpha: (_isFocused || _isListening) ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isListening
                    ? AppColors.softGreen
                    : (_isFocused
                        ? AppColors.neonPurple.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.12)),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: _isListening
                        ? AppColors.softGreen
                        : (_isFocused ? AppColors.neonPurple : AppColors.textSecondary),
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
                      hintText: _isListening
                          ? 'Dinleniyor... Konuşun'
                          : 'Belgeyi hesapla, zamanı planla, sor...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: _isListening
                            ? AppColors.softGreen
                            : AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: _submitCommand,
                  ),
                ),
                const SizedBox(width: 8),
                _ActionIcon(
                  icon: _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                  isActive: _isListening,
                  activeColor: AppColors.softGreen,
                  onTap: _toggleListening,
                ),
                const SizedBox(width: 8),
                _ActionIcon(
                  icon: Icons.camera_alt_rounded,
                  onTap: _openScanner,
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
  final bool isActive;
  final Color? activeColor;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isActive
        ? (activeColor ?? AppColors.neonPurple)
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? effectiveColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          border: isActive
              ? Border.all(color: effectiveColor.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Icon(icon, color: effectiveColor, size: 20),
      ),
    );
  }
}
