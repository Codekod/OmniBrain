import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// A class holding the state of our RevenueCat integration.
class RevenueCatState {
  final bool isInitialized;
  final bool isPro;
  final Offerings? offerings;

  const RevenueCatState({
    this.isInitialized = false,
    this.isPro = false,
    this.offerings,
  });

  RevenueCatState copyWith({
    bool? isInitialized,
    bool? isPro,
    Offerings? offerings,
  }) {
    return RevenueCatState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPro: isPro ?? this.isPro,
      offerings: offerings ?? this.offerings,
    );
  }
}

class RevenueCatNotifier extends StateNotifier<RevenueCatState> {
  RevenueCatNotifier() : super(const RevenueCatState()) {
    _initRevenueCat();
  }

  Future<void> _initRevenueCat() async {
    try {
      // Suppress verbose logs in release builds
      await Purchases.setLogLevel(LogLevel.warn);

      String? apiKey;
      if (Platform.isIOS) {
        apiKey = dotenv.env['REVENUECAT_APPLE_KEY'];
      } else if (Platform.isAndroid) {
        apiKey = dotenv.env['REVENUECAT_GOOGLE_KEY'];
      }

      if (apiKey == null || apiKey.isEmpty) {
        print("RevenueCat API Key not found in .env. Skipping initialization.");
        return;
      }

      // RevenueCat crashes with fatalError() if a test API key is used in
      // release/profile mode. Skip initialization to prevent the crash.
      if (apiKey.startsWith('test_') && !kDebugMode) {
        print("RevenueCat: Test API key detected in non-debug build. "
            "Skipping initialization to prevent crash. "
            "Use a production API key for release builds.");
        return;
      }

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateProStatus(customerInfo);
      });

      // Run network calls in parallel for faster startup
      final results = await Future.wait([
        Purchases.getCustomerInfo(),
        Purchases.getOfferings(),
      ]);

      _updateProStatus(results[0] as CustomerInfo);

      state = state.copyWith(
        isInitialized: true,
        offerings: results[1] as Offerings,
      );
    } catch (e) {
      print("Error initializing RevenueCat: $e");
    }
  }

  void _updateProStatus(CustomerInfo customerInfo) {
    // If any entitlement is active, consider the user as Pro
    final isPro = customerInfo.entitlements.active.isNotEmpty;
    state = state.copyWith(isPro: isPro);
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      _updateProStatus(purchaseResult.customerInfo);
      return purchaseResult.customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      print("Purchase failed: $e");
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateProStatus(customerInfo);
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      print("Restore failed: $e");
      return false;
    }
  }

  void enableTestProMode() {
    state = state.copyWith(isPro: true);
  }
}

final revenueCatProvider = StateNotifierProvider<RevenueCatNotifier, RevenueCatState>((ref) {
  return RevenueCatNotifier();
});
