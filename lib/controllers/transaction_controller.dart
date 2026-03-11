import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/auth/auth_state.dart';
import '../features/budgets/budget_providers.dart';
import '../services/transaction_service.dart';

class TransactionController extends AsyncNotifier<List<MenudoTransaction>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<MenudoTransaction>> build() async {
    final uid = ref.watch(authProvider).userId;
    final budgetId = ref.watch(selectedBudgetIdProvider);
    if (uid == null) return const [];

    return ref.read(transactionServiceProvider).fetchTransactions(
      int.parse(uid),
      budgetId: budgetId,
    );
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;

    final budgetId = ref.read(selectedBudgetIdProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(transactionServiceProvider)
          .fetchTransactions(userId, budgetId: budgetId),
    );
  }

  Future<MenudoTransaction?> addTransaction(MenudoTransaction transaction) async {
    final userId = _uid();
    if (userId == 0) return null;

    final budgetId = ref.read(selectedBudgetIdProvider);
    state = const AsyncValue.loading();
    try {
      final created = await ref
          .read(transactionServiceProvider)
          .createTransaction(transaction);
      final transactions = await ref
          .read(transactionServiceProvider)
          .fetchTransactions(userId, budgetId: budgetId);
      state = AsyncValue.data(transactions);
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<MenudoTransaction?> updateTransaction(
    MenudoTransaction transaction,
  ) async {
    final userId = _uid();
    if (userId == 0) return null;

    final budgetId = ref.read(selectedBudgetIdProvider);
    state = const AsyncValue.loading();
    try {
      final updated = await ref
          .read(transactionServiceProvider)
          .updateTransaction(transaction);
      final transactions = await ref
          .read(transactionServiceProvider)
          .fetchTransactions(userId, budgetId: budgetId);
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

    final budgetId = ref.read(selectedBudgetIdProvider);
    state = const AsyncValue.loading();
    try {
      await ref.read(transactionServiceProvider).deleteTransaction(transactionId);
      final transactions = await ref
          .read(transactionServiceProvider)
          .fetchTransactions(userId, budgetId: budgetId);
      state = AsyncValue.data(transactions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<MenudoTransaction>> fetchTransactionsForWallet(int walletId) {
    return ref.read(transactionServiceProvider).fetchTransactionsForWallet(
      walletId,
    );
  }
}

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, List<MenudoTransaction>>(
      TransactionController.new,
    );
