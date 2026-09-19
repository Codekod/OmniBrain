import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:omnibrain_ai/l10n/app_localizations.dart';
import 'package:omnibrain_ai/core/constants/app_strings.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/theme/app_theme.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';

class OmniBrainApp extends ConsumerWidget {
  const OmniBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger early initialization of RevenueCat
    ref.read(revenueCatProvider);
    
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: OmniBrainTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('fr', 'FR'),
        Locale('ar', 'AE'),
        Locale('it', 'IT'),
        Locale('es', 'ES'),
        Locale('pt', 'PT'),
        Locale('zh', 'CN'),
      ],
      locale: const Locale('tr', 'TR'), // Default to Turkish
    );
  }
}
