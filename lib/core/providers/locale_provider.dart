import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnibrain_ai/core/providers/shared_prefs_provider.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final Locale locale;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.locale,
  });
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷', locale: Locale('tr', 'TR')),
  AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸', locale: Locale('en', 'US')),
  AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪', locale: Locale('de', 'DE')),
  AppLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷', locale: Locale('fr', 'FR')),
  AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸', locale: Locale('es', 'ES')),
  AppLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹', locale: Locale('it', 'IT')),
  AppLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇧🇷', locale: Locale('pt', 'BR')),
  AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦', locale: Locale('ar', 'AE')),
  AppLanguage(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳', locale: Locale('zh', 'CN')),
  AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵', locale: Locale('ja', 'JP')),
];

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;
  static const String _prefKey = 'selected_language_code';

  LocaleNotifier(this._ref) : super(_detectInitialLocale(_ref));

  static Locale _detectInitialLocale(Ref ref) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        final match = supportedLanguages.where((l) => l.code == savedCode).firstOrNull;
        if (match != null) return match.locale;
      }
    } catch (_) {}

    // Auto-detect device/system locale
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    final systemLangCode = systemLocale.languageCode.toLowerCase();
    final match = supportedLanguages.where((l) => l.code == systemLangCode).firstOrNull;
    if (match != null) {
      return match.locale;
    }

    // Default to English if system language is not in the 10 supported languages
    return const Locale('en', 'US');
  }

  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setString(_prefKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('Failed to save locale: $e');
    }
  }

  Future<void> setLanguageByCode(String code) async {
    final match = supportedLanguages.where((l) => l.code == code).firstOrNull;
    if (match != null) {
      await setLocale(match.locale);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

final currentLanguageProvider = Provider<AppLanguage>((ref) {
  final currentLocale = ref.watch(localeProvider);
  return supportedLanguages.firstWhere(
    (l) => l.code == currentLocale.languageCode,
    orElse: () => supportedLanguages.firstWhere((l) => l.code == 'en'),
  );
});
