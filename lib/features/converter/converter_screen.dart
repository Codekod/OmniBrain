import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';
import 'package:omnibrain_ai/features/converter/services/currency_service.dart';
import 'package:omnibrain_ai/features/converter/widgets/ai_translation_view.dart';

enum ConversionCategory {
  currency('Döviz', Icons.currency_exchange_rounded),
  length('Uzunluk', Icons.straighten_rounded),
  weight('Ağırlık', Icons.scale_rounded),
  temperature('Sıcaklık', Icons.thermostat_rounded),
  area('Alan & Hacim', Icons.aspect_ratio_rounded),
  speed('Hız', Icons.speed_rounded),
  data('Veri & Bellek', Icons.storage_rounded);

  final String label;
  final IconData icon;
  const ConversionCategory(this.label, this.icon);
}

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: GradientBackground(
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
              'Çeviri & Dönüştürücü Studio',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.neonPurple.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.5)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.translate_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('AI Dil Çevirmeni'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.currency_exchange_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Döviz & Birimler'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: const SafeArea(
            child: TabBarView(
              children: [
                AiTranslationView(),
                _UniversalUnitConverterView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UniversalUnitConverterView extends ConsumerStatefulWidget {
  const _UniversalUnitConverterView();

  @override
  ConsumerState<_UniversalUnitConverterView> createState() => _UniversalUnitConverterViewState();
}

class _UniversalUnitConverterViewState extends ConsumerState<_UniversalUnitConverterView> {
  final TextEditingController _amountController = TextEditingController(text: "1");
  final TextEditingController _naturalLanguageController = TextEditingController();

  ConversionCategory _selectedCategory = ConversionCategory.currency;
  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Conversion Units per Category
  final Map<ConversionCategory, List<String>> _unitsByCategory = {
    ConversionCategory.currency: ['USD', 'EUR', 'TRY', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD', 'BTC', 'ETH'],
    ConversionCategory.length: ['Santimetre (cm)', 'Metre (m)', 'Kilometre (km)', 'İnç (in)', 'Fit (ft)', 'Mil (mi)'],
    ConversionCategory.weight: ['Gram (g)', 'Kilogram (kg)', 'Ton (t)', 'Libre (lb)', 'Ons (oz)'],
    ConversionCategory.temperature: ['Santigrat (°C)', 'Fahrenhayt (°F)', 'Kelvin (K)'],
    ConversionCategory.area: ['Metrekare (m²)', 'Dönüm', 'Hektar', 'Litre (L)', 'Mililitre (ml)'],
    ConversionCategory.speed: ['km/s', 'mph', 'knot', 'm/sn'],
    ConversionCategory.data: ['Megabayt (MB)', 'Gigabayt (GB)', 'Terabayt (TB)', 'Kilobayt (KB)'],
  };

  late String _fromUnit;
  late String _toUnit;
  String _resultValue = "34.20";
  String _statusMessage = "Canlı döviz kurları aktiftir.";

  // Conversion History
  final List<Map<String, String>> _recentConversions = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _fromUnit = 'USD';
    _toUnit = 'TRY';

    _calculateImmediateConversion();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _naturalLanguageController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onCategoryChanged(ConversionCategory cat) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = cat;
      final units = _unitsByCategory[cat]!;
      _fromUnit = units[0];
      _toUnit = units.length > 1 ? units[1] : units[0];
    });
    _calculateImmediateConversion();
  }

  void _swapUnits() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
    _calculateImmediateConversion();
  }

  Future<void> _calculateImmediateConversion() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      setState(() {
        _resultValue = "0";
      });
      return;
    }

    if (_selectedCategory == ConversionCategory.currency) {
      setState(() => _isLoading = true);
      try {
        final result = await CurrencyService.convert(
          amount: amount,
          from: _fromUnit,
          to: _toUnit,
        );
        if (mounted) {
          setState(() {
            _resultValue = result >= 100
                ? result.toStringAsFixed(2)
                : (result >= 1 ? result.toStringAsFixed(3) : result.toStringAsPrecision(4));
            _statusMessage =
                "Canlı piyasa kuruyla çevrildi (1 $_fromUnit = ${(result / amount).toStringAsFixed(2)} $_toUnit)";
            _isLoading = false;
          });
        }
        _addToHistory('$amount $_fromUnit', '$_resultValue $_toUnit');
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Local formula conversions for instant zero-latency UX
      final res = _calculateStandardUnits(amount, _fromUnit, _toUnit);
      if (mounted) {
        setState(() {
          _resultValue = res.toStringAsFixed(res % 1 == 0 ? 0 : 2);
          _statusMessage = "$_fromUnit başarıyla $_toUnit birimine dönüştürüldü.";
        });
      }
      _addToHistory('$amount $_fromUnit', '$_resultValue $_toUnit');
    }
  }

  double _calculateStandardUnits(double val, String from, String to) {
    // Length in meters
    double toMeters(String u, double v) {
      if (u.contains('cm')) return v * 0.01;
      if (u.contains('km')) return v * 1000;
      if (u.contains('in')) return v * 0.0254;
      if (u.contains('ft')) return v * 0.3048;
      if (u.contains('mi')) return v * 1609.34;
      return v;
    }

    double fromMeters(String u, double m) {
      if (u.contains('cm')) return m / 0.01;
      if (u.contains('km')) return m / 1000;
      if (u.contains('in')) return m / 0.0254;
      if (u.contains('ft')) return m / 0.3048;
      if (u.contains('mi')) return m / 1609.34;
      return m;
    }

    // Weight in grams
    double toGrams(String u, double v) {
      if (u.contains('kg')) return v * 1000;
      if (u.contains('t') && !u.contains('oz')) return v * 1000000;
      if (u.contains('lb')) return v * 453.592;
      if (u.contains('oz')) return v * 28.3495;
      return v;
    }

    double fromGrams(String u, double g) {
      if (u.contains('kg')) return g / 1000;
      if (u.contains('t') && !u.contains('oz')) return g / 1000000;
      if (u.contains('lb')) return g / 453.592;
      if (u.contains('oz')) return g / 28.3495;
      return g;
    }

    if (_selectedCategory == ConversionCategory.length) {
      return fromMeters(to, toMeters(from, val));
    }
    if (_selectedCategory == ConversionCategory.weight) {
      return fromGrams(to, toGrams(from, val));
    }
    if (_selectedCategory == ConversionCategory.temperature) {
      if (from.contains('°C') && to.contains('°F')) return (val * 9 / 5) + 32;
      if (from.contains('°F') && to.contains('°C')) return (val - 32) * 5 / 9;
      if (from.contains('°C') && to.contains('K')) return val + 273.15;
      if (from.contains('K') && to.contains('°C')) return val - 273.15;
      return val;
    }
    if (_selectedCategory == ConversionCategory.area) {
      if (from.contains('Dönüm') && to.contains('m²')) return val * 1000;
      if (from.contains('m²') && to.contains('Dönüm')) return val / 1000;
      if (from.contains('Hektar') && to.contains('m²')) return val * 10000;
      if (from.contains('L') && to.contains('ml')) return val * 1000;
      if (from.contains('ml') && to.contains('L')) return val / 1000;
      return val;
    }
    if (_selectedCategory == ConversionCategory.speed) {
      double toMs(String u, double v) {
        if (u.contains('km/s')) return v / 3.6;
        if (u.contains('mph')) return v * 0.44704;
        if (u.contains('knot')) return v * 0.514444;
        return v;
      }

      double fromMs(String u, double m) {
        if (u.contains('km/s')) return m * 3.6;
        if (u.contains('mph')) return m / 0.44704;
        if (u.contains('knot')) return m / 0.514444;
        return m;
      }

      return fromMs(to, toMs(from, val));
    }
    if (_selectedCategory == ConversionCategory.data) {
      double toMb(String u, double v) {
        if (u.contains('KB')) return v / 1024;
        if (u.contains('MB')) return v;
        if (u.contains('GB')) return v * 1024;
        if (u.contains('TB')) return v * 1048576;
        return v;
      }

      double fromMb(String u, double mb) {
        if (u.contains('KB')) return mb * 1024;
        if (u.contains('MB')) return mb;
        if (u.contains('GB')) return mb / 1024;
        if (u.contains('TB')) return mb / 1048576;
        return mb;
      }

      return fromMb(to, toMb(from, val));
    }
    return val;
  }

  void _addToHistory(String from, String to) {
    if (_recentConversions.any((item) => item['from'] == from && item['to'] == to)) return;
    setState(() {
      _recentConversions.insert(0, {'from': from, 'to': to});
      if (_recentConversions.length > 5) _recentConversions.removeLast();
    });
  }

  Future<void> _processAiNaturalQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _naturalLanguageController.clear();
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
        _amountController.text = origVal;
        _fromUnit = origUnit;
        _toUnit = convUnit;
        _resultValue = convVal;
        _statusMessage = msg;
        _isLoading = false;
      });
      _addToHistory('$origVal $origUnit', '$convVal $convUnit');
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_naturalLanguageController.text.isNotEmpty) {
        _processAiNaturalQuery(_naturalLanguageController.text);
      }
    } else {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;

      final available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_naturalLanguageController.text.isNotEmpty) {
              _processAiNaturalQuery(_naturalLanguageController.text);
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
            localeId: 'tr_TR',
          ),
          onResult: (val) {
            setState(() {
              _naturalLanguageController.text = val.recognizedWords;
            });
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = _unitsByCategory[_selectedCategory] ?? [];

    return Column(
      children: [
        const SizedBox(height: 12),
        // 1. CATEGORY TABS (Ana Başlıklar)
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: ConversionCategory.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = ConversionCategory.values[index];
              final isSelected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => _onCategoryChanged(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.amber.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected ? AppColors.amber : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // 2. CONVERSION CARD AREA (Scrollable)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // FROM CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kaynak Miktar & Birim',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          _buildUnitDropdown(
                            selected: _fromUnit,
                            options: units,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _fromUnit = val);
                                _calculateImmediateConversion();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.montserrat(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => _calculateImmediateConversion(),
                      ),
                    ],
                  ),
                ),

                // SWAP BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: GestureDetector(
                    onTap: _swapUnits,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.amber.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withValues(alpha: 0.2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: AppColors.amber,
                        size: 26,
                      ),
                    ),
                  ),
                ),

                // TO CARD (RESULT)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dönüştürülen Değer',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              _buildUnitDropdown(
                                selected: _toUnit,
                                options: units,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _toUnit = val);
                                    _calculateImmediateConversion();
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
                                tooltip: 'Kopyala',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: '$_resultValue $_toUnit'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sonuç panoya kopyalandı!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            height: 36,
                            width: 36,
                            child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 3),
                          ),
                        )
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _resultValue,
                            style: GoogleFonts.montserrat(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Status Note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                // Conversion History
                if (_recentConversions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Son Dönüşümler',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentConversions.length,
                    itemBuilder: (context, index) {
                      final item = _recentConversions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['from']!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.amber, size: 14),
                            Text(item['to']!,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        // 3. AI NATURAL LANGUAGE COMMAND BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.deepNightBlue,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? AppColors.coralRed : AppColors.amber,
                ),
                onPressed: _toggleListening,
              ),
              Expanded(
                child: TextField(
                  controller: _naturalLanguageController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _isListening ? "Dinliyorum..." : "Yaz veya söyle (Örn: 250 Dolar kaç TL?)",
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.darkNavy,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _processAiNaturalQuery,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _processAiNaturalQuery(_naturalLanguageController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.amber, AppColors.coralRed]),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitDropdown({
    required String selected,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final validSelected = options.contains(selected) ? selected : (options.isNotEmpty ? options.first : selected);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validSelected,
          dropdownColor: AppColors.darkNavy,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          items: options.map((u) {
            return DropdownMenuItem<String>(
              value: u,
              child: Text(u),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
