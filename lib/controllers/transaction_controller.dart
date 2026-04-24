import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/auth/auth_state.dart';
import '../services/transaction_service.dart';

class TransactionController extends AsyncNotifier<List<MenudoTransaction>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<MenudoTransaction>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid == null) return const [];

    return ref
        .read(transactionServiceProvider)
        .fetchTransactions(int.parse(uid));
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;

    state = const AsyncLoading<List<MenudoTransaction>>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(
      () => ref.read(transactionServiceProvider).fetchTransactions(userId),
    );
  }

  Future<MenudoTransaction?> addTransaction(
    MenudoTransaction transaction,
  ) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncLoading<List<MenudoTransaction>>().copyWithPrevious(
      state,
    );
    try {
      final created = await ref
          .read(transactionServiceProvider)
          .createTransaction(transaction);
      final transactions = await ref
          .read(transactionServiceProvider)
          .fetchTransactions(userId);
      state = AsyncValue.data(transactions);
      return created;
    } catch (error, stackTrace) {
      try {
        final transactions = await ref
            .read(transactionServiceProvider)
            .fetchTransactions(userId);
        state = AsyncValue.data(transactions);
      } catch (_) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<MenudoTransaction?> updateTransaction(
    MenudoTransaction transaction,
  ) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncLoading<List<MenudoTransaction>>().copyWithPrevious(
      state,
    );
    try {
      final updated = await ref
          .read(transactionServiceProvider)
          .updateTransaction(transaction);
      final transactions = await ref
          .read(transactionServiceProvider)
          .fetchTransactions(userId);
      state = AsyncValue.data(transactions);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    final userId = _uid();
    if (userId == 0) return;

    state = const AsyncLoading<List<MenudoTransaction>>().copyWithPrevious(
      state,
    );
    try {
      await ref
          .read(transactionServiceProvider)
          .deleteTransaction(transactionId);
      final transactions = await ref
          .read(transactionServiceProvider)
          .fetchTransactions(userId);
      state = AsyncValue.data(transactions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<MenudoTransaction>> fetchTransactionsForWallet(int walletId) {
    return ref
        .read(transactionServiceProvider)
        .fetchTransactionsForWallet(walletId);
  }
}

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, List<MenudoTransaction>>(
      TransactionController.new,
    );
