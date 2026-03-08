import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';

/// Index of the budget shown on the Dashboard.
/// Defaults to the first active budget, or 0.
final selectedBudgetIdxProvider = StateProvider<int>((ref) {
  final idx = mockBudgets.indexWhere((b) => b.activo);
  return idx >= 0 ? idx : 0;
});
