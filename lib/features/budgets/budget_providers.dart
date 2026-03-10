import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';

export 'data/budget_notifier.dart';

/// Index of the budget shown on the Dashboard.
/// Defaults to the first active budget.
final selectedBudgetIdxProvider = StateProvider<int>((ref) {
  final idx = mockBudgets.indexWhere((b) => b.activo);
  return idx >= 0 ? idx : 0;
});
