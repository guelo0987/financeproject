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
    List<String> invitedEmails,
  ) {
    return _repository.createBudget(
      userId,
      budget,
      catSlugToId,
      incomeDetails,
      invitedEmails,
    );
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

  Future<void> deleteBudget(int budgetId) {
    return _repository.deleteBudget(budgetId);
  }

  Future<List<BudgetMember>> fetchBudgetMembers(int budgetId) {
    return _repository.fetchBudgetMembers(budgetId);
  }

  Future<void> removeBudgetMember(int budgetId, int userId) {
    return _repository.removeBudgetMember(budgetId, userId);
  }
}

final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService(ref.watch(budgetRepositoryProvider));
});
