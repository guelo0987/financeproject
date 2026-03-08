import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import '../data/wallet_repository.dart';

// Notifier that manages the list of wallet accounts
class WalletNotifier extends AsyncNotifier<List<WalletAccount>> {
  @override
  Future<List<WalletAccount>> build() async {
    // TODO: replace 1 with real userId from authProvider
    return ref.read(walletRepositoryProvider).fetchWallets(1);
  }

  Future<void> addWallet(WalletAccount wallet) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // TODO: replace 1 with real userId from authProvider
      await ref.read(walletRepositoryProvider).createWallet(1, wallet);
      return ref.read(walletRepositoryProvider).fetchWallets(1);
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(walletRepositoryProvider).fetchWallets(1),
    );
  }
}

final walletNotifierProvider = AsyncNotifierProvider<WalletNotifier, List<WalletAccount>>(
  WalletNotifier.new,
);

// Convenience provider: total balance across all accounts
final totalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(walletNotifierProvider).valueOrNull ?? mockWallets;
  return wallets.fold(0.0, (sum, w) => sum + w.saldo);
});
