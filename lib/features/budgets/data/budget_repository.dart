import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/models.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';

class BudgetRepository {
  final ApiService _api;
  BudgetRepository(this._api);

  Future<List<MenudoBudget>> fetchBudgets(int userId) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.budgets,
      parser: asJsonList,
    );
    final rows = response.requireData();
    return Future.wait(
      rows.map((row) {
        final map = asJsonMap(row);
        final budgetId = (map['id'] ?? map['presupuesto_id'] as num).toInt();
        return fetchBudgetById(budgetId);
      }),
    );
  }

  Future<MenudoBudget> fetchBudgetById(int budgetId) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiPaths.budgetById(budgetId),
      parser: asJsonMap,
    );
    return _budgetFromApi(response.requireData());
  }

  Future<Map<String, double>> fetchSpentPerCategory(int presupuestoId) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.budgetSpending(presupuestoId),
      parser: asJsonList,
    );
    final data = response.requireData();
    final result = <String, double>{};
    for (final row in data) {
      final map = asJsonMap(row);
      final categoryPayload = map['category'] ?? map['categorias'];
      final category = categoryPayload == null
          ? null
          : asJsonMap(categoryPayload);
      final slug = map['slug'] as String? ?? category?['slug'] as String? ?? '';
      final monto =
          (map['spent'] ?? map['gastado'] ?? map['monto'] ?? 0) as num;
      result[slug] = (result[slug] ?? 0) + monto;
    }
    return result;
  }

  Future<MenudoBudget> createBudget(
    int userId,
    MenudoBudget budget,
    Map<String, int> catSlugToId,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.budgets,
      body: {
        'nombre': budget.nombre,
        'periodo': budget.periodo,
        'dia_inicio': budget.diaInicio,
        'ingresos': budget.ingresos,
        'ahorro_objetivo': budget.ahorroObjetivo,
        'activo': budget.activo,
        'espacio_id': budget.espacioId,
        'categorias': [
          for (final entry in budget.cats.entries)
            if (catSlugToId[entry.key] != null)
              {
                'categoryId': catSlugToId[entry.key],
                'limite': entry.value.limite,
              },
        ],
      },
      parser: asJsonMap,
    );
    return _budgetFromApi(response.requireData());
  }

  Future<void> setActiveBudget(int presupuestoId, int userId) async {
    await _api.patch<void>(ApiPaths.activateBudget(presupuestoId));
  }

  MenudoBudget _budgetFromApi(Map<String, dynamic> row) {
    final categories = asJsonList(row['categorias'] ?? const []);
    final cats = <String, BudgetCategory>{};

    for (final item in categories) {
      final category = asJsonMap(item);
      final slug = category['slug'] as String? ?? '';
      if (slug.isEmpty) continue;

      cats[slug] = BudgetCategory.fromJson({
        'categoria_id': category['categoriaId'],
        'nombre': category['nombre'],
        'icono': category['icono'],
        'limite': category['limite'],
        'gastado': category['gastado'],
      });
    }

    return MenudoBudget.fromJson({
      'presupuesto_id': row['id'] ?? row['presupuesto_id'],
      'espacio_id': row['espacio_id'],
      'nombre': row['nombre'],
      'periodo': row['periodo'],
      'dia_inicio': row['dia_inicio'],
      'activo': row['activo'],
      'ingresos': row['ingresos'],
      'ahorro_objetivo': row['ahorro_objetivo'],
    }, cats: cats);
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(apiServiceProvider));
});
