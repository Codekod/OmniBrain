import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/providers/gemini_provider.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';
import 'package:omnibrain_ai/core/providers/usage_limit_provider.dart';
import 'package:omnibrain_ai/features/ai_command/widgets/chat_bubble.dart';

class AiCommandScreen extends ConsumerStatefulWidget {
  const AiCommandScreen({super.key});

  @override
  ConsumerState<AiCommandScreen> createState() => _AiCommandScreenState();
}

class _AiCommandScreenState extends ConsumerState<AiCommandScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    _controller.clear();
    FocusScope.of(context).unfocus(); // Close keyboard

    final success = await ref.read(geminiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
    
    if (!success) {
      if (mounted) {
        // Assume limit reached if success is false but text was valid
        context.push(RoutePaths.paywall);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(geminiChatProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OmniBrain Asistan',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Consumer(
                builder: (context, ref, _) {
                  final isPro = ref.watch(revenueCatProvider).isPro;
                  final usage = ref.watch(usageLimitProvider);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPro ? AppColors.amber.withValues(alpha: 0.2) : Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isPro ? AppColors.amber : Colors.white24,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isPro ? "PRO • Sınırsız" : "Günlük Kalan Hak: ${usage.remainingCredits}/5",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPro ? AppColors.amber : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            if (chatState.messages.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                onPressed: () {
                  ref.read(geminiChatProvider.notifier).clearChat();
                },
                tooltip: "Sohbeti Temizle",
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: chatState.messages.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(chatState),
            ),
            _buildInputArea(chatState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.neonPurple, AppColors.iceBlue],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPurple.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(
            "Nasıl yardımcı olabilirim?",
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 48),
          
          // Suggestion Chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip("Özetle", Icons.short_text, AppColors.neonPurple),
              _buildSuggestionChip("Çevir", Icons.swap_vert, AppColors.amber),
              _buildSuggestionChip("Kod Yaz", Icons.code, AppColors.iceBlue),
              _buildSuggestionChip("Fikir Üret", Icons.lightbulb, AppColors.coralRed),
            ],
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        _controller.text = "Lütfen bana şu konuda yardımcı ol: $label ";
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(ChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        return ChatBubble(message: message).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildInputArea(bool isLoading) {
    final remaining = ref.watch(geminiChatProvider.notifier).remainingFreeMessages;
    final isPro = remaining > 100; // Just a quick check for PRO

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final bottomPad = isKeyboardOpen ? 12.0 : (MediaQuery.of(context).padding.bottom + 84.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: bottomPad,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepNightBlue.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "Kalan Ücretsiz Mesaj: $remaining",
                style: GoogleFonts.inter(fontSize: 12, color: remaining == 0 ? AppColors.coralRed : Colors.white54),
              ),
            ),
          Row(
            children: [
              // Metin Kutusu
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendMessage(),
                  decoration: InputDecoration(
                    hintText: "OmniBrain ile sohbet et...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.darkNavy,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.neonPurple.withValues(alpha: 0.5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Gönder Butonu
              GestureDetector(
                onTap: isLoading ? null : _handleSendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLoading ? Colors.white24 : AppColors.neonPurple,
                  ),
                  child: isLoading 
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : const Icon(Icons.arrow_upward, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
