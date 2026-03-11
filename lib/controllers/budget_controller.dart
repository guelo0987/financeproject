import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/auth/auth_state.dart';
import '../services/budget_service.dart';

final selectedBudgetIdxProvider = StateProvider<int>((ref) => 0);

class BudgetController extends AsyncNotifier<List<MenudoBudget>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<MenudoBudget>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid == null) return const [];

    final budgets = await ref
        .read(budgetServiceProvider)
        .fetchBudgets(int.parse(uid));
    _syncSelectedBudgetIndex(budgets);
    return budgets;
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final budgets = await ref
          .read(budgetServiceProvider)
          .fetchBudgets(userId);
      _syncSelectedBudgetIndex(budgets);
      return budgets;
    });
  }

  Future<MenudoBudget?> createBudget(
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails,
  ) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncValue.loading();
    try {
      final created = await ref
          .read(budgetServiceProvider)
          .createBudget(userId, budget, catSlugToId, incomeDetails);
      final budgets = await ref
          .read(budgetServiceProvider)
          .fetchBudgets(userId);
      _syncSelectedBudgetIndex(budgets, preferredBudgetId: created.id);
      state = AsyncValue.data(budgets);
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<MenudoBudget?> updateBudget(
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails,
  ) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncValue.loading();
    try {
      final updated = await ref
          .read(budgetServiceProvider)
          .updateBudget(budget, catSlugToId, incomeDetails);
      final budgets = await ref
          .read(budgetServiceProvider)
          .fetchBudgets(userId);
      _syncSelectedBudgetIndex(budgets, preferredBudgetId: updated.id);
      state = AsyncValue.data(budgets);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> activateBudget(int budgetId) async {
    final userId = _uid();
    if (userId == 0) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(budgetServiceProvider).activateBudget(budgetId);
      final budgets = await ref
          .read(budgetServiceProvider)
          .fetchBudgets(userId);
      _syncSelectedBudgetIndex(budgets, preferredBudgetId: budgetId);
      state = AsyncValue.data(budgets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<MenudoBudget> fetchBudgetById(int budgetId) {
    return ref.read(budgetServiceProvider).fetchBudgetById(budgetId);
  }

  Future<Map<String, double>> fetchSpentPerCategory(int budgetId) {
    return ref.read(budgetServiceProvider).fetchSpentPerCategory(budgetId);
  }

  void _syncSelectedBudgetIndex(
    List<MenudoBudget> budgets, {
    int? preferredBudgetId,
  }) {
    final notifier = ref.read(selectedBudgetIdxProvider.notifier);
    if (budgets.isEmpty) {
      notifier.state = 0;
      return;
    }

    var nextIndex = -1;
    if (preferredBudgetId != null) {
      nextIndex = budgets.indexWhere(
        (budget) => budget.id == preferredBudgetId,
      );
    }
    if (nextIndex == -1) {
      nextIndex = budgets.indexWhere((budget) => budget.activo);
    }
    if (nextIndex == -1) {
      final currentIndex = notifier.state;
      nextIndex = currentIndex.clamp(0, budgets.length - 1);
    }

    notifier.state = nextIndex;
  }
}

final budgetControllerProvider =
    AsyncNotifierProvider<BudgetController, List<MenudoBudget>>(
      BudgetController.new,
    );
