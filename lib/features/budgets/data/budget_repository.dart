import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/models.dart';
import '../../../core/network/supabase_client.dart';

class BudgetRepository {
  final SupabaseClient _client;
  BudgetRepository(this._client);

  Future<List<MenudoBudget>> fetchBudgets(int userId) async {
    final data = await _client
        .from('presupuestos')
        .select('*, presupuesto_categorias(limite, categorias(categoria_id, nombre, slug, icono, color_hex))')
        .eq('usuario_id', userId)
        .order('presupuesto_id');

    return (data as List).map((row) {
      final map = row as Map<String, dynamic>;
      final catRows = (map['presupuesto_categorias'] as List? ?? []);
      final cats = <String, BudgetCategory>{};
      for (final cr in catRows) {
        final catMap = cr as Map<String, dynamic>;
        final cat = catMap['categorias'] as Map<String, dynamic>?;
        if (cat == null) continue;
        final slug = cat['slug'] as String? ?? cat['nombre'] as String;
        cats[slug] = BudgetCategory.fromJson({
          'nombre': cat['nombre'],
          'icono': cat['icono'],
          'color_hex': cat['color_hex'],
          'limite': catMap['limite'],
          'gastado': 0.0, // computed separately via transaction sums
        });
      }
      return MenudoBudget.fromJson(map, cats: cats);
    }).toList();
  }

  /// Compute spent per category for a budget by summing transactions.
  Future<Map<String, double>> fetchSpentPerCategory(int presupuestoId) async {
    final data = await _client
        .from('transacciones')
        .select('monto, categorias(slug)')
        .eq('presupuesto_id', presupuestoId)
        .eq('tipo', 'gasto');
    final result = <String, double>{};
    for (final row in (data as List)) {
      final map = row as Map<String, dynamic>;
      final slug = ((map['categorias'] as Map<String, dynamic>?)?['slug'] as String?) ?? '';
      final monto = (map['monto'] as num).toDouble();
      result[slug] = (result[slug] ?? 0) + monto;
    }
    return result;
  }

  Future<MenudoBudget> createBudget(int userId, MenudoBudget budget, Map<String, int> catSlugToId) async {
    // Insert budget
    final row = await _client
        .from('presupuestos')
        .insert({...budget.toJson(), 'usuario_id': userId})
        .select()
        .single();
    final presupuestoId = row['presupuesto_id'] as int;

    // Insert category limits
    if (catSlugToId.isNotEmpty && budget.cats.isNotEmpty) {
      final catInserts = budget.cats.entries.map((e) {
        final catId = catSlugToId[e.key];
        if (catId == null) return null;
        return {'presupuesto_id': presupuestoId, 'categoria_id': catId, 'limite': e.value.limite};
      }).whereType<Map<String, dynamic>>().toList();
      if (catInserts.isNotEmpty) {
        await _client.from('presupuesto_categorias').insert(catInserts);
      }
    }

    return fetchBudgets(userId).then((list) => list.firstWhere((b) => b.id == presupuestoId));
  }

  Future<void> setActiveBudget(int presupuestoId, int userId) async {
    // Deactivate all, then activate the selected one
    await _client.from('presupuestos').update({'activo': false}).eq('usuario_id', userId);
    await _client.from('presupuestos').update({'activo': true}).eq('presupuesto_id', presupuestoId);
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(supabaseClientProvider));
});
