import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import 'budget_repository.dart';

class BudgetNotifier extends AsyncNotifier<List<MenudoBudget>> {
  @override
  Future<List<MenudoBudget>> build() async {
    // TODO: replace 1 with real userId from authProvider
    return ref.read(budgetRepositoryProvider).fetchBudgets(1);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(budgetRepositoryProvider).fetchBudgets(1),
    );
  }

  Future<void> createBudget(MenudoBudget budget, Map<String, int> catSlugToId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).createBudget(1, budget, catSlugToId);
      return ref.read(budgetRepositoryProvider).fetchBudgets(1);
    });
  }
}

final budgetNotifierProvider = AsyncNotifierProvider<BudgetNotifier, List<MenudoBudget>>(
  BudgetNotifier.new,
);
