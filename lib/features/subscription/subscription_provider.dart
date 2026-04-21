import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'subscription_state.dart';
import '../auth/auth_state.dart';
import '../../services/subscription_service.dart';
import '../../services/api_service.dart';

/// Backend DB is the single source of truth for subscription estado/dates.
/// RC is only a fallback for the brief window after a purchase before
/// the webhook reaches the backend.
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this._service, this._api)
    : super(const SubscriptionState()) {
    _listener = (_) async {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) refresh();
    };
    _service.addCustomerInfoListener(_listener);
    refresh();
  }

  final SubscriptionService _service;
  final ApiService _api;
  late final CustomerInfoUpdateListener _listener;

  Future<void> refresh() async {
    var backendFailed = false;

    // ── Step 1: Backend DB (authoritative) ───────────────────────────
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/subscriptions/estado',
        parser: (p) => p as Map<String, dynamic>,
      );
      if (!mounted) return;
      final data = response.data;

      if (data != null && data['isActive'] == true) {
        final estado = data['estado'] as String? ?? 'prueba';
        final rawPlan = data['plan'] as String? ?? 'mensual';
        final plan = rawPlan == 'anual' ? 'annual' : rawPlan;
        final trialFin = data['trial_fin'] as String?;
        final periodoFin = data['periodo_fin'] as String?;
        final expiryStr = estado == 'prueba' ? trialFin : periodoFin;
        final expiresAt = expiryStr != null
            ? DateTime.tryParse(expiryStr)
            : null;
        final canceladoEn = data['cancelado_en'] as String?;

        state = SubscriptionState(
          isLoading: false,
          isActive: true,
          estado: estado,
          plan: plan,
          expiresAt: expiresAt,
          willRenew:
              estado == 'activa' && plan != 'lifetime' && canceladoEn == null,
          hasVerificationIssue: false,
        );
        return; // Backend confirmed — done
      }
    } catch (_) {
      backendFailed = true;
    }

    var rcFailed = false;
    var rcReached = false;
    // ── Step 2: RC fallback (post-purchase before webhook arrives) ───
    if (_service.isConfigured) {
      try {
        final info = await _service.getCustomerInfo();
        if (info == null) {
          rcFailed = true;
        } else {
          rcReached = true;
          final entitlement = info.entitlements.active[kEntitlementId];

          if (entitlement != null) {
            if (!mounted) return;
            final productId = entitlement.productIdentifier;
            final plan = productId == 'yearly'
                ? 'annual'
                : productId == 'lifetime'
                ? 'lifetime'
                : 'monthly';
            final expiresAt = entitlement.expirationDate != null
                ? DateTime.tryParse(entitlement.expirationDate!)
                : null;
            final isTrial = entitlement.periodType == PeriodType.trial;

            state = SubscriptionState(
              isLoading: false,
              isActive: true,
              estado: isTrial ? 'prueba' : 'activa',
              plan: plan,
              expiresAt: expiresAt,
              willRenew: entitlement.willRenew,
              hasVerificationIssue: false,
            );
            return;
          }
        }
      } catch (_) {
        rcFailed = true;
      }
    }

    if (backendFailed && (!rcReached || rcFailed)) {
      if (!mounted) return;

      if (state.isActive ||
          state.estado == 'prueba' ||
          state.estado == 'activa' ||
          state.estado == 'cancelada') {
        state = state.copyWith(isLoading: false, hasVerificationIssue: true);
        return;
      }

      state = const SubscriptionState(
        isLoading: false,
        isActive: false,
        hasVerificationIssue: true,
      );
      return;
    }

    // ── Neither source says active ──────────────────────────────────
    if (mounted) {
      state = const SubscriptionState(
        isLoading: false,
        isActive: false,
        estado: 'vencida',
        hasVerificationIssue: false,
      );
    }
  }

  @override
  void dispose() {
    _service.removeCustomerInfoListener(_listener);
    super.dispose();
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      ref.watch(authProvider.select((state) => state.userId));
      return SubscriptionNotifier(
        ref.read(subscriptionServiceProvider),
        ref.read(apiServiceProvider),
      );
    });
