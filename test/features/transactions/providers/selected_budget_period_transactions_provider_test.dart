import 'package:financeproject/core/data/models.dart';
import 'package:financeproject/features/budgets/budget_providers.dart';
import 'package:financeproject/features/transactions/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String _isoDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

MenudoTransaction _txn(int id, DateTime date) {
  return MenudoTransaction(
    id: id,
    dateString: _isoDate(date),
    desc: 'Movimiento $id',
    catKey: 'delivery',
    monto: -250,
    tipo: 'gasto',
    icono: Icons.circle,
  );
}

void main() {
  test(
    'budgetRangeFor mensual retrocede al ciclo anterior si el inicio no ha llegado',
    () {
      const budget = MenudoBudget(
        id: 1,
        nombre: 'Casa',
        periodo: 'mensual',
        diaInicio: 25,
        activo: true,
        miembros: [],
        ingresos: 4000,
        cats: {},
      );

      final range = budgetRangeFor(
        budget,
        referenceDate: DateTime(2026, 3, 14),
      );

      expect(range, isNotNull);
      expect(range!.start, DateTime(2026, 2, 25));
      expect(range.end, DateTime(2026, 3, 24));
    },
  );

  test(
    'selectedBudgetPeriodTransactionsProvider filtra el ciclo quincenal correcto',
    () {
      const budget = MenudoBudget(
        id: 1,
        nombre: 'Casa',
        periodo: 'quincenal',
        diaInicio: 20,
        activo: true,
        miembros: [],
        ingresos: 4000,
        cats: {},
      );

      final range = budgetRangeFor(
        budget,
        referenceDate: DateTime(2026, 3, 14),
      );

      expect(range, isNotNull);

      final insideStart = _txn(1, range!.start);
      final insideEnd = _txn(2, range.end);
      final outside = _txn(3, range.start.subtract(const Duration(days: 1)));

      final container = ProviderContainer(
        overrides: [
          selectedBudgetProvider.overrideWith((ref) => budget),
          effectiveTransactionsProvider.overrideWith(
            (ref) => [insideStart, insideEnd, outside],
          ),
        ],
      );
      addTearDown(container.dispose);

      final filtered = container.read(selectedBudgetPeriodTransactionsProvider);

      expect(filtered.map((txn) => txn.id), [1, 2]);
    },
  );
}
