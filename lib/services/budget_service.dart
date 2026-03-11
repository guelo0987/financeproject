import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/budgets/data/budget_repository.dart';

class BudgetService {
  const BudgetService(this._repository);

  final BudgetRepository _repository;

  Future<List<MenudoBudget>> fetchBudgets(int userId) {
    return _repository.fetchBudgets(userId);
  }

  Future<MenudoBudget> fetchBudgetById(int budgetId) {
    return _repository.fetchBudgetById(budgetId);
  }

  Future<Map<String, double>> fetchSpentPerCategory(int budgetId) {
    return _repository.fetchSpentPerCategory(budgetId);
  }

  Future<MenudoBudget> createBudget(
    int userId,
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails,
  ) {
    return _repository.createBudget(userId, budget, catSlugToId, incomeDetails);
  }

  Future<MenudoBudget> updateBudget(
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails,
  ) {
    return _repository.updateBudget(budget, catSlugToId, incomeDetails);
  }

  Future<void> activateBudget(int budgetId) {
    return _repository.setActiveBudget(budgetId);
  }
}

final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService(ref.watch(budgetRepositoryProvider));
});
