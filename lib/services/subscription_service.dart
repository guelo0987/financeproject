import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/app_env.dart';

const kEntitlementId = 'Menudo Pro';

class SubscriptionService {
  static bool _configured = false;

  bool get isConfigured => _configured;

  static Future<void> initialize() async {
    final apiKey = AppEnv.revenueCatApiKey;
    if (apiKey.isEmpty) {
      _configured = false;
      return;
    }

    if (apiKey.startsWith('test_') && !AppEnv.allowTestStoreRevenueCat) {
      _configured = false;
      return;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
  }

  Future<void> logIn(String userId) async {
    if (!_configured) return;
    await Purchases.logIn(userId);
  }

  Future<void> logOut() async {
    if (!_configured) return;
    await Purchases.logOut();
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_configured) return null;
    return Purchases.getCustomerInfo();
  }

  Future<bool> hasActiveEntitlement() async {
    final info = await getCustomerInfo();
    return info?.entitlements.active.containsKey(kEntitlementId) ?? false;
  }

  Future<Offering?> getOfferings() async {
    if (!_configured) return null;
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  }

  Future<PurchaseResult?> purchasePackage(Package package) async {
    if (!_configured) return null;
    return Purchases.purchase(PurchaseParams.package(package));
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    return Purchases.restorePurchases();
  }

  void addCustomerInfoListener(CustomerInfoUpdateListener listener) {
    if (!_configured) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  void removeCustomerInfoListener(CustomerInfoUpdateListener listener) {
    if (!_configured) return;
    Purchases.removeCustomerInfoUpdateListener(listener);
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>(
  (_) => SubscriptionService(),
);
