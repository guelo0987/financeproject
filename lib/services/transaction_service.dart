import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/transactions/data/transaction_repository.dart';

class TransactionService {
  const TransactionService(this._repository);

  final TransactionRepository _repository;

  Future<List<MenudoTransaction>> fetchTransactions(
    int userId, {
    int? budgetId,
    int limit = 100,
  }) {
    return _repository.fetchTransactions(
      userId,
      budgetId: budgetId,
      limit: limit,
    );
  }

  Future<List<MenudoTransaction>> fetchTransactionsForWallet(int walletId) {
    return _repository.fetchTransactionsForWallet(walletId);
  }

  Future<MenudoTransaction> createTransaction(MenudoTransaction transaction) {
    return _repository.createTransaction(transaction);
  }

  Future<MenudoTransaction> updateTransaction(MenudoTransaction transaction) {
    return _repository.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(int transactionId) {
    return _repository.deleteTransaction(transactionId);
  }
}

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.watch(transactionRepositoryProvider));
});
