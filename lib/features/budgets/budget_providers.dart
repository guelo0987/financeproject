import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'data/budget_notifier.dart';

/// Index of the budget shown on the Dashboard.
/// Managed manually; screens should clamp to budgets.length - 1 before use.
final selectedBudgetIdxProvider = StateProvider<int>((ref) => 0);
