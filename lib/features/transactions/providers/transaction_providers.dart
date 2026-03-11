import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/transaction_controller.dart'
    as transaction_controller;
import '../../../controllers/demo_mode_controller.dart';
import '../../../core/data/models.dart';
import '../../budgets/budget_providers.dart';

final transactionNotifierProvider =
    transaction_controller.transactionControllerProvider;
final transactionControllerProvider =
    transaction_controller.transactionControllerProvider;

final effectiveTransactionsProvider = Provider<List<MenudoTransaction>>((ref) {
  final transactions = ref.watch(transactionNotifierProvider).valueOrNull;
  final demoMode = ref.watch(demoModeProvider);

  if (transactions != null && transactions.isNotEmpty) {
    return transactions;
  }
  if (demoMode) {
    return mockTxns;
  }
  return transactions ?? const [];
});

DateTimeRange? _budgetRangeFor(MenudoBudget? budget) {
  if (budget == null) return null;

  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final day = budget.diaInicio.clamp(1, 28);
  final period = budget.periodo.toLowerCase();

  if (period == 'mensual') {
    return DateTimeRange(
      start: DateTime(year, month, day),
      end: DateTime(year, month + 1, 0),
    );
  }

  if (period == 'quincenal') {
    final start = DateTime(year, month, day);
    return DateTimeRange(
      start: start,
      end: start.add(const Duration(days: 14)),
    );
  }

  if (period == 'semanal') {
    return DateTimeRange(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
  }

  return null;
}

final selectedBudgetPeriodTransactionsProvider =
    Provider<List<MenudoTransaction>>((ref) {
      final budget = ref.watch(selectedBudgetProvider);
      final txns = ref.watch(effectiveTransactionsProvider);

      final range = _budgetRangeFor(budget);
      if (range == null) return txns;

      return txns.where((t) {
        final date = DateTime.tryParse(t.dateString);
        if (date == null) return false;
        return !date.isBefore(range.start) && !date.isAfter(range.end);
      }).toList();
    });

final monthlyGastosProvider = Provider<List<MenudoTransaction>>((ref) {
  final txns = ref.watch(selectedBudgetPeriodTransactionsProvider);
  return txns.where((t) => t.tipo == 'gasto').toList();
});

final monthlySpentProvider = Provider<double>((ref) {
  final gastos = ref.watch(monthlyGastosProvider);
  return gastos.fold(0.0, (sum, t) => sum + t.monto.abs());
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final txns = ref.watch(selectedBudgetPeriodTransactionsProvider);
  return txns
      .where((t) => t.tipo == 'ingreso')
      .fold(0.0, (sum, t) => sum + t.monto);
});
