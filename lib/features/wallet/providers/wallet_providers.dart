import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import '../../../features/auth/auth_state.dart';
import '../data/wallet_repository.dart';

// Notifier that manages the list of wallet accounts
class WalletNotifier extends AsyncNotifier<List<WalletAccount>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<WalletAccount>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid == null) return [];
    return ref.read(walletRepositoryProvider).fetchWallets(int.parse(uid));
  }

  Future<void> addWallet(WalletAccount wallet) async {
    final userId = _uid();
    if (userId == 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(walletRepositoryProvider).createWallet(userId, wallet);
      return ref.read(walletRepositoryProvider).fetchWallets(userId);
    });
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(walletRepositoryProvider).fetchWallets(userId),
    );
  }
}

final walletNotifierProvider = AsyncNotifierProvider<WalletNotifier, List<WalletAccount>>(
  WalletNotifier.new,
);

// Convenience provider: total balance across all accounts
final totalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(walletNotifierProvider).valueOrNull ?? [];
  return wallets.fold(0.0, (sum, w) => sum + w.saldo);
});
