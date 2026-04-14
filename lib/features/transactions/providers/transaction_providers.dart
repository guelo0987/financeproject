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

bool _isTransactionWithinRange(
  MenudoTransaction transaction,
  DateTimeRange range,
) {
  final date = DateTime.tryParse(transaction.dateString);
  if (date == null) return false;
  return !date.isBefore(range.start) && !date.isAfter(range.end);
}

DateTimeRange? budgetRangeFor(MenudoBudget? budget, {DateTime? referenceDate}) {
  if (budget == null) return null;

  final now = referenceDate ?? DateTime.now();
  final todayDay = now.day;
  final day = budget.diaInicio.clamp(1, 28);
  final period = budget.periodo.toLowerCase();

  if (period == 'mensual') {
    var startYear = now.year;
    var startMonth = now.month;
    if (day > todayDay) {
      startMonth -= 1;
      if (startMonth < 1) {
        startMonth = 12;
        startYear -= 1;
      }
    }

    final start = DateTime(startYear, startMonth, day);
    return DateTimeRange(
      start: start,
      end: DateTime(startYear, startMonth + 1, day - 1),
    );
  }

  if (period == 'quincenal') {
    var startYear = now.year;
    var startMonth = now.month;
    if (day > todayDay) {
      startMonth -= 1;
      if (startMonth < 1) {
        startMonth = 12;
        startYear -= 1;
      }
    }

    final start = DateTime(startYear, startMonth, day);
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
      final budgetScoped = budget == null
          ? txns
          : txns.where((transaction) => transaction.budgetId == budget.id).toList();

      final range = budgetRangeFor(budget);
      if (range == null) return budgetScoped;

      return budgetScoped
          .where((transaction) => _isTransactionWithinRange(transaction, range))
          .toList();
    });

final currentMonthTransactionsProvider = Provider<List<MenudoTransaction>>((
  ref,
) {
  final txns = ref.watch(effectiveTransactionsProvider);
  final now = DateTime.now();
  final range = DateTimeRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
  );

  return txns
      .where((transaction) => _isTransactionWithinRange(transaction, range))
      .toList();
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

final generalMonthlySpentProvider = Provider<double>((ref) {
  final txns = ref.watch(currentMonthTransactionsProvider);
  return txns
      .where((transaction) => transaction.tipo == 'gasto')
      .fold(0.0, (sum, transaction) => sum + transaction.monto.abs());
});

final generalMonthlyIncomeProvider = Provider<double>((ref) {
  final txns = ref.watch(currentMonthTransactionsProvider);
  return txns
      .where((transaction) => transaction.tipo == 'ingreso')
      .fold(0.0, (sum, transaction) => sum + transaction.monto.abs());
});

final generalMonthlyBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(generalMonthlyIncomeProvider);
  final spent = ref.watch(generalMonthlySpentProvider);
  return income - spent;
});
