import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/recurring/data/recurring_repository.dart';

class RecurringService {
  const RecurringService(this._repository);

  final RecurringRepository _repository;

  Future<List<RecurringTransaction>> fetchRecurring(int userId) {
    return _repository.fetchRecurring(userId);
  }

  Future<RecurringTransaction> createRecurring(RecurringTransaction recurring) {
    return _repository.createRecurring(recurring);
  }

  Future<RecurringTransaction> updateRecurring(RecurringTransaction recurring) {
    return _repository.updateRecurring(recurring);
  }

  Future<void> toggleActive(int recurringId, bool active) {
    return _repository.toggleActive(recurringId, active);
  }

  Future<void> deleteRecurring(int recurringId) {
    return _repository.deleteRecurring(recurringId);
  }
}

final recurringServiceProvider = Provider<RecurringService>((ref) {
  return RecurringService(ref.watch(recurringRepositoryProvider));
});
