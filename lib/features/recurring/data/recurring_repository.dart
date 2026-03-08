import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/models.dart';
import '../../../core/network/supabase_client.dart';

class RecurringRepository {
  final SupabaseClient _client;
  RecurringRepository(this._client);

  Future<List<RecurringTransaction>> fetchRecurring(int userId) async {
    final data = await _client
        .from('transacciones_recurrentes')
        .select('*, categorias(slug, icono)')
        .eq('usuario_id', userId)
        .order('recurrente_id');
    return (data as List).map((row) {
      final map = row as Map<String, dynamic>;
      final catSlug = (map['categorias'] as Map<String, dynamic>?)?['slug'] as String? ?? '';
      final catIcono = (map['categorias'] as Map<String, dynamic>?)?['icono'] as String? ?? 'circle';
      return RecurringTransaction.fromJson({...map, 'categoria_icono': catIcono}, catKey: catSlug);
    }).toList();
  }

  Future<RecurringTransaction> createRecurring(int userId, int categoriaId, RecurringTransaction rec) async {
    final row = await _client
        .from('transacciones_recurrentes')
        .insert({...rec.toJson(), 'usuario_id': userId, 'categoria_id': categoriaId})
        .select('*, categorias(slug, icono)')
        .single();
    final catSlug = (row['categorias'] as Map<String, dynamic>?)?['slug'] as String? ?? '';
    final catIcono = (row['categorias'] as Map<String, dynamic>?)?['icono'] as String? ?? 'circle';
    return RecurringTransaction.fromJson({...row, 'categoria_icono': catIcono}, catKey: catSlug);
  }

  Future<void> toggleActive(int recurrenteId, bool activo) async {
    await _client
        .from('transacciones_recurrentes')
        .update({'activo': activo})
        .eq('recurrente_id', recurrenteId);
  }

  Future<void> deleteRecurring(int recurrenteId) async {
    await _client.from('transacciones_recurrentes').delete().eq('recurrente_id', recurrenteId);
  }
}

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(supabaseClientProvider));
});
