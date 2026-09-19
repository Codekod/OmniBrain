import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/core/widgets/omnibrain_camera_view.dart';
import 'package:omnibrain_ai/features/ai_command/widgets/chat_bubble.dart';
import 'package:omnibrain_ai/core/models/chat_message.dart';
import 'package:omnibrain_ai/features/notes/providers/notes_providers.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';

class SmartCalculatorScreen extends ConsumerStatefulWidget {
  const SmartCalculatorScreen({super.key});

  @override
  ConsumerState<SmartCalculatorScreen> createState() => _SmartCalculatorScreenState();
}

class _SmartCalculatorScreenState extends ConsumerState<SmartCalculatorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isCameraOpen = false;

  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
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
            _chatHistory.add({'type': 'ai_receipt', 'data': parsedData});
          }
          _isLoading = false;
        });
      } catch (_) {
        // If not JSON, it's markdown text (e.g. math solution)
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
    HapticFeedback.lightImpact();
    setState(() => _isCameraOpen = true);
  }

  void _closeCamera() {
    setState(() => _isCameraOpen = false);
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        _processImage(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Galeriden görsel seçilemedi: $e')),
        );
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    _closeCamera();
    setState(() {
      _isLoading = true;
      _chatHistory.add({'type': 'user', 'text': '📷 Görsel analiz ediliyor...'});
    });
    _scrollToBottom();

    try {
      final aiRepo = ref.read(aiCommandRepositoryProvider);

      // 1. Direct Multimodal Gemini Vision (Best accuracy)
      final visionResult = await aiRepo.processImageCalculation(imagePath);
      final cleanResult = visionResult.replaceAll('```json', '').replaceAll('```', '').trim();

      try {
        final parsed = jsonDecode(cleanResult);
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('error')) {
            // If Vision couldn't read, try ML Kit OCR fallback
            await _runOcrFallback(imagePath);
            return;
          }
          setState(() {
            _chatHistory.add({'type': 'ai_receipt', 'data': parsed});
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      } catch (_) {
        // Returned markdown explanation (math problem solved from photo)
        setState(() {
          _chatHistory.add({'type': 'ai_text', 'text': visionResult});
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }
    } catch (_) {
      // If Gemini Vision fails (e.g. network), fallback to ML Kit OCR
      await _runOcrFallback(imagePath);
    }
  }

  Future<void> _runOcrFallback(String imagePath) async {
    try {
      final ocrRepo = ref.read(ocrRepositoryProvider);
      final rawText = await ocrRepo.processImage(imagePath);

      if (rawText.isEmpty || rawText.startsWith('Metin okunamadı')) {
        throw Exception('Görselde okunabilir bir metin bulunamadı. Lütfen daha net ve aydınlık bir fotoğraf çekin.');
      }

      await _processMessage(rawText, displayUserMessage: '📷 Belge metni çözümlendi.');
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
    HapticFeedback.lightImpact();
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _processMessage(_textController.text);
      }
    } else {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni gerekli')),
          );
        }
        return;
      }

      final available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_textController.text.isNotEmpty) {
              _processMessage(_textController.text);
            }
          }
        },
        onError: (_) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
          ),
          localeId: 'tr_TR',
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
        );
      }
    }
  }

  void _saveReceiptToNotes(Map<String, dynamic> data) {
    HapticFeedback.lightImpact();
    final merchant = data['merchant'] ?? 'Harcama Fişi';
    final total = data['totalExpense'] ?? data['balance'] ?? 0;
    final dateStr = data['date'] != null && data['date'].toString().isNotEmpty
        ? data['date']
        : DateFormat('dd.MM.yyyy').format(DateTime.now());

    final items = data['items'] as List<dynamic>? ?? [];
    final itemsSummary = items.map((i) => "- ${i['label']}: ${i['amount']} ₺").join("\n");

    final noteText = "$merchant ($dateStr)\nToplam: $total ₺\n$itemsSummary";

    ref.read(notesProvider.notifier).addNote(noteText, category: 'Finans');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.softGreen, size: 20),
            SizedBox(width: 8),
            Text('Fiş [Finans] notlarınıza kaydedildi!'),
          ],
        ),
        backgroundColor: AppColors.darkNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Akıllı Hesaplayıcı & OCR',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: AppColors.iceBlue),
              tooltip: 'Galeriden Fiş Seç',
              onPressed: _pickFromGallery,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.iceBlue),
              tooltip: 'Kamera ile Tara',
              onPressed: _openCamera,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _chatHistory.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.neonPurple.withValues(alpha: 0.25),
                                    AppColors.iceBlue.withValues(alpha: 0.25),
                                  ],
                                ),
                                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
                              ),
                              child: const Icon(
                                Icons.document_scanner_rounded,
                                size: 52,
                                color: AppColors.iceBlue,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Fiş Tara veya Soru Sor",
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Kamerayı açarak bir market fişi veya fatura tara;\nkalem kalem harcamalarını, KDV'yi ve toplamı hesaplayalım.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.neonPurple,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                                  label: const Text('Kamera ile Tara', style: TextStyle(color: Colors.white)),
                                  onPressed: _openCamera,
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: const Icon(Icons.photo_library_rounded, color: AppColors.iceBlue, size: 20),
                                  label: const Text('Galeriden Seç', style: TextStyle(color: Colors.white)),
                                  onPressed: _pickFromGallery,
                                ),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(),
                      ),
                    )
                  : ListView.builder(
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
                          return ChatBubble(
                            message: ChatMessage(
                              id: DateTime.now().toString(),
                              role: MessageRole.ai,
                              text: item['text'],
                            ),
                          );
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
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5), width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
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
          color: AppColors.coralRed.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.coralRed.withValues(alpha: 0.5)),
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
    final merchant = data['merchant'] as String?;
    final date = data['date'] as String?;
    final tax = data['tax'];
    final items = data['items'] as List<dynamic>? ?? [];
    final totalExpense = data['totalExpense'] ?? 0;
    final totalIncome = data['totalIncome'] ?? 0;
    final balance = data['balance'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24, right: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 1,
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Merchant & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.iceBlue, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    merchant != null && merchant.isNotEmpty ? merchant : 'Hesap Özeti',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (date != null && date.isNotEmpty)
                Text(
                  date,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Items List
          if (items.isNotEmpty) ...[
            ...items.map((item) {
              final isIncome = item['type'] == 'income';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['label'] ?? '',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}${item['amount']} ₺',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isIncome ? AppColors.softGreen : AppColors.coralRed,
                        fontWeight: FontWeight.w600,
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

          if (tax != null && tax != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('KDV / Vergi', style: GoogleFonts.inter(fontSize: 13, color: Colors.white60)),
                  Text('$tax ₺', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),

          _buildSummaryRow('Toplam Gelir', totalIncome, AppColors.softGreen),
          _buildSummaryRow('Toplam Gider', totalExpense, AppColors.coralRed),
          const SizedBox(height: 12),

          // Balance Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: balance >= 0
                  ? AppColors.softGreen.withValues(alpha: 0.12)
                  : AppColors.coralRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: balance >= 0
                    ? AppColors.softGreen.withValues(alpha: 0.35)
                    : AppColors.coralRed.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Genel Toplam',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${balance > 0 ? '+' : ''}$balance ₺',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? AppColors.softGreen : AppColors.coralRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Save to Notes & Copy
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppColors.neonPurple.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18, color: AppColors.iceBlue),
                  label: const Text('Notlarıma Kaydet', style: TextStyle(fontSize: 13)),
                  onPressed: () => _saveReceiptToNotes(data),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                tooltip: 'Kopyala',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final summary = "Fiş: ${merchant ?? ''}\nToplam: $totalExpense ₺\nBakiye: $balance ₺";
                  Clipboard.setData(ClipboardData(text: summary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hesap özeti kopyalandı!'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
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
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
          Text('$amount ₺', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
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
      child: Row(
        children: [
          // Gallery Button
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.photo_library_rounded, color: AppColors.iceBlue, size: 22),
            ),
          ),
          const SizedBox(width: 8),

          // Camera Button
          GestureDetector(
            onTap: _openCamera,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),

          // Text Field
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isListening ? "Dinliyorum..." : "Yaz, sor veya fiş tara...",
                hintStyle: TextStyle(
                  color: _isListening ? AppColors.coralRed : Colors.white38,
                  fontSize: 14,
                ),
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
              onSubmitted: (val) => _processMessage(val),
            ),
          ),
          const SizedBox(width: 8),

          // Mic Button
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppColors.coralRed.withValues(alpha: 0.2) : Colors.transparent,
                border: Border.all(
                  color: _isListening ? AppColors.coralRed : Colors.white24,
                ),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? AppColors.coralRed : Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Send Button
          GestureDetector(
            onTap: () {
              if (_textController.text.isNotEmpty) {
                _processMessage(_textController.text);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.neonPurple, AppColors.iceBlue],
                ),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
