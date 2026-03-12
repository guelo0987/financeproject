import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_state.dart';
import '../model/models.dart';
import '../services/alert_service.dart';
import 'budget_controller.dart';
import 'space_controller.dart';

final unreadAlertsCountProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(authProvider).userId;
  if (uid == null) return 0;
  return ref.watch(alertServiceProvider).fetchUnreadCount();
});

class AlertController extends AsyncNotifier<List<AppAlert>> {
  @override
  Future<List<AppAlert>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid == null) return const [];
    return ref.read(alertServiceProvider).fetchAlerts();
  }

  Future<void> refresh({bool unreadOnly = false}) async {
    final uid = ref.read(authProvider).userId;
    if (uid == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(alertServiceProvider).fetchAlerts(unreadOnly: unreadOnly),
    );
    ref.invalidate(unreadAlertsCountProvider);
  }

  Future<void> markAsRead(int alertId) async {
    final current = state.valueOrNull ?? const <AppAlert>[];
    final updated = await ref.read(alertServiceProvider).markAsRead(alertId);
    state = AsyncValue.data([
      for (final alert in current)
        if (alert.id == alertId) updated else alert,
    ]);
    ref.invalidate(unreadAlertsCountProvider);
  }

  Future<void> markAllAsRead() async {
    await ref.read(alertServiceProvider).markAllAsRead();
    final current = state.valueOrNull ?? const <AppAlert>[];
    state = AsyncValue.data([
      for (final alert in current) alert.copyWith(isRead: true),
    ]);
    ref.invalidate(unreadAlertsCountProvider);
  }

  Future<void> acceptInvitation(AppAlert alert, String email) async {
    final token = alert.extra.token?.trim();
    if (token == null || token.isEmpty) {
      throw StateError('La alerta no contiene un token de invitación válido.');
    }

    await ref
        .read(alertServiceProvider)
        .acceptInvitation(token: token, email: email);
    await markAsRead(alert.id);
    await ref.read(budgetControllerProvider.notifier).refresh();
    ref.invalidate(spaceControllerProvider);
  }
}

final alertControllerProvider =
    AsyncNotifierProvider<AlertController, List<AppAlert>>(AlertController.new);
