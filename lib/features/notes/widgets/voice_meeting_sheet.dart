import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/gemini_provider.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';
import 'package:omnibrain_ai/features/notes/providers/notes_providers.dart';

class VoiceMeetingSheet extends ConsumerStatefulWidget {
  const VoiceMeetingSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const VoiceMeetingSheet(),
    );
  }

  @override
  ConsumerState<VoiceMeetingSheet> createState() => _VoiceMeetingSheetState();
}

class _VoiceMeetingSheetState extends ConsumerState<VoiceMeetingSheet> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSummarizing = false;
  String _recognizedText = '';
  int _secondsRecorded = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni verilmedi.')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'notListening' || val == 'done') {
          if (_isListening && mounted) {
            // Keep listening until user explicitly stops
            _listenAgain();
          }
        }
      },
      onError: (val) {
        debugPrint('Speech error: $val');
      },
    );

    if (available && mounted) {
      setState(() {
        _isListening = true;
        _secondsRecorded = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isListening) {
          setState(() => _secondsRecorded++);
        }
      });

      _listenAgain();
    }
  }

  void _listenAgain() {
    _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      localeId: 'tr_TR',
      onResult: (result) {
        if (mounted) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        }
      },
    );
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _generateAiSummary() async {
    if (_recognizedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıtta henüz metin algılanmadı. Lütfen konuşun.')),
      );
      return;
    }

    await _stopRecording();
    setState(() => _isSummarizing = true);
    HapticFeedback.mediumImpact();

    try {
      final gemini = ref.read(geminiModelProvider);
      if (gemini == null) {
        throw Exception('Gemini AI modeli yüklenemedi.');
      }

      final prompt = '''
Sen dünya standartlarında uzman bir yönetici asistanısın. Aşağıdaki ses kaydı / konuşma metnini analiz et ve profesyonel, son derece düzenli bir toplantı notu ve eylem planı oluştur.

Format kuralları:
- İlk satırda # [Toplantı Başlığı] olsun.
- Altında 📝 Yönetici Özeti: 2-3 cümlelik net özet.
- Altında 🎯 Önemli Tartışma Maddeleri (madde imli).
- Altında ✅ Kararlar ve Eylem Planı (her biri '- [ ] [Görev/Sorumlu]' şeklinde yapılacaklar listesi olsun).

Konuşma Metni:
"$_recognizedText"
''';

      final response = await gemini.generateContent([Content.text(prompt)]);
      final summary = response.text ?? 'Özet oluşturulamadı.';

      // Save as Note
      await ref.read(notesProvider.notifier).addNote(
        summary,
        category: 'İş',
      );

      HapticFeedback.heavyImpact();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Toplantı AI ile özetlendi ve Notlarıma kaydedildi!'),
            backgroundColor: AppColors.softGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSummarizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Özetleme hatası: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsRecorded ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRecorded % 60).toString().padLeft(2, '0');
    final isPro = ref.watch(isProProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: 16,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: AppColors.deepNightBlue.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.iceBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_rounded, color: AppColors.iceBlue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesli Toplantı Kaydı',
                            style: GoogleFonts.montserrat(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Yapay Zekâ Eylem Planı Çıkarıcı',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPro ? AppColors.softGreen : AppColors.neonPurple).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (isPro ? AppColors.softGreen : AppColors.neonPurple).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      isPro ? 'PRO AKTİF' : 'PRO AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPro ? AppColors.softGreen : AppColors.iceBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recording Pulsing Circle & Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.coralRed.withValues(alpha: 0.15),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1200.ms),
                  GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? AppColors.coralRed : AppColors.iceBlue,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? AppColors.coralRed : AppColors.iceBlue).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                '$minutes:$seconds',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _isListening ? 'Kayıt yapılıyor, konuşun...' : 'Kayıt duraklatıldı',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _isListening ? AppColors.softGreen : Colors.white54,
                ),
              ),

              const SizedBox(height: 20),

              // Transcript Preview Box
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _recognizedText.isEmpty ? 'Sesiniz burada gerçek zamanlı yazıya dökülecek...' : _recognizedText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _recognizedText.isEmpty ? Colors.white30 : Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Summarize & Save Action Button
              if (_isSummarizing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.neonPurple),
                    SizedBox(height: 12),
                    Text('Yapay Zekâ Toplantıyı Özetliyor...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    shadowColor: AppColors.neonPurple.withValues(alpha: 0.4),
                    elevation: 10,
                  ),
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  label: const Text(
                    'Toplantıyı Özetle & Eylem Planı Çıkar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: _generateAiSummary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
