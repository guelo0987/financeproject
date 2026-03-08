import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import '../data/recurring_repository.dart';

class RecurringNotifier extends AsyncNotifier<List<RecurringTransaction>> {
  @override
  Future<List<RecurringTransaction>> build() async {
    // TODO: replace 1 with real userId from authProvider
    return ref.read(recurringRepositoryProvider).fetchRecurring(1);
  }

  Future<void> toggle(int id, bool activo) async {
    await ref.read(recurringRepositoryProvider).toggleActive(id, activo);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await ref.read(recurringRepositoryProvider).deleteRecurring(id);
    ref.invalidateSelf();
  }
}

final recurringNotifierProvider = AsyncNotifierProvider<RecurringNotifier, List<RecurringTransaction>>(
  RecurringNotifier.new,
);
