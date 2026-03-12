import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/models.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';

class TransactionRepository {
  final ApiService _api;
  TransactionRepository(this._api);

  Future<List<MenudoTransaction>> fetchTransactions(
    int userId, {
    int? budgetId,
    int limit = 100,
  }) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.transactions,
      queryParameters: {'limit': limit, 'budgetId': budgetId},
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((row) => _transactionFromApi(asJsonMap(row)))
        .toList();
  }

  Future<List<MenudoTransaction>> fetchTransactionsForWallet(
    int walletId,
  ) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.walletTransactions(walletId),
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((row) => _transactionFromApi(asJsonMap(row)))
        .toList();
  }

  Future<MenudoTransaction> createTransaction(MenudoTransaction txn) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.transactions,
      body: _transactionBody(txn),
      parser: asJsonMap,
    );
    return _transactionFromApi(response.requireData());
  }

  Future<MenudoTransaction> updateTransaction(MenudoTransaction txn) async {
    if (txn.id <= 0) {
      throw StateError(
        'A transaction requires a valid id before it can be updated.',
      );
    }

    final response = await _api.put<Map<String, dynamic>>(
      ApiPaths.transactionById(txn.id),
      body: _transactionBody(txn),
      parser: asJsonMap,
    );
    return _transactionFromApi(response.requireData());
  }

  Future<void> deleteTransaction(int transactionId) async {
    await _api.delete<void>(ApiPaths.transactionById(transactionId));
  }

  Map<String, dynamic> _transactionBody(MenudoTransaction txn) {
    if (txn.budgetId == null) {
      throw StateError(
        'A transaction requires a budgetId before it can be sent to the API.',
      );
    }
    if (txn.fromAccountId == null) {
      throw StateError(
        'A transaction requires a walletId before it can be sent to the API.',
      );
    }
    if (txn.catKey.isEmpty) {
      throw StateError(
        'A transaction requires a catKey before it can be sent to the API.',
      );
    }

    return {
      'fecha': txn.dateString,
      'descripcion': txn.desc,
      'monto': txn.monto.abs(),
      'tipo': txn.tipo,
      'budgetId': txn.budgetId,
      'catKey': txn.catKey,
      'walletId': txn.fromAccountId,
      if (txn.toAccountId != null) 'toWalletId': txn.toAccountId,
      if (txn.nota != null) 'nota': txn.nota,
      'moneda': txn.moneda,
    };
  }

  MenudoTransaction _transactionFromApi(Map<String, dynamic> row) {
    final categoryPayload = row['categoria'] ?? row['categorias'];
    final category = categoryPayload == null
        ? null
        : asJsonMap(categoryPayload);
    final userPayload = row['usuario'] ?? row['usuarios'];
    final user = userPayload == null ? null : asJsonMap(userPayload);
    final walletPayload = row['wallet'] ?? row['wallet_origen'];
    final wallet = walletPayload == null ? null : asJsonMap(walletPayload);
    final toWalletPayload = row['wallet_destino'] ?? row['to_wallet'];
    final toWallet = toWalletPayload == null
        ? null
        : asJsonMap(toWalletPayload);
    final categoryId = row['catId'] ?? row['categoria_id'];
    final budgetId = row['budgetId'] ?? row['presupuesto_id'];
    final walletId = row['walletId'] ?? row['activo_id'];
    final toWalletId = row['toWalletId'] ?? row['activo_destino_id'];
    final userId =
        row['userId'] ??
        row['usuario_id'] ??
        user?['id'] ??
        user?['usuario_id'];

    return MenudoTransaction.fromJson({
      'transaccion_id': row['id'] ?? row['transaccion_id'],
      'presupuesto_id': budgetId,
      'fecha': row['fecha'],
      'descripcion': row['descripcion'],
      'monto': row['monto'],
      'tipo': row['tipo'],
      'categoria_id': categoryId,
      'categoria_icono':
          category?['icono'] as String? ?? row['categoria_icono'] ?? 'circle',
      'activo_id': walletId,
      'activo_destino_id': toWalletId,
      'nota': row['nota'],
      'moneda': row['moneda'],
      'usuario_id': userId,
      ...?wallet == null ? null : {'wallet': wallet},
      ...?toWallet == null ? null : {'wallet_destino': toWallet},
      'user_name':
          row['user_name'] ??
          row['usuario_nombre'] ??
          user?['nombre'] ??
          user?['name'],
    }, catKey: row['catKey'] as String? ?? category?['slug'] as String? ?? '');
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(apiServiceProvider));
});
