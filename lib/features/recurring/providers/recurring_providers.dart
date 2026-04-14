import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/recurring_controller.dart' as recurring_controller;
import '../../../controllers/demo_mode_controller.dart';
import '../../../core/data/models.dart';

final recurringNotifierProvider =
    recurring_controller.recurringControllerProvider;
final recurringControllerProvider =
    recurring_controller.recurringControllerProvider;

final effectiveRecurringProvider = Provider<List<RecurringTransaction>>((ref) {
  final recurring = ref.watch(recurringNotifierProvider).valueOrNull;
  final demoMode = ref.watch(demoModeProvider);

  if (recurring != null && recurring.isNotEmpty) {
    return recurring;
  }
  if (demoMode) {
    return mockRecurring;
  }
  return recurring ?? const [];
});

final selectedBudgetRecurringProvider = Provider<List<RecurringTransaction>>((
  ref,
) {
  return ref.watch(effectiveRecurringProvider);
});
