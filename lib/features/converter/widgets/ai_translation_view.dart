import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/gemini_provider.dart';
import 'package:omnibrain_ai/features/converter/services/ai_translation_service.dart';

class AiTranslationView extends ConsumerStatefulWidget {
  const AiTranslationView({super.key});

  @override
  ConsumerState<AiTranslationView> createState() => _AiTranslationViewState();
}

class _AiTranslationViewState extends ConsumerState<AiTranslationView> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late stt.SpeechToText _speech;

  String _sourceLanguage = 'Otomatik Algıla';
  String _targetLanguage = 'İngilizce';
  TranslationTone _selectedTone = TranslationTone.natural;

  bool _isLoading = false;
  bool _isListening = false;
  AiTranslationResult? _currentResult;
  List<AiTranslationResult> _history = [];

  final List<String> _languages = [
    'Otomatik Algıla',
    'Türkçe',
    'İngilizce',
    'Almanca',
    'Fransızca',
    'İspanyolca',
    'İtalyanca',
    'Rusça',
    'Arapça',
    'Japonca',
    'Çince',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await AiTranslationService.getHistory();
    if (mounted) {
      setState(() => _history = history);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _swapLanguages() {
    HapticFeedback.lightImpact();
    if (_sourceLanguage == 'Otomatik Algıla') return;
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;

      if (_currentResult != null) {
        _textController.text = _currentResult!.translatedText;
        _currentResult = null;
      }
    });
    if (_textController.text.trim().isNotEmpty) {
      _executeTranslation();
    }
  }

  Future<void> _executeTranslation() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final gemini = ref.read(geminiModelProvider);
      if (gemini == null) {
        throw Exception('Gemini AI modeli yüklenemedi. Lütfen internet bağlantını kontrol et.');
      }

      final result = await AiTranslationService.translate(
        gemini: gemini,
        text: text,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        tone: _selectedTone,
      );

      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {
          _currentResult = result;
          _isLoading = false;
        });
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çeviri hatası: $e'),
            backgroundColor: AppColors.coralRed,
          ),
        );
      }
    }
  }

  Future<void> _pickImageAndOcr(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extracted = recognizedText.text.trim();
      if (extracted.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Görselde okunabilir metin bulunamadı.')),
          );
        }
        return;
      }

      setState(() {
        _textController.text = extracted;
      });

      await _executeTranslation();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera/OCR hatası: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kamera ile Çevir (OCR)',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.iceBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.iceBlue),
                ),
                title: const Text('Fotoğraf Çek', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Tabela, menü veya doküman fotoğrafı çek', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageAndOcr(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.neonPurple),
                ),
                title: const Text('Galeriden Seç', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Daha önce çektiğin ekran görüntüsü veya fotoğraf', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageAndOcr(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSpeech() async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      setState(() => _isListening = false);
      await _speech.stop();
      if (_textController.text.trim().isNotEmpty) {
        _executeTranslation();
      }
    } else {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni verilmedi.')),
          );
        }
        return;
      }

      final available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_textController.text.trim().isNotEmpty) {
              _executeTranslation();
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
            localeId: _sourceLanguage.contains('İng') ? 'en_US' : 'tr_TR',
          ),
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
            });
          },
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _textController.text = data.text!;
      });
      _executeTranslation();
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panoya kopyalandı!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareTranslation(AiTranslationResult result) {
    HapticFeedback.mediumImpact();
    final text = '''
🌐 ${result.sourceLanguage} ➔ ${result.targetLanguage} (${result.tone.label}):

"${result.translatedText}"

Orijinal: "${result.originalText}"

OmniBrain AI Çevirmen ile oluşturuldu 🚀
''';
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'OmniBrain Çeviri: ${result.sourceLanguage} - ${result.targetLanguage}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Language Pair Bar (DeepL / Apple Translate style)
          _buildLanguageHeaderBar(),

          const SizedBox(height: 12),

          // 2. Tone Selector Chips (Natural, Business, Academic, Casual)
          _buildToneSelector(),

          const SizedBox(height: 14),

          // 3. Input Text Box Card
          _buildInputCard(),

          const SizedBox(height: 14),

          // 4. Translation Output Card
          if (_isLoading)
            _buildLoadingCard()
          else if (_currentResult != null)
            _buildResultCard(_currentResult!)
          else
            _buildTipCard(),

          // 5. Smart Vocabulary & Phrases Insight
          if (_currentResult != null &&
              (_currentResult!.vocabularyItems.isNotEmpty || _currentResult!.alternativePhrases.isNotEmpty)) ...[
            const SizedBox(height: 16),
            _buildVocabularySection(_currentResult!),
          ],

          // 6. Recent Translations History
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildHistorySection(),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLanguageHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Source Language Dropdown
          Expanded(
            child: _buildLanguageDropdown(
              value: _sourceLanguage,
              items: _languages,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _sourceLanguage = val);
                  if (_textController.text.isNotEmpty) _executeTranslation();
                }
              },
            ),
          ),

          // Swap Button
          GestureDetector(
            onTap: _swapLanguages,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: AppColors.iceBlue, size: 20),
            ),
          ),

          // Target Language Dropdown
          Expanded(
            child: _buildLanguageDropdown(
              value: _targetLanguage,
              items: _languages.where((l) => l != 'Otomatik Algıla').toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _targetLanguage = val);
                  if (_textController.text.isNotEmpty) _executeTranslation();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.contains(value) ? value : items.first;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: validValue,
        isExpanded: true,
        dropdownColor: const Color(0xFF111827),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54, size: 20),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        items: items.map((l) {
          return DropdownMenuItem(
            value: l,
            child: Text(
              l,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: l == validValue ? FontWeight.bold : FontWeight.normal,
                color: l == validValue ? AppColors.iceBlue : Colors.white,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToneSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TranslationTone.values.map((tone) {
          final isSelected = tone == _selectedTone;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTone = tone);
                if (_textController.text.isNotEmpty) _executeTranslation();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.neonPurple.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.neonPurple : Colors.white10,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  tone.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text Input Box
          TextField(
            controller: _textController,
            maxLines: null,
            minLines: 3,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white, height: 1.4),
            decoration: InputDecoration(
              hintText: _isListening ? "Dinleniyor, konuşmaya başla..." : "Çevrilecek metni yaz, yapıştır veya söyle...",
              hintStyle: TextStyle(
                color: _isListening ? AppColors.coralRed : Colors.white30,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => _executeTranslation(),
          ),

          const SizedBox(height: 12),

          // Bottom Action Toolbar (Paste, Clear, Camera OCR, Voice, Translate)
          Row(
            children: [
              // Character count or quick paste
              if (_textController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _textController.clear();
                      _currentResult = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.clear_rounded, size: 12, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text('Temizle', style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _pasteFromClipboard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.content_paste_rounded, size: 12, color: AppColors.iceBlue),
                        const SizedBox(width: 4),
                        Text('Yapıştır', style: GoogleFonts.inter(fontSize: 11, color: AppColors.iceBlue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Camera OCR button
              IconButton(
                icon: const Icon(Icons.camera_alt_rounded, color: AppColors.iceBlue, size: 20),
                tooltip: 'Kamera ile Çevir',
                onPressed: _showImageSourceDialog,
              ),

              // Voice Dictation button
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening ? AppColors.coralRed : Colors.white70,
                  size: 22,
                ),
                tooltip: 'Sesle Çevir',
                onPressed: _toggleSpeech,
              ),

              const SizedBox(width: 4),

              // Translate Trigger Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _executeTranslation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 15),
                    const SizedBox(width: 6),
                    Text('Çevir', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: AppColors.iceBlue, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'Yapay zeka çeviriyor ve kelime nüanslarını analiz ediyor...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildResultCard(AiTranslationResult result) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1B4B),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPurple.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Target language and tone badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.softGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    result.targetLanguage,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  result.tone.label,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Translated Text
          SelectableText(
            result.translatedText,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 10),

          // Actions: Copy, Share, Swap
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Reverse into input
              IconButton(
                icon: const Icon(Icons.input_rounded, color: Colors.white60, size: 18),
                tooltip: 'Metin Kutusuna Aktar',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _textController.text = result.translatedText;
                  });
                },
              ),
              // Copy Button
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white60, size: 18),
                tooltip: 'Kopyala',
                onPressed: () => _copyToClipboard(result.translatedText),
              ),
              // Share Button (AirDrop, WhatsApp, Mail)
              IconButton(
                icon: const Icon(Icons.ios_share_rounded, color: AppColors.iceBlue, size: 18),
                tooltip: 'Paylaş',
                onPressed: () => _shareTranslation(result),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fotoğraftaki yabancı yazıları anında çevirmek için kamera butonunu kullanabilirsin 📸',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularySection(AiTranslationResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_stories_rounded, color: AppColors.iceBlue, size: 16),
            const SizedBox(width: 8),
            Text(
              'Kelime Kartları & Deyim Analizi',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Vocabulary Cards
        if (result.vocabularyItems.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: result.vocabularyItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final vocab = result.vocabularyItems[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          vocab.word,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.iceBlue,
                          ),
                        ),
                        Text(
                          vocab.translation,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.softGreen,
                          ),
                        ),
                      ],
                    ),
                    if (vocab.explanation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        vocab.explanation,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                    if (vocab.exampleSentence.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 10)),
                            Expanded(
                              child: Text(
                                vocab.exampleSentence,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

        // Alternative Phrases
        if (result.alternativePhrases.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Alternatif Çeviri İfadeleri',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.alternativePhrases.map((phrase) {
              return GestureDetector(
                onTap: () => _copyToClipboard(phrase),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        phrase,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.copy_rounded, size: 12, color: Colors.white38),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Geçmiş Çeviriler',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                await AiTranslationService.clearHistory();
                setState(() => _history = []);
              },
              child: Text(
                'Temizle',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.coralRed, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length > 5 ? 5 : _history.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _history[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _textController.text = item.originalText;
                  _sourceLanguage = item.sourceLanguage;
                  _targetLanguage = item.targetLanguage;
                  _selectedTone = item.tone;
                  _currentResult = item;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.sourceLanguage} ➔ ${item.targetLanguage}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.iceBlue, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.tone.label.split(' ')[0],
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.translatedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      item.originalText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
