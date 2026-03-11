import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/auth/auth_state.dart';
import '../services/recurring_service.dart';

class RecurringController extends AsyncNotifier<List<RecurringTransaction>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<RecurringTransaction>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid == null) return const [];
    return ref.read(recurringServiceProvider).fetchRecurring(int.parse(uid));
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(recurringServiceProvider).fetchRecurring(userId),
    );
  }

  Future<RecurringTransaction?> addRecurring(
    RecurringTransaction recurring,
  ) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncValue.loading();
    try {
      final created = await ref
          .read(recurringServiceProvider)
          .createRecurring(recurring);
      final recurringItems = await ref
          .read(recurringServiceProvider)
          .fetchRecurring(userId);
      state = AsyncValue.data(recurringItems);
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<RecurringTransaction?> updateRecurring(
    RecurringTransaction recurring,
  ) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncValue.loading();
    try {
      final updated = await ref
          .read(recurringServiceProvider)
          .updateRecurring(recurring);
      final recurringItems = await ref
          .read(recurringServiceProvider)
          .fetchRecurring(userId);
      state = AsyncValue.data(recurringItems);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> toggle(int recurringId, bool active) async {
    final userId = _uid();
    if (userId == 0) {
      ref.invalidateSelf();
      return;
    }

    await ref.read(recurringServiceProvider).toggleActive(recurringId, active);
    state = await AsyncValue.guard(
      () => ref.read(recurringServiceProvider).fetchRecurring(userId),
    );
  }

  Future<void> remove(int recurringId) async {
    final userId = _uid();
    if (userId == 0) {
      ref.invalidateSelf();
      return;
    }

    await ref.read(recurringServiceProvider).deleteRecurring(recurringId);
    state = await AsyncValue.guard(
      () => ref.read(recurringServiceProvider).fetchRecurring(userId),
    );
  }
}

final recurringControllerProvider =
    AsyncNotifierProvider<RecurringController, List<RecurringTransaction>>(
      RecurringController.new,
    );
