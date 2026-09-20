import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TranslationTone {
  natural('🌟 Doğal & Akıcı', 'Günlük dilde en doğal ifade'),
  formal('💼 Kurumsal & Resmi', 'İş dünyası, e-postalar ve resmi yazışmalar için'),
  academic('🎓 Akademik & Hassas', 'Makale, araştırma ve edebi metinler için'),
  casual('💬 Samimi & Günlük', 'Sohbet, mesajlaşma ve arkadaşlar arası iletişim için');

  final String label;
  final String description;
  const TranslationTone(this.label, this.description);
}

class VocabularyItem {
  final String word;
  final String translation;
  final String explanation;
  final String exampleSentence;

  VocabularyItem({
    required this.word,
    required this.translation,
    required this.explanation,
    required this.exampleSentence,
  });

  Map<String, dynamic> toMap() => {
        'word': word,
        'translation': translation,
        'explanation': explanation,
        'exampleSentence': exampleSentence,
      };

  factory VocabularyItem.fromMap(Map<String, dynamic> map) => VocabularyItem(
        word: map['word']?.toString() ?? '',
        translation: map['translation']?.toString() ?? '',
        explanation: map['explanation']?.toString() ?? '',
        exampleSentence: map['exampleSentence']?.toString() ?? '',
      );
}

class AiTranslationResult {
  final String id;
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final TranslationTone tone;
  final List<VocabularyItem> vocabularyItems;
  final List<String> alternativePhrases;
  final DateTime timestamp;

  AiTranslationResult({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.tone,
    this.vocabularyItems = const [],
    this.alternativePhrases = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'originalText': originalText,
        'translatedText': translatedText,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'tone': tone.name,
        'vocabularyItems': vocabularyItems.map((v) => v.toMap()).toList(),
        'alternativePhrases': alternativePhrases,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AiTranslationResult.fromMap(Map<String, dynamic> map) => AiTranslationResult(
        id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        originalText: map['originalText']?.toString() ?? '',
        translatedText: map['translatedText']?.toString() ?? '',
        sourceLanguage: map['sourceLanguage']?.toString() ?? 'Otomatik',
        targetLanguage: map['targetLanguage']?.toString() ?? 'Türkçe',
        tone: TranslationTone.values.firstWhere(
          (t) => t.name == map['tone'],
          orElse: () => TranslationTone.natural,
        ),
        vocabularyItems: (map['vocabularyItems'] as List<dynamic>? ?? [])
            .map((v) => VocabularyItem.fromMap(v as Map<String, dynamic>))
            .toList(),
        alternativePhrases: (map['alternativePhrases'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class AiTranslationService {
  static const String _historyKey = 'omnibrain_ai_translation_history_v1';

  static Future<AiTranslationResult> translate({
    required GenerativeModel gemini,
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    required TranslationTone tone,
  }) async {
    final toneInstruction = switch (tone) {
      TranslationTone.natural => 'En doğal ve ana dil gibi akıcı bir üslupla çevir.',
      TranslationTone.formal => 'Son derece profesyonel, saygılı ve iş dünyası (business/diplomatic) standartlarına uygun bir üslupla çevir.',
      TranslationTone.academic => 'Terminolojik olarak en hassas, akademik ve literatüre uygun dille çevir.',
      TranslationTone.casual => 'Arkadaşça, samimi, modern günlük konuşma dili ve deyimlerle çevir.',
    };

    final prompt = '''
Sen dünyanın en gelişmiş yapay zeka çeviri motorusun (DeepL, Google Neural ve Apple Translate kalitesinin üzerinde).
Aşağıdaki metni $sourceLanguage dilinden $targetLanguage diline çevir.

İstenen Ton: ${tone.label} - $toneInstruction

Lütfen çıktıyı YALNIZCA ve KESİNLİKLE aşağıdaki geçerli JSON formatında ver (hiçbir markdown başlığı, açıklaması veya fazladan metin ekleme):
```json
{
  "translatedText": "Çevrilen tam metin",
  "vocabulary": [
    {
      "word": "Orijinal metindeki önemli/anahtar kelime veya deyim",
      "translation": "Hedef dildeki karşılığı",
      "explanation": "Kısa nüans/anlam açıklaması",
      "exampleSentence": "Hedef dilde örnek kullanım cümlesi"
    }
  ],
  "alternativePhrases": [
    "Aynı anlamı ifade eden alternatif 1. çeviri varyantı",
    "Aynı anlamı ifade eden alternatif 2. çeviri varyantı"
  ]
}
```

Kaynak Metin:
"""
$text
"""
''';

    final response = await gemini.generateContent([Content.text(prompt)]);
    final rawText = response.text ?? '';

    String cleanJson = rawText.trim();
    if (cleanJson.contains('```json')) {
      cleanJson = cleanJson.split('```json')[1].split('```')[0].trim();
    } else if (cleanJson.contains('```')) {
      cleanJson = cleanJson.split('```')[1].split('```')[0].trim();
    }

    try {
      final data = jsonDecode(cleanJson) as Map<String, dynamic>;
      final translated = data['translatedText']?.toString() ?? text;
      final rawVocab = data['vocabulary'] as List<dynamic>? ?? [];
      final vocabList = rawVocab.map((v) {
        final map = v as Map<String, dynamic>;
        return VocabularyItem(
          word: map['word']?.toString() ?? '',
          translation: map['translation']?.toString() ?? '',
          explanation: map['explanation']?.toString() ?? '',
          exampleSentence: map['exampleSentence']?.toString() ?? '',
        );
      }).toList();

      final rawAlt = data['alternativePhrases'] as List<dynamic>? ?? [];
      final altList = rawAlt.map((e) => e.toString()).toList();

      final result = AiTranslationResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalText: text,
        translatedText: translated,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        tone: tone,
        vocabularyItems: vocabList,
        alternativePhrases: altList,
        timestamp: DateTime.now(),
      );

      // Save to local history
      await saveToHistory(result);
      return result;
    } catch (e) {
      debugPrint('JSON parse error in AI translation: $e. Falling back to raw response.');
      // If parsing fails, use clean text
      final result = AiTranslationResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalText: text,
        translatedText: cleanJson.isNotEmpty ? cleanJson : text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        tone: tone,
        timestamp: DateTime.now(),
      );
      await saveToHistory(result);
      return result;
    }
  }

  static Future<void> saveToHistory(AiTranslationResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHistory = await getHistory();
      // Remove duplicate if same text
      currentHistory.removeWhere((item) => item.originalText.trim() == result.originalText.trim());
      // Insert newest at top
      currentHistory.insert(0, result);
      // Keep max 20
      if (currentHistory.length > 20) {
        currentHistory.removeRange(20, currentHistory.length);
      }
      final jsonList = currentHistory.map((e) => e.toMap()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to save translation to history: $e');
    }
  }

  static Future<List<AiTranslationResult>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_historyKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => AiTranslationResult.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Failed to load translation history: $e');
      return [];
    }
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {}
  }
}
