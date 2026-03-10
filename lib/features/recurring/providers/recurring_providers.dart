import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import '../../../features/auth/auth_state.dart';
import '../data/recurring_repository.dart';

class RecurringNotifier extends AsyncNotifier<List<RecurringTransaction>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<RecurringTransaction>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid != null) {
      return ref
          .read(recurringRepositoryProvider)
          .fetchRecurring(int.parse(uid));
    }
    return mockRecurring;
  }

  Future<void> toggle(int id, bool activo) async {
    await ref.read(recurringRepositoryProvider).toggleActive(id, activo);
    final userId = _uid();
    if (userId == 0) {
      ref.invalidateSelf();
      return;
    }
    state = await AsyncValue.guard(
      () => ref.read(recurringRepositoryProvider).fetchRecurring(userId),
    );
  }

  Future<void> remove(int id) async {
    await ref.read(recurringRepositoryProvider).deleteRecurring(id);
    final userId = _uid();
    if (userId == 0) {
      ref.invalidateSelf();
      return;
    }
    state = await AsyncValue.guard(
      () => ref.read(recurringRepositoryProvider).fetchRecurring(userId),
    );
  }
}

final recurringNotifierProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringTransaction>>(
      RecurringNotifier.new,
    );
