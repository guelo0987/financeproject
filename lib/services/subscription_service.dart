import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _kApiKey = 'test_kcBeSKYkrMMhFlcmFTuwHhXGKaw';
const kEntitlementId = 'Menudo Pro';

class SubscriptionService {
  static Future<void> initialize() async {
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    await Purchases.configure(PurchasesConfiguration(_kApiKey));
  }

  Future<void> logIn(String userId) async {
    await Purchases.logIn(userId);
  }

  Future<void> logOut() async {
    await Purchases.logOut();
  }

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  Future<bool> hasActiveEntitlement() async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(kEntitlementId);
  }

  Future<Offering?> getOfferings() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  }

  void addCustomerInfoListener(CustomerInfoUpdateListener listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  void removeCustomerInfoListener(CustomerInfoUpdateListener listener) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>(
  (_) => SubscriptionService(),
);
