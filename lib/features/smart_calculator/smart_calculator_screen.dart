import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';

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
    "%20 KDV Ekle",
    "%20 KDV Çıkar",
    "Yüzde Hesapla",
    "Hesabı 4 Kişiye Böl",
    "Kredi Aylık Taksiti",
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
          listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.confirmation),
          localeId: 'tr_TR',
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
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _inputController.text = "$label: ";
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
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
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.neonPurple.withValues(alpha: 0.2),
                                  border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
                                ),
                                child: const Icon(
                                  Icons.calculate_rounded,
                                  size: 50,
                                  color: AppColors.neonPurple,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Matematik & Akıllı Hesaplama",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "İster formül yaz (450 * 1.20), ister doğal dille sor;\n'1500 liralık yemeğin %10 bahşişi ve 3 kişiye payı ne kadar?'",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.neonPurple.withValues(alpha: 0.25),
                                  border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5)),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  item['content']!,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14, right: 40),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isError
                                    ? AppColors.coralRed.withValues(alpha: 0.15)
                                    : AppColors.darkNavy,
                                border: Border.all(
                                  color: isError
                                      ? AppColors.coralRed.withValues(alpha: 0.4)
                                      : AppColors.iceBlue.withValues(alpha: 0.3),
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(18),
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
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isError ? AppColors.coralRed : AppColors.iceBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['content']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.deepNightBlue,
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
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
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _isListening ? "Dinliyorum..." : "Formül veya soru yaz (Örn: 1500 * 0.18)",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.darkNavy,
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
