import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'subscription_state.dart';
import '../../services/subscription_service.dart';

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this._service) : super(const SubscriptionState()) {
    _listener = _updateFromCustomerInfo;
    _service.addCustomerInfoListener(_listener);
    refresh();
  }

  final SubscriptionService _service;
  late final CustomerInfoUpdateListener _listener;

  Future<void> refresh() async {
    try {
      final info = await _service.getCustomerInfo();
      _updateFromCustomerInfo(info);
    } catch (_) {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  void _updateFromCustomerInfo(CustomerInfo info) {
    if (!mounted) return;
    final entitlement = info.entitlements.active[kEntitlementId];

    if (entitlement == null) {
      state = const SubscriptionState(isLoading: false, isActive: false);
      return;
    }

    final expiresAt = entitlement.expirationDate != null
        ? DateTime.tryParse(entitlement.expirationDate!)
        : null;

    final productId = entitlement.productIdentifier;
    final plan = productId == 'yearly'
        ? 'annual'
        : productId == 'lifetime'
            ? 'lifetime'
            : 'monthly';

    state = SubscriptionState(
      isLoading: false,
      isActive: true,
      plan: plan,
      expiresAt: expiresAt,
      willRenew: entitlement.willRenew,
    );
  }

  @override
  void dispose() {
    _service.removeCustomerInfoListener(_listener);
    super.dispose();
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref.read(subscriptionServiceProvider));
});
