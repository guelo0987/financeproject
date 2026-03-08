import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import '../data/transaction_repository.dart';

class TransactionNotifier extends AsyncNotifier<List<MenudoTransaction>> {
  @override
  Future<List<MenudoTransaction>> build() async {
    // TODO: replace 1 with real userId from authProvider
    return ref.read(transactionRepositoryProvider).fetchTransactions(1);
  }

  Future<void> addTransaction(int categoriaId, MenudoTransaction txn) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // TODO: replace 1 with real userId from authProvider
      await ref.read(transactionRepositoryProvider).createTransaction(1, categoriaId, txn);
      return ref.read(transactionRepositoryProvider).fetchTransactions(1);
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(transactionRepositoryProvider).fetchTransactions(1),
    );
  }
}

final transactionNotifierProvider =
    AsyncNotifierProvider<TransactionNotifier, List<MenudoTransaction>>(
  TransactionNotifier.new,
);

// Filtered provider: only gastos for the current month
final monthlyGastosProvider = Provider<List<MenudoTransaction>>((ref) {
  final txns = ref.watch(transactionNotifierProvider).valueOrNull ?? mockTxns;
  final now = DateTime.now();
  return txns.where((t) {
    if (t.tipo != 'gasto') return false;
    final date = DateTime.tryParse(t.dateString);
    return date != null && date.year == now.year && date.month == now.month;
  }).toList();
});

// Total spent this month
final monthlySpentProvider = Provider<double>((ref) {
  final gastos = ref.watch(monthlyGastosProvider);
  return gastos.fold(0.0, (sum, t) => sum + t.monto.abs());
});

// Total income this month
final monthlyIncomeProvider = Provider<double>((ref) {
  final txns = ref.watch(transactionNotifierProvider).valueOrNull ?? mockTxns;
  final now = DateTime.now();
  return txns
      .where((t) {
        if (t.tipo != 'ingreso') return false;
        final date = DateTime.tryParse(t.dateString);
        return date != null && date.year == now.year && date.month == now.month;
      })
      .fold(0.0, (sum, t) => sum + t.monto);
});
