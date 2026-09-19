import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omnibrain_ai/app.dart';
import 'package:omnibrain_ai/core/providers/shared_prefs_provider.dart';
import 'package:omnibrain_ai/core/services/notification_service.dart';
import 'package:omnibrain_ai/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for consistent layout
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Orientation lock failed: $e');
  }

  // Load .env first (synchronous)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env load failed: $e');
  }

  // Safe initialization of services to prevent startup crashes
  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences init failed: $e');
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }

  try {
    await initSupabase();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        if (sharedPreferences != null)
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const OmniBrainApp(),
    ),
  );
}
