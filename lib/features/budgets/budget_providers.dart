import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/demo_mode_controller.dart';
import '../../controllers/budget_controller.dart' as budget_controller;
import '../../core/data/models.dart';

export 'data/budget_notifier.dart';

final budgetNotifierProvider = budget_controller.budgetControllerProvider;
final budgetControllerProvider = budget_controller.budgetControllerProvider;
final selectedBudgetIdxProvider = budget_controller.selectedBudgetIdxProvider;

final effectiveBudgetsProvider = Provider<List<MenudoBudget>>((ref) {
  final budgets = ref.watch(budgetNotifierProvider).valueOrNull;
  final demoMode = ref.watch(demoModeProvider);

  if (budgets != null && budgets.isNotEmpty) {
    return budgets;
  }
  if (demoMode) {
    return mockBudgets;
  }
  return budgets ?? const [];
});

final selectedBudgetProvider = Provider<MenudoBudget?>((ref) {
  final budgets = ref.watch(effectiveBudgetsProvider);
  if (budgets.isEmpty) return null;

  final selectedIdx = ref
      .watch(selectedBudgetIdxProvider)
      .clamp(0, budgets.length - 1);
  return budgets[selectedIdx];
});

final selectedBudgetIdProvider = Provider<int?>((ref) {
  return ref.watch(selectedBudgetProvider)?.id;
});
