import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnibrain_ai/l10n/app_localizations.dart';
import 'package:omnibrain_ai/core/constants/app_strings.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/theme/app_theme.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';

import 'package:omnibrain_ai/core/providers/locale_provider.dart';

class OmniBrainApp extends ConsumerWidget {
  const OmniBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger early initialization of RevenueCat
    ref.read(revenueCatProvider);
    
    final router = ref.watch(appRouterProvider);
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: OmniBrainTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: currentLocale,
    );
  }
}
