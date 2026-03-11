import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_state.dart';
import '../model/models.dart';
import '../services/wallet_service.dart';

final defaultWalletIdProvider = StateProvider<int?>((ref) => null);

class WalletController extends AsyncNotifier<List<WalletAccount>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<WalletAccount>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid == null) return const [];
    return ref.read(walletServiceProvider).fetchWallets(int.parse(uid));
  }

  Future<WalletAccount?> addWallet(WalletAccount wallet) async {
    final userId = _uid();
    if (userId == 0) return null;
    state = const AsyncValue.loading();
    try {
      final createdWallet = await ref
          .read(walletServiceProvider)
          .createWallet(userId, wallet);
      final wallets = await ref
          .read(walletServiceProvider)
          .fetchWallets(userId);
      if (ref.read(defaultWalletIdProvider) == null && wallets.isNotEmpty) {
        ref.read(defaultWalletIdProvider.notifier).state = createdWallet.id;
      }
      state = AsyncValue.data(wallets);
      return createdWallet;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<WalletAccount?> updateWallet(WalletAccount wallet) async {
    final userId = _uid();
    if (userId == 0) return null;
    state = const AsyncValue.loading();
    try {
      final updatedWallet = await ref
          .read(walletServiceProvider)
          .updateWallet(wallet);
      final wallets = await ref
          .read(walletServiceProvider)
          .fetchWallets(userId);
      state = AsyncValue.data(wallets);
      return updatedWallet;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> removeWallet(int walletId) async {
    final userId = _uid();
    if (userId == 0) return;
    final currentDefault = ref.read(defaultWalletIdProvider);
    state = const AsyncValue.loading();
    try {
      await ref.read(walletServiceProvider).deleteWallet(walletId);
      final wallets = await ref
          .read(walletServiceProvider)
          .fetchWallets(userId);
      if (currentDefault == walletId) {
        ref.read(defaultWalletIdProvider.notifier).state = wallets.isEmpty
            ? null
            : wallets.first.id;
      }
      state = AsyncValue.data(wallets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(walletServiceProvider).fetchWallets(userId),
    );
  }
}

final walletControllerProvider =
    AsyncNotifierProvider<WalletController, List<WalletAccount>>(
      WalletController.new,
    );
