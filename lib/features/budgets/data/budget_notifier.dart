import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import '../../../features/auth/auth_state.dart';
import 'budget_repository.dart';

class BudgetNotifier extends AsyncNotifier<List<MenudoBudget>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<MenudoBudget>> build() async {
    // TODO: replace with Supabase fetch once backend is ready
    // final uid = ref.watch(authProvider).userId;
    // if (uid != null) return ref.read(budgetRepositoryProvider).fetchBudgets(int.parse(uid));
    return mockBudgets;
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(budgetRepositoryProvider).fetchBudgets(userId),
    );
  }

  Future<void> createBudget(MenudoBudget budget, Map<String, int> catSlugToId) async {
    final userId = _uid();
    if (userId == 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).createBudget(userId, budget, catSlugToId);
      return ref.read(budgetRepositoryProvider).fetchBudgets(userId);
    });
  }
}

final budgetNotifierProvider = AsyncNotifierProvider<BudgetNotifier, List<MenudoBudget>>(
  BudgetNotifier.new,
);
