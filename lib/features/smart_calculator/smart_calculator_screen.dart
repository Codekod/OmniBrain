import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/widgets/omnibrain_camera_view.dart';
import 'package:omnibrain_ai/features/ai_command/widgets/chat_bubble.dart';
import 'package:omnibrain_ai/core/models/chat_message.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';

class SmartCalculatorScreen extends ConsumerStatefulWidget {
  const SmartCalculatorScreen({super.key});

  @override
  ConsumerState<SmartCalculatorScreen> createState() => _SmartCalculatorScreenState();
}

class _SmartCalculatorScreenState extends ConsumerState<SmartCalculatorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _chatHistory = [];
  Map<String, dynamic>? _lastParsedData;
  bool _isCameraOpen = false;

  // Sesli Komut Değişkenleri
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _processMessage(String message, {String? displayUserMessage}) async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
    
    if (message.trim().isEmpty) return;
    
    final userMessage = message;
    _textController.clear();
    FocusScope.of(context).unfocus();
    
    setState(() {
      _chatHistory.add({'type': 'user', 'text': displayUserMessage ?? userMessage});
      _isLoading = true;
    });
    
    _scrollToBottom();

    try {
      final aiRepo = ref.read(aiCommandRepositoryProvider);
      final responseJson = await aiRepo.processTextCalculation(userMessage);
      
      try {
        final cleanJson = responseJson.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsedData = jsonDecode(cleanJson);

        setState(() {
          if (parsedData.containsKey('error')) {
            _chatHistory.add({'type': 'ai_error', 'text': parsedData['error']});
          } else {
            _lastParsedData = parsedData;
            _chatHistory.add({'type': 'ai_receipt', 'data': parsedData});
          }
          _isLoading = false;
        });
      } catch (e) {
        // Eğer JSON değilse düz metin yanıtıdır (Örn. Matematik çözümü)
        setState(() {
          _chatHistory.add({'type': 'ai_text', 'text': responseJson});
          _isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _chatHistory.add({'type': 'ai_error', 'text': 'Sistemsel bir hata oluştu: $e'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _openCamera() {
    setState(() {
      _isCameraOpen = true;
    });
  }

  void _closeCamera() {
    setState(() {
      _isCameraOpen = false;
    });
  }

  Future<void> _processImage(String imagePath) async {
    _closeCamera();
    setState(() {
      _isLoading = true;
      _chatHistory.add({'type': 'user', 'text': '📷 Görsel tarandı. Çözümleniyor...'});
    });
    _scrollToBottom();

    try {
      final ocrRepo = ref.read(ocrRepositoryProvider);
      final rawText = await ocrRepo.processImage(imagePath);

      if (rawText.isEmpty || rawText.startsWith('Metin okunamadı')) {
        throw Exception('Metin bulunamadı. Lütfen daha net bir fotoğraf çekin.');
      }
      
      // Çıkan metni arkada Gemini'a gönder, ekranda kocaman OCR metni görünmesin
      _processMessage(rawText, displayUserMessage: '📷 Görsel analiz ediliyor...');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chatHistory.add({'type': 'ai_error', 'text': 'Tarama hatası: $e'});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _processMessage(_textController.text);
      }
    } else {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni gerekli')),
          );
        }
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') {
            setState(() => _isListening = false);
            if (_textController.text.isNotEmpty) {
              _processMessage(_textController.text);
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

  @override
  Widget build(BuildContext context) {
    if (_isCameraOpen) {
      return OmniBrainCameraView(
        onImageCaptured: _processImage,
        onCancel: _closeCamera,
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Akıllı Hesapla'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final item = _chatHistory[index];
                  if (item['type'] == 'user') {
                    return _buildUserBubble(item['text']);
                  } else if (item['type'] == 'ai_receipt') {
                    return _buildReceiptCard(item['data']);
                  } else if (item['type'] == 'ai_text') {
                    return ChatBubble(message: ChatMessage(id: DateTime.now().toString(), role: MessageRole.ai, text: item['text']));
                  } else {
                    return _buildErrorBubble(item['text']);
                  }
                },
              ),
            ),
            if (_isLoading) _buildLoadingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Shimmer.fromColors(
          baseColor: AppColors.neonPurple,
          highlightColor: AppColors.iceBlue,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Yapay zeka analiz ediyor...',
                style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground, // Daha soft ve okunaklı
          border: Border.all(color: AppColors.neonPurple.withOpacity(0.5), width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonPurple.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    ).animate().slideX(begin: 0.2, end: 0).fadeIn();
  }

  Widget _buildErrorBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.coralRed.withOpacity(0.15),
          border: Border.all(color: AppColors.coralRed.withOpacity(0.5)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Text(text, style: const TextStyle(color: AppColors.coralRed, fontSize: 14)),
      ),
    ).animate().slideX(begin: -0.2, end: 0).fadeIn();
  }

  Widget _buildReceiptCard(Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>? ?? [];
    final totalExpense = data['totalExpense'] ?? 0;
    final totalIncome = data['totalIncome'] ?? 0;
    final balance = data['balance'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24, right: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.iceBlue),
              const SizedBox(width: 8),
              Text('Hesap Özeti', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isNotEmpty) ...[
            ...items.map((item) {
              final isIncome = item['type'] == 'income';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['label'] ?? '',
                        style: AppTextStyles.bodyText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}${item['amount']} ₺',
                      style: AppTextStyles.bodyText.copyWith(
                        color: isIncome ? AppColors.softGreen : AppColors.coralRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(color: Colors.white24),
            ),
          ],
          _buildSummaryRow('Toplam Gelir', totalIncome, AppColors.softGreen),
          _buildSummaryRow('Toplam Gider', totalExpense, AppColors.coralRed),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: balance >= 0 ? AppColors.softGreen.withOpacity(0.1) : AppColors.coralRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: balance >= 0 ? AppColors.softGreen.withOpacity(0.3) : AppColors.coralRed.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kalan Bakiye', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '${balance > 0 ? '+' : ''}$balance ₺',
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? AppColors.softGreen : AppColors.coralRed,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 100.ms).fadeIn();
  }

  Widget _buildSummaryRow(String label, dynamic amount, Color color) {
    if (amount == 0 || amount == 0.0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyText.copyWith(color: Colors.white70)),
          Text('$amount ₺', style: AppTextStyles.bodyText.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      // Uyumsuz gri/beyaz renk kalktı, tamamen transparan veya derin koyu renk yapıldı
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
          // Kamera Butonu
          GestureDetector(
            onTap: _openCamera,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.iceBlue.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.camera_alt, color: AppColors.iceBlue, size: 24),
            ),
          ),
          const SizedBox(width: 8),
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
          if (_isListening)
            const SizedBox(width: 8)
          else
            const SizedBox(width: 12),
          // Metin Kutusu
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isListening ? "Dinliyorum..." : "Bir hesaplama yazın...",
                hintStyle: TextStyle(color: _isListening ? AppColors.coralRed : Colors.white38),
                filled: true,
                fillColor: AppColors.darkNavy, // Daha premium koyu gri/lacivert
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
                  borderSide: BorderSide(color: AppColors.neonPurple.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _processMessage,
            ),
          ),
          const SizedBox(width: 8),
          // Gönder Butonu
          GestureDetector(
            onTap: () {
              if (_textController.text.isNotEmpty) {
                _processMessage(_textController.text);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.neonPurple, AppColors.iceBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPurple.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
