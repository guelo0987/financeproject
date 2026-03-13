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
    final authState = ref.watch(authProvider);
    final uid = authState.userId;
    if (uid == null) return const [];

    final budgets = await ref
        .read(budgetServiceProvider)
        .fetchBudgets(int.parse(uid));
    _syncSelectedBudgetIndex(
      budgets,
      preferredBudgetId: authState.profile?.defaultBudgetId,
    );
    return budgets;
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;
    final currentSelectedBudgetId = _currentSelectedBudgetId();

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final budgets = await ref
          .read(budgetServiceProvider)
          .fetchBudgets(userId);
      _syncSelectedBudgetIndex(
        budgets,
        preferredBudgetId: currentSelectedBudgetId,
      );
      return budgets;
    });
  }

  Future<MenudoBudget?> createBudget(
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails, {
    List<String> invitedEmails = const [],
  }) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncValue.loading();
    try {
      final created = await ref
          .read(budgetServiceProvider)
          .createBudget(
            userId,
            budget,
            catSlugToId,
            incomeDetails,
            invitedEmails,
          );
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

  Future<void> deleteBudget(int budgetId) async {
    final userId = _uid();
    if (userId == 0) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(budgetServiceProvider).deleteBudget(budgetId);
      final budgets = await ref
          .read(budgetServiceProvider)
          .fetchBudgets(userId);
      _syncSelectedBudgetIndex(budgets);
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

  Future<List<BudgetMember>> fetchBudgetMembers(int budgetId) {
    return ref.read(budgetServiceProvider).fetchBudgetMembers(budgetId);
  }

  Future<void> removeBudgetMember(int budgetId, int targetUserId) async {
    final userId = _uid();
    if (userId == 0) return;

    await ref
        .read(budgetServiceProvider)
        .removeBudgetMember(budgetId, targetUserId);
    await refresh();
  }

  Future<void> inviteBudgetMember(int budgetId, String email) async {
    final userId = _uid();
    if (userId == 0) return;

    await ref.read(budgetServiceProvider).inviteBudgetMember(budgetId, email);
    await refresh();
  }

  void selectBudgetLocally(int budgetId) {
    final budgets = state.valueOrNull ?? const <MenudoBudget>[];
    if (budgets.isEmpty) return;

    final nextIndex = budgets.indexWhere((budget) => budget.id == budgetId);
    if (nextIndex == -1) return;

    ref.read(selectedBudgetIdxProvider.notifier).state = nextIndex;
  }

  Future<void> selectBudget(int budgetId, {bool persist = false}) async {
    selectBudgetLocally(budgetId);
    if (!persist) return;
    await ref.read(authProvider.notifier).setDefaultBudget(budgetId);
  }

  int? _currentSelectedBudgetId() {
    final budgets = state.valueOrNull;
    if (budgets == null || budgets.isEmpty) return null;

    final selectedIdx = ref.read(selectedBudgetIdxProvider);
    if (selectedIdx < 0 || selectedIdx >= budgets.length) return null;

    return budgets[selectedIdx].id;
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
