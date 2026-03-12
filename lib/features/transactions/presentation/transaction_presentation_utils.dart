import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';

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
      return LucideIcons.alertCircle;
    case 'gastos':
      return LucideIcons.creditCard;
    default:
      return LucideIcons.landmark;
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
    moneda: snapshot.moneda ?? 'DOP',
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
            : AppColors.e8,
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
