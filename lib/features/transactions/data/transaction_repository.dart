import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/models.dart';
import '../../../core/network/supabase_client.dart';

class TransactionRepository {
  final SupabaseClient _client;
  TransactionRepository(this._client);

  /// Fetch all transactions for a user, joined with category slug for catKey resolution.
  Future<List<MenudoTransaction>> fetchTransactions(int userId, {int limit = 100}) async {
    final data = await _client
        .from('transacciones')
        .select('*, categorias(slug, icono)')
        .eq('usuario_id', userId)
        .order('fecha', ascending: false)
        .limit(limit);
    return data.map((row) {
      final catSlug = (row['categorias'] as Map<String, dynamic>?)?['slug'] as String? ?? '';
      final catIcono = (row['categorias'] as Map<String, dynamic>?)?['icono'] as String? ?? 'circle';
      return MenudoTransaction.fromJson({...row, 'categoria_icono': catIcono}, catKey: catSlug);
    }).toList();
  }

  /// Fetch transactions for a specific wallet account.
  Future<List<MenudoTransaction>> fetchTransactionsForWallet(int walletId) async {
    final data = await _client
        .from('transacciones')
        .select('*, categorias(slug, icono)')
        .or('activo_id.eq.$walletId,activo_destino_id.eq.$walletId')
        .order('fecha', ascending: false);
    return data.map((row) {
      final catSlug = (row['categorias'] as Map<String, dynamic>?)?['slug'] as String? ?? '';
      final catIcono = (row['categorias'] as Map<String, dynamic>?)?['icono'] as String? ?? 'circle';
      return MenudoTransaction.fromJson({...row, 'categoria_icono': catIcono}, catKey: catSlug);
    }).toList();
  }

  Future<MenudoTransaction> createTransaction(int userId, int categoriaId, MenudoTransaction txn) async {
    final row = await _client
        .from('transacciones')
        .insert({
          ...txn.toJson(),
          'usuario_id': userId,
          'categoria_id': categoriaId,
        })
        .select('*, categorias(slug, icono)')
        .single();
    final catSlug = (row['categorias'] as Map<String, dynamic>?)?['slug'] as String? ?? '';
    final catIcono = (row['categorias'] as Map<String, dynamic>?)?['icono'] as String? ?? 'circle';
    return MenudoTransaction.fromJson({...row, 'categoria_icono': catIcono}, catKey: catSlug);
  }

  Future<void> deleteTransaction(int transactionId) async {
    await _client.from('transacciones').delete().eq('transaccion_id', transactionId);
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});
