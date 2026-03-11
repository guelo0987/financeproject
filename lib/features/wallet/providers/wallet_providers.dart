import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/demo_mode_controller.dart';
import '../../../controllers/wallet_controller.dart' as wallet_controller;
import '../../../core/data/models.dart';

final walletNotifierProvider = wallet_controller.walletControllerProvider;
final defaultWalletIdProvider = wallet_controller.defaultWalletIdProvider;

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

final totalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(effectiveWalletsProvider);
  return wallets.fold(0.0, (sum, wallet) => sum + wallet.saldo);
});
