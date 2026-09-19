import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';

class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  final TextEditingController _textController = TextEditingController();
  
  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // AI'dan Dönen Değerler
  String _originalValue = "0";
  String _originalUnit = "Birim";
  String _convertedValue = "0";
  String _convertedUnit = "Birim";
  String _message = "Akıllı dönüştürme için konuşun veya yazın.";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _processConversion(_textController.text);
      }
    } else {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni gerekli')),
        );
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') {
            setState(() => _isListening = false);
            if (_textController.text.isNotEmpty) {
              _processConversion(_textController.text);
            }
          }
        },
        onError: (val) => print('onError: $val'),
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
          localeId: 'tr_TR',
        );
      }
    }
  }

  Future<void> _processConversion(String message) async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    final query = message.trim();
    if (query.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final aiRepo = ref.read(aiCommandRepositoryProvider);
      final responseStr = await aiRepo.processConversion(query);
      
      final cleanJson = responseStr.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanJson);

      setState(() {
        _originalValue = data['originalValue']?.toString() ?? "0";
        _originalUnit = data['originalUnit']?.toString() ?? "Birim";
        _convertedValue = data['convertedValue']?.toString() ?? "0";
        _convertedUnit = data['convertedUnit']?.toString() ?? "Birim";
        _message = data['message']?.toString() ?? "Hesaplandı.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = "Sistemsel bir hata oluştu: $e";
        _isLoading = false;
      });
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
          title: const Text('Evrensel Çevirici'),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    _buildValueCard(_originalValue, _originalUnit, true),
                    const SizedBox(height: 24),
                    
                    // Ortadaki Ok İkonu
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.deepNightBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 28, 
                              height: 28, 
                              child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)
                            )
                          : const Icon(Icons.swap_vert_rounded, color: AppColors.amber, size: 28)
                              .animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: const Duration(seconds: 2), color: Colors.white),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildValueCard(_convertedValue, _convertedUnit, false),
                    const SizedBox(height: 32),
                    
                    // AI Mesajı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.amber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message,
                              style: AppTextStyles.bodyText.copyWith(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ).animate(key: ValueKey(_message)).fadeIn(),
                  ],
                ),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard(String value, String unit, bool isOriginal) {
    return Container(
      key: ValueKey("$value$unit"),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isOriginal ? AppColors.cardBorder : AppColors.amber.withOpacity(0.5),
          width: isOriginal ? 1 : 2,
        ),
        boxShadow: isOriginal ? [] : [
          BoxShadow(
            color: AppColors.amber.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ]
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isOriginal ? Colors.white10 : AppColors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              unit.toUpperCase(),
              style: TextStyle(
                color: isOriginal ? Colors.white70 : AppColors.amber,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepNightBlue.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          // Mikrofon Butonu
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppColors.coralRed.withOpacity(0.2) : Colors.transparent,
                border: Border.all(
                  color: _isListening ? AppColors.coralRed : Colors.white24,
                ),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? AppColors.coralRed : Colors.white,
                size: 24,
              ),
            ),
          ),
          if (_isListening) const SizedBox(width: 8) else const SizedBox(width: 12),
          
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isListening ? "Dinliyorum..." : "Ne çevirmek istiyorsun?",
                hintStyle: TextStyle(color: _isListening ? AppColors.coralRed : Colors.white38),
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
                  borderSide: BorderSide(color: AppColors.amber.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _processConversion,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_textController.text.isNotEmpty) {
                _processConversion(_textController.text);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: const Icon(Icons.send, color: AppColors.deepNightBlue, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
