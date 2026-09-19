import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // AI Values
  String _originalValue = "100";
  String _originalUnit = "USD";
  String _convertedValue = "...";
  String _convertedUnit = "TRY";
  String _message = "Akıllı dönüştürme için konuşun, yazın veya hazır butonlara dokunun.";

  // Conversion History
  final List<Map<String, String>> _recentConversions = [];

  final List<String> _popularPresets = [
    "100 USD kaç TL?",
    "100 EUR kaç TL?",
    "1 inç kaç cm?",
    "10 mil kaç km?",
    "5 lbs kaç kg?",
    "1 ons altın kaç gr?",
    "75 fahrenheit kaç santigrat?",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Run initial conversion for USD to TRY
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processConversion("100 USD kaç TL?");
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _processConversion(_textController.text);
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
              _processConversion(_textController.text);
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
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
            });
          },
        );
      }
    }
  }

  Future<void> _processConversion(String query) async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final aiRepo = ref.read(aiCommandRepositoryProvider);
      final responseStr = await aiRepo.processConversion(trimmed);

      final cleanJson = responseStr.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanJson);

      final origVal = data['originalValue']?.toString() ?? "0";
      final origUnit = data['originalUnit']?.toString() ?? "Birim";
      final convVal = data['convertedValue']?.toString() ?? "0";
      final convUnit = data['convertedUnit']?.toString() ?? "Birim";
      final msg = data['message']?.toString() ?? "Hesaplandı.";

      setState(() {
        _originalValue = origVal;
        _originalUnit = origUnit;
        _convertedValue = convVal;
        _convertedUnit = convUnit;
        _message = msg;
        _isLoading = false;

        // Add to history
        _recentConversions.insert(0, {
          'from': '$origVal $origUnit',
          'to': '$convVal $convUnit',
        });
        if (_recentConversions.length > 5) {
          _recentConversions.removeLast();
        }
      });
    } catch (e) {
      setState(() {
        _message = "Dönüştürme başarısız oldu: $e";
        _isLoading = false;
      });
    }
  }

  void _swapUnits() {
    if (_convertedValue == "..." || _isLoading) return;
    HapticFeedback.lightImpact();

    final swapQuery = "$_convertedValue $_convertedUnit kaç $_originalUnit?";
    _processConversion(swapQuery);
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
            'Evrensel Çevirici',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Popular Presets Horizontal Chips
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _popularPresets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final preset = _popularPresets[index];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _processConversion(preset);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Center(
                          child: Text(
                            preset,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.iceBlue),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Original Value Card
                    _buildValueCard(_originalValue, _originalUnit, true),
                    const SizedBox(height: 16),

                    // Center Swap Button
                    GestureDetector(
                      onTap: _swapUnits,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.deepNightBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.amber.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
                              )
                            : const Icon(Icons.swap_vert_rounded, color: AppColors.amber, size: 28),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Converted Value Card
                    _buildValueCard(_convertedValue, _convertedUnit, false),
                    const SizedBox(height: 20),

                    // AI Explanation Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.amber, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _message,
                              style: AppTextStyles.bodyText.copyWith(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ).animate(key: ValueKey(_message)).fadeIn(),

                    // Recent Conversions
                    if (_recentConversions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Son Dönüşümler',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._recentConversions.map((hist) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(hist['from'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const Icon(Icons.arrow_forward_rounded, color: AppColors.amber, size: 14),
                              Text(
                                hist['to'] ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isOriginal ? AppColors.cardBorder : AppColors.amber.withValues(alpha: 0.5),
          width: isOriginal ? 1 : 1.5,
        ),
        boxShadow: isOriginal
            ? []
            : [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 4,
                )
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOriginal ? 'Kaynak Değer' : 'Dönüştürülen Değer',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (!isOriginal && value != "...")
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: "$value $unit"));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sonuç panoya kopyalandı!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 54,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isOriginal ? Colors.white.withValues(alpha: 0.08) : AppColors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              unit.toUpperCase(),
              style: TextStyle(
                color: isOriginal ? Colors.white70 : AppColors.amber,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 10,
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
          // Speech Mic Button
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
          const SizedBox(width: 8),

          // Text Field
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isListening ? "Dinliyorum..." : "Örn: 250 Dolar kaç TL?",
                hintStyle: TextStyle(
                  color: _isListening ? AppColors.coralRed : Colors.white38,
                  fontSize: 13,
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
                  borderSide: BorderSide(color: AppColors.amber.withValues(alpha: 0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: _processConversion,
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          GestureDetector(
            onTap: () {
              if (_textController.text.isNotEmpty) {
                _processConversion(_textController.text);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.amber, AppColors.neonPurple],
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
