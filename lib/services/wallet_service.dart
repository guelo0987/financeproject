import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/wallet/data/wallet_repository.dart';
import '../model/models.dart';

class WalletService {
  const WalletService(this._repository);

  final WalletRepository _repository;

  Future<List<WalletAccount>> fetchWallets(int userId) {
    return _repository.fetchWallets(userId);
  }

  Future<WalletAccount> createWallet(int userId, WalletAccount wallet) {
    return _repository.createWallet(userId, wallet);
  }

  Future<WalletAccount> updateWallet(WalletAccount wallet) {
    return _repository.updateWallet(wallet);
  }

  Future<void> deleteWallet(int walletId) {
    return _repository.deleteWallet(walletId);
  }
}

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(ref.watch(walletRepositoryProvider));
});
