import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _cacheKey = 'cached_currency_rates';
  static const String _cacheTimestampKey = 'cached_currency_timestamp';

  // Fallback realistic base rates (USD base)
  static final Map<String, double> _defaultRates = {
    'USD': 1.0,
    'TRY': 34.20,
    'EUR': 0.92,
    'GBP': 0.77,
    'JPY': 152.4,
    'CHF': 0.86,
    'CAD': 1.38,
    'AUD': 1.51,
    'AED': 3.67,
    'SAR': 3.75,
    'BTC': 0.000015,
    'ETH': 0.00038,
  };

  static Map<String, double>? _memoryRates;
  static DateTime? _lastFetchTime;

  /// Returns current rates against USD
  static Future<Map<String, double>> getRates() async {
    // If fetched in the last 15 minutes, return memory cache
    if (_memoryRates != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 15) {
      return _memoryRates!;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);
        if (json['result'] == 'success' && json['rates'] is Map) {
          final rawRates = json['rates'] as Map<String, dynamic>;
          final Map<String, double> parsed = {};
          rawRates.forEach((key, value) {
            if (value is num) {
              parsed[key] = value.toDouble();
            }
          });

          _memoryRates = parsed;
          _lastFetchTime = DateTime.now();

          // Persist to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(parsed));
          await prefs.setInt(_cacheTimestampKey, _lastFetchTime!.millisecondsSinceEpoch);

          return parsed;
        }
      }
    } catch (_) {
      // Ignore network errors, fall back to cached
    }

    // Try reading cached rates from disk
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);
      if (cachedStr != null) {
        final decoded = jsonDecode(cachedStr) as Map<String, dynamic>;
        final Map<String, double> diskRates = {};
        decoded.forEach((key, val) {
          if (val is num) diskRates[key] = val.toDouble();
        });
        _memoryRates = diskRates;
        return diskRates;
      }
    } catch (_) {}

    _memoryRates = _defaultRates;
    return _defaultRates;
  }

  /// Converts an amount from one currency to another using latest rates
  static Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    final rates = await getRates();
    final fromRate = rates[from] ?? _defaultRates[from] ?? 1.0;
    final toRate = rates[to] ?? _defaultRates[to] ?? 1.0;

    // Convert from -> USD -> to
    final amountInUsd = amount / fromRate;
    return amountInUsd * toRate;
  }
}
