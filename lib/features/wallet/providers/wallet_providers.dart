import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/demo_mode_controller.dart';
import '../../../controllers/wallet_controller.dart' as wallet_controller;
import '../../../core/data/models.dart';

final walletNotifierProvider = wallet_controller.walletControllerProvider;

final effectiveWalletsProvider = Provider<List<WalletAccount>>((ref) {
  final wallets = ref.watch(walletNotifierProvider).valueOrNull;
  final demoMode = ref.watch(demoModeProvider);

  if (wallets != null && wallets.isNotEmpty) {
    return wallets;
  }
  if (demoMode) {
    return mockWallets;
  }
  return wallets ?? const [];
});

final defaultWalletProvider = Provider<WalletAccount?>((ref) {
  final wallets = ref.watch(effectiveWalletsProvider);
  for (final wallet in wallets) {
    if (wallet.esDefault) {
      return wallet;
    }
  }
  return wallets.isNotEmpty ? wallets.first : null;
});

final defaultWalletIdProvider = Provider<int?>((ref) {
  return ref.watch(defaultWalletProvider)?.id;
});

final netWorthWalletsProvider = Provider<List<WalletAccount>>((ref) {
  final wallets = ref.watch(effectiveWalletsProvider);
  return wallets
      .where((wallet) => wallet.incluirEnPatrimonio)
      .toList(growable: false);
});

final excludedFromNetWorthWalletsProvider = Provider<List<WalletAccount>>((
  ref,
) {
  final wallets = ref.watch(effectiveWalletsProvider);
  return wallets
      .where((wallet) => !wallet.incluirEnPatrimonio)
      .toList(growable: false);
});

final totalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(netWorthWalletsProvider);
  return wallets.fold(0.0, (sum, wallet) => sum + wallet.saldo);
});
