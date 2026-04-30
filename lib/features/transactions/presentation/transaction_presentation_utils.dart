import 'package:flutter/material.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class TransactionViewPresentation {
  const TransactionViewPresentation({
    required this.prefix,
    required this.amountColor,
    required this.sourceWallet,
    required this.destinationWallet,
    this.contextTitle,
    this.contextSubtitle,
  });

  final String prefix;
  final Color amountColor;
  final WalletAccount? sourceWallet;
  final WalletAccount? destinationWallet;
  final String? contextTitle;
  final String? contextSubtitle;

  String get routeLabel {
    final from = sourceWallet?.nombre;
    final to = destinationWallet?.nombre;
    if (from == null && to == null) return 'Transferencia entre wallets';
    if (from == null) return 'Hacia ${to!}';
    if (to == null) return 'Desde $from';
    return '$from → $to';
  }
}

WalletAccount? findWalletById(List<WalletAccount> wallets, int? walletId) {
  if (walletId == null) return null;
  for (final wallet in wallets) {
    if (wallet.id == walletId) return wallet;
  }
  return null;
}

String? validateTransactionAmountAgainstWallets({
  required String transactionType,
  required double amount,
  WalletAccount? sourceWallet,
  WalletAccount? destinationWallet,
}) {
  if (amount <= 0) return null;

  final normalizedType = transactionType.trim().toLowerCase();
  final normalizedAmount = amount.abs();

  if ((normalizedType == 'gasto' || normalizedType == 'transferencia') &&
      sourceWallet != null &&
      sourceWallet.tipo != 'deudas' &&
      normalizedAmount > sourceWallet.saldo) {
    return 'Ese monto supera el saldo disponible en ${sourceWallet.nombre}.';
  }

  if (normalizedType == 'ingreso' &&
      sourceWallet != null &&
      sourceWallet.tipo == 'deudas' &&
      normalizedAmount > sourceWallet.saldo.abs()) {
    return 'Ese monto supera la deuda pendiente en ${sourceWallet.nombre}.';
  }

  if (normalizedType == 'transferencia' &&
      destinationWallet != null &&
      destinationWallet.tipo == 'deudas' &&
      normalizedAmount > destinationWallet.saldo.abs()) {
    return 'Ese monto supera la deuda pendiente en ${destinationWallet.nombre}.';
  }

  return null;
}

String formatTransactionAmountLabel(
  MenudoTransaction transaction, {
  String currencyCode = '',
}) {
  final effectiveCurrency = transactionCurrencyCode(
    transaction,
    fallbackCurrencyCode: currencyCode,
  );

  if (transaction.tipo == 'transferencia') {
    return formatMoney(transaction.monto.abs(), currency: effectiveCurrency);
  }

  final signedAmount = switch (transaction.tipo) {
    'ingreso' => transaction.monto.abs(),
    'gasto' => -transaction.monto.abs(),
    _ => transaction.monto,
  };

  return formatMoney(signedAmount, currency: effectiveCurrency, signed: true);
}

String transactionCurrencyCode(
  MenudoTransaction transaction, {
  String fallbackCurrencyCode = '',
}) {
  final fallback = fallbackCurrencyCode.trim().isEmpty
      ? AppFormattingPreferences.currencyCode
      : fallbackCurrencyCode.trim().toUpperCase();

  String? resolved(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized == 'DOP' && fallback.isNotEmpty && fallback != 'DOP') {
      return null;
    }
    return normalized;
  }

  final sourceCurrency = resolved(transaction.fromWallet?.moneda);
  if (sourceCurrency != null) {
    return sourceCurrency;
  }

  final destinationCurrency = resolved(transaction.toWallet?.moneda);
  if (destinationCurrency != null) {
    return destinationCurrency;
  }

  return resolved(transaction.moneda) ?? fallback;
}

String _walletSnapshotCurrency(String? value) {
  final fallback = AppFormattingPreferences.currencyCode;
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return fallback;
  if (normalized == 'DOP' && fallback != 'DOP') return fallback;
  return normalized;
}

Color _fallbackWalletColor(String? type) {
  switch (type) {
    case 'deudas':
      return AppColors.r5;
    case 'gastos':
      return AppColors.b5;
    default:
      return AppColors.e7;
  }
}

IconData _fallbackWalletIcon(String? type) {
  switch (type) {
    case 'deudas':
      return MenudoCupertinoIcons.alertCircle;
    case 'gastos':
      return MenudoCupertinoIcons.creditCard;
    default:
      return MenudoCupertinoIcons.landmark;
  }
}

WalletAccount? resolveTransactionWallet(
  List<WalletAccount> wallets,
  int? walletId,
  TransactionWalletInfo? snapshot,
) {
  final localWallet = findWalletById(wallets, walletId);
  if (localWallet != null) return localWallet;
  if (snapshot == null) return null;

  return WalletAccount(
    id: snapshot.id,
    nombre: snapshot.nombre,
    tipo: snapshot.tipo ?? 'cuentas',
    saldo: 0,
    color: _fallbackWalletColor(snapshot.tipo),
    icono: _fallbackWalletIcon(snapshot.tipo),
    moneda: _walletSnapshotCurrency(snapshot.moneda),
  );
}

TransactionViewPresentation buildTransactionPresentation(
  MenudoTransaction transaction,
  List<WalletAccount> wallets, {
  int? contextWalletId,
}) {
  final sourceWallet = resolveTransactionWallet(
    wallets,
    transaction.fromAccountId,
    transaction.fromWallet,
  );
  final destinationWallet = resolveTransactionWallet(
    wallets,
    transaction.toAccountId,
    transaction.toWallet,
  );

  if (transaction.tipo == 'gasto') {
    return TransactionViewPresentation(
      prefix: '-',
      amountColor: AppColors.r5,
      sourceWallet: sourceWallet,
      destinationWallet: destinationWallet,
    );
  }

  if (transaction.tipo == 'ingreso') {
    return TransactionViewPresentation(
      prefix: '+',
      amountColor: AppColors.e6,
      sourceWallet: sourceWallet,
      destinationWallet: destinationWallet,
    );
  }

  if (contextWalletId != null) {
    final contextWallet = findWalletById(wallets, contextWalletId);

    if (contextWallet != null &&
        transaction.fromAccountId == contextWallet.id) {
      return TransactionViewPresentation(
        prefix: '-',
        amountColor: contextWallet.tipo == 'deudas'
            ? AppColors.r5
            : AppColors.b5,
        sourceWallet: sourceWallet,
        destinationWallet: destinationWallet,
        contextTitle: contextWallet.tipo == 'deudas'
            ? 'Dinero tomado de esta deuda'
            : 'Salió dinero de esta cuenta',
        contextSubtitle: sourceWallet != null && destinationWallet != null
            ? 'Fue desde ${sourceWallet.nombre} hacia ${destinationWallet.nombre}.'
            : null,
      );
    }

    if (contextWallet != null && transaction.toAccountId == contextWallet.id) {
      return TransactionViewPresentation(
        prefix: '+',
        amountColor: AppColors.e6,
        sourceWallet: sourceWallet,
        destinationWallet: destinationWallet,
        contextTitle: contextWallet.tipo == 'deudas'
            ? 'Abono a la deuda'
            : 'Entró dinero a esta cuenta',
        contextSubtitle: sourceWallet != null && destinationWallet != null
            ? 'Fue desde ${sourceWallet.nombre} hacia ${destinationWallet.nombre}.'
            : null,
      );
    }
  }

  return TransactionViewPresentation(
    prefix: '',
    amountColor: AppColors.b5,
    sourceWallet: sourceWallet,
    destinationWallet: destinationWallet,
    contextTitle: 'Transferencia entre cuentas',
    contextSubtitle: sourceWallet != null && destinationWallet != null
        ? 'Fue desde ${sourceWallet.nombre} hacia ${destinationWallet.nombre}.'
        : null,
  );
}

String normalizedUiLabel(String? value) {
  return (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
}

String distinctUiLabel(String? value, {String? against}) {
  final normalizedValue = normalizedUiLabel(value);
  final normalizedAgainst = normalizedUiLabel(against);
  if (normalizedValue.isEmpty) return '';
  if (normalizedAgainst.isNotEmpty &&
      normalizedValue.toLowerCase() == normalizedAgainst.toLowerCase()) {
    return '';
  }
  return normalizedValue;
}

String joinDistinctUiLabels(Iterable<String?> values) {
  final labels = <String>[];
  final seen = <String>{};

  for (final value in values) {
    final normalized = normalizedUiLabel(value);
    if (normalized.isEmpty) continue;
    final key = normalized.toLowerCase();
    if (seen.add(key)) {
      labels.add(normalized);
    }
  }

  return labels.join(' · ');
}
