import 'package:financeproject/core/data/models.dart';
import 'package:financeproject/core/preferences/app_preferences.dart';
import 'package:financeproject/features/transactions/presentation/transaction_presentation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MenudoTransaction _transaction({
  required int id,
  required String tipo,
  required double monto,
  String moneda = 'DOP',
}) {
  return MenudoTransaction(
    id: id,
    dateString: '2026-04-23',
    desc: 'Movimiento $id',
    catKey: 'general',
    monto: monto,
    tipo: tipo,
    icono: Icons.circle,
    moneda: moneda,
  );
}

void main() {
  setUp(() {
    AppFormattingPreferences.configure(
      locale: const Locale('es', 'DO'),
      currencyCode: 'DOP',
    );
  });

  WalletAccount wallet({
    required int id,
    required String nombre,
    required String tipo,
    required double saldo,
  }) {
    return WalletAccount(
      id: id,
      nombre: nombre,
      tipo: tipo,
      saldo: saldo,
      color: Colors.blue,
      icono: Icons.account_balance_wallet,
    );
  }

  test('formatTransactionAmountLabel usa + para ingresos', () {
    final transaction = _transaction(id: 1, tipo: 'ingreso', monto: 500);

    expect(formatTransactionAmountLabel(transaction), '+RD\$500');
  });

  test('formatTransactionAmountLabel usa - para gastos', () {
    final transaction = _transaction(id: 2, tipo: 'gasto', monto: 500);

    expect(formatTransactionAmountLabel(transaction), '-RD\$500');
  });

  test('formatTransactionAmountLabel no agrega signo a transferencias', () {
    final transaction = _transaction(id: 3, tipo: 'transferencia', monto: 500);

    expect(formatTransactionAmountLabel(transaction), 'RD\$500');
  });

  test('formatTransactionAmountLabel prioriza la moneda de la transacción', () {
    final transaction = _transaction(
      id: 4,
      tipo: 'gasto',
      monto: 500,
      moneda: 'USD',
    );

    expect(
      formatTransactionAmountLabel(transaction, currencyCode: 'DOP'),
      '-US\$500',
    );
  });

  test('formatTransactionAmountLabel corrige DOP legacy con moneda activa', () {
    final transaction = _transaction(
      id: 5,
      tipo: 'gasto',
      monto: 500,
      moneda: 'DOP',
    );

    expect(
      formatTransactionAmountLabel(transaction, currencyCode: 'USD'),
      '-US\$500',
    );
  });

  test('formatTransactionAmountLabel corrige wallet snapshot DOP legacy', () {
    final transaction = MenudoTransaction(
      id: 6,
      dateString: '2026-04-23',
      desc: 'Movimiento 6',
      catKey: 'general',
      monto: 500,
      tipo: 'gasto',
      icono: Icons.circle,
      moneda: '',
      fromWallet: const TransactionWalletInfo(
        id: 1,
        nombre: 'Cuenta legacy',
        tipo: 'cuentas',
        moneda: 'DOP',
      ),
    );

    expect(
      formatTransactionAmountLabel(transaction, currencyCode: 'USD'),
      '-US\$500',
    );
  });

  test('valida gastos mayores que el saldo disponible', () {
    final result = validateTransactionAmountAgainstWallets(
      transactionType: 'gasto',
      amount: 25,
      sourceWallet: wallet(
        id: 1,
        nombre: 'Efectivo',
        tipo: 'cuentas',
        saldo: 5,
      ),
    );

    expect(result, 'Ese monto supera el saldo disponible en Efectivo.');
  });

  test('permite gastos desde una deuda', () {
    final result = validateTransactionAmountAgainstWallets(
      transactionType: 'gasto',
      amount: 25,
      sourceWallet: wallet(id: 1, nombre: 'Tarjeta', tipo: 'deudas', saldo: -5),
    );

    expect(result, isNull);
  });

  test('valida abonos mayores que la deuda pendiente', () {
    final result = validateTransactionAmountAgainstWallets(
      transactionType: 'transferencia',
      amount: 25,
      sourceWallet: wallet(id: 1, nombre: 'Banco', tipo: 'cuentas', saldo: 100),
      destinationWallet: wallet(
        id: 2,
        nombre: 'Tarjeta',
        tipo: 'deudas',
        saldo: -5,
      ),
    );

    expect(result, 'Ese monto supera la deuda pendiente en Tarjeta.');
  });
}
