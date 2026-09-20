import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/premium_card.dart';

class SmartCalculatorScreen extends ConsumerStatefulWidget {
  const SmartCalculatorScreen({super.key});

  @override
  ConsumerState<SmartCalculatorScreen> createState() => _SmartCalculatorScreenState();
}

class _SmartCalculatorScreenState extends ConsumerState<SmartCalculatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  final List<Map<String, String>> _calculations = [];

  final List<String> _quickMathShortcuts = [
    "🧾 KDV Ekle",
    "🧾 KDV Çıkar",
    "📊 Yüzde Hesapla",
    "👥 Hesabı Böl",
    "💳 Kredi Taksiti",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _processCalculation(String expression) async {
    final query = expression.trim();
    if (query.isEmpty) return;

    _inputController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _calculations.add({'type': 'user', 'content': query});
    });
    _scrollToBottom();

    try {
      final aiRepo = ref.read(aiCommandRepositoryProvider);
      final answer = await aiRepo.processTextCalculation(query);

      setState(() {
        _calculations.add({'type': 'ai', 'content': answer});
        _isLoading = false;
      });
      _scrollToBottom();
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _calculations.add({'type': 'error', 'content': 'Hesaplanamadı: $e'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_inputController.text.isNotEmpty) {
        _processCalculation(_inputController.text);
      }
    } else {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;

      final available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_inputController.text.isNotEmpty) {
              _processCalculation(_inputController.text);
            }
          }
        },
        onError: (_) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.confirmation, localeId: 'tr_TR'),
          onResult: (val) {
            setState(() {
              _inputController.text = val.recognizedWords;
            });
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Akıllı Hesaplayıcı',
            style: AppTextStyles.pageTitle.copyWith(
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_calculations.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white54),
                tooltip: 'Temizle',
                onPressed: () {
                  setState(() => _calculations.clear());
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Shortcut chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickMathShortcuts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final label = _quickMathShortcuts[index];
                    bool isPressed = false;
                    return StatefulBuilder(
                      builder: (context, setChipState) {
                        return GestureDetector(
                          onTapDown: (_) => setChipState(() => isPressed = true),
                          onTapUp: (_) {
                            setChipState(() => isPressed = false);
                            HapticFeedback.selectionClick();
                            // Skip the emoji part for input
                            final inputLabel = label.split(' ').skip(1).join(' ');
                            _inputController.text = "$inputLabel: ";
                          },
                          onTapCancel: () => setChipState(() => isPressed = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.neonPurple.withValues(alpha: isPressed ? 0.3 : 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.neonPurple.withValues(alpha: isPressed ? 0.8 : 0.3)),
                              boxShadow: isPressed 
                                ? [BoxShadow(color: AppColors.neonPurple.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)]
                                : [],
                            ),
                            child: Text(
                              label,
                              style: AppTextStyles.caption.copyWith(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Chat / Calculation History Area
              Expanded(
                child: _calculations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Deneyin",
                                style: AppTextStyles.caption.copyWith(color: Colors.white60),
                              ),
                              const SizedBox(height: 16),
                              PremiumCard(
                                variant: PremiumCardVariant.standard,
                                onTap: () => _processCalculation("450 * 1.20"),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Text("🧮", style: TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("450 × 1.20 = ?", style: AppTextStyles.cardTitle),
                                        Text("KDV Hesapla", style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              PremiumCard(
                                variant: PremiumCardVariant.standard,
                                onTap: () => _processCalculation("%10 bahşiş hesapla"),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Text("💰", style: TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("%10 bahşiş hesapla", style: AppTextStyles.cardTitle),
                                        Text("Bahşiş & Paylaştır", style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              PremiumCard(
                                variant: PremiumCardVariant.standard,
                                onTap: () => _processCalculation("1500 / 3 kişi"),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Text("👥", style: TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("1500 ÷ 3 kişi", style: AppTextStyles.cardTitle),
                                        Text("Hesabı Böl", style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).animate().fadeIn(),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _calculations.length,
                        itemBuilder: (context, index) {
                          final item = _calculations[index];
                          final isUser = item['type'] == 'user';
                          final isError = item['type'] == 'error';

                          if (isUser) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12, left: 60),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonPurple.withValues(alpha: 0.15),
                                        border: Border(
                                          top: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                                        ),
                                      ),
                                      child: Text(
                                        item['content']!,
                                        style: AppTextStyles.bodyText.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return GestureDetector(
                            onLongPress: () {
                              if (!isError) {
                                Clipboard.setData(ClipboardData(text: item['content'] ?? ''));
                                HapticFeedback.mediumImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sonuç kopyalandı!'), duration: Duration(seconds: 1)),
                                );
                              }
                            },
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14, right: 40),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(18),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfacePrimary,
                                        border: Border(
                                          left: BorderSide(
                                            color: isError ? AppColors.coralRed.withValues(alpha: 0.5) : AppColors.iceBlue.withValues(alpha: 0.2),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isError ? Icons.error_outline : Icons.auto_awesome,
                                                color: isError ? AppColors.coralRed : AppColors.iceBlue,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isError ? "Hata" : "Sonuç",
                                                style: AppTextStyles.microText.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isError ? AppColors.coralRed : AppColors.iceBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item['content']!,
                                            style: AppTextStyles.bodyText.copyWith(
                                              height: 1.4,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: AppColors.neonPurple, strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text("Hesaplanıyor...", style: TextStyle(color: AppColors.neonPurple.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                ),

              // Bottom Math Command Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? AppColors.coralRed : AppColors.iceBlue,
                            ),
                            onPressed: _toggleListening,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              style: AppTextStyles.bodyText.copyWith(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: _isListening ? "Dinliyorum..." : "Formül veya soru yaz",
                                hintStyle: AppTextStyles.bodyText.copyWith(color: Colors.white38),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.2),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: _processCalculation,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _processCalculation(_inputController.text),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppColors.neonPurple, AppColors.iceBlue]),
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .boxShadow(
                                begin: const BoxShadow(color: Colors.transparent), 
                                end: BoxShadow(color: AppColors.neonPurple.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2), 
                                duration: 1500.ms
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
        ),
      ),
    );
  }
}
