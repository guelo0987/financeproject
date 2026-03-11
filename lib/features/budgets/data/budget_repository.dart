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
    Map<int, double> incomeDetails,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.budgets,
      body: _budgetBody(budget, catSlugToId, incomeDetails),
      parser: asJsonMap,
    );
    return _budgetFromApi(response.requireData());
  }

  Future<MenudoBudget> updateBudget(
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails,
  ) async {
    if (budget.id <= 0) {
      throw StateError(
        'A budget requires a valid id before it can be updated.',
      );
    }

    final response = await _api.put<Map<String, dynamic>>(
      ApiPaths.budgetById(budget.id),
      body: _budgetBody(budget, catSlugToId, incomeDetails),
      parser: asJsonMap,
    );
    return _budgetFromApi(response.requireData());
  }

  Future<void> setActiveBudget(int presupuestoId) async {
    await _api.patch<void>(ApiPaths.activateBudget(presupuestoId));
  }

  Map<String, dynamic> _budgetBody(
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails,
  ) {
    return {
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
              'categoriaId': catSlugToId[entry.key],
              'limite': entry.value.limite,
            },
      ],
      'ingresos_detalle': [
        for (final entry in incomeDetails.entries)
          {'categoriaId': entry.key, 'monto': entry.value},
      ],
    };
  }

  MenudoBudget _budgetFromApi(Map<String, dynamic> row) {
    final categories = asJsonList(row['categorias'] ?? const []);
    final cats = <String, BudgetCategory>{};
    final incomePlan = <int, double>{};
    final incomeSources = <BudgetIncomeSource>[];

    for (final item in categories) {
      final category = asJsonMap(item);
      final slug = category['slug'] as String? ?? '';
      if (slug.isEmpty) continue;

      cats[slug] = BudgetCategory.fromJson({
        'categoria_id': category['categoriaId'] ?? category['categoria_id'],
        'categoria_padre_id':
            category['categoria_padre_id'] ?? category['parentCategoryId'],
        'slug': category['slug'],
        'nombre': category['nombre'],
        'tipo': category['tipo'],
        'icono': category['icono'],
        'color_hex': category['color_hex'],
        'limite': category['limite'],
        'gastado': category['gastado'],
      });
    }

    final actualIncomePayload = row['ingresos_actuales'];
    final incomeDetails = actualIncomePayload is Map<String, dynamic>
        ? asJsonList(actualIncomePayload['detalle'] ?? const [])
        : asJsonList(row['ingresos_detalle'] ?? const []);

    for (final item in incomeDetails) {
      final income = asJsonMap(item);
      final rawCategoryId =
          income['categoriaId'] ??
          income['categoria_id'] ??
          income['id'] ??
          income['categoryId'];
      if (rawCategoryId is! num) continue;

      final amount =
          (income['monto_planeado'] ??
                  income['monto'] ??
                  income['planned'] ??
                  income['limite'] ??
                  0)
              as num;
      incomePlan[rawCategoryId.toInt()] = amount.toDouble();
    }

    for (final item in incomeDetails) {
      final income = asJsonMap(item);
      incomeSources.add(
        BudgetIncomeSource.fromJson({
          'categoria_id':
              income['categoriaId'] ??
              income['categoria_id'] ??
              income['id'] ??
              income['categoryId'],
          'categoria_padre_id':
              income['categoria_padre_id'] ?? income['parentCategoryId'],
          'slug': income['slug'],
          'nombre': income['nombre'] ?? 'Ingresos',
          'tipo': income['tipo'] ?? 'ingreso',
          'icono': income['icono'] ?? 'trendingUp',
          'color_hex': income['color_hex'] ?? '#10B981',
          'monto_planeado':
              income['monto_planeado'] ??
              income['monto'] ??
              income['planned'] ??
              0,
          'monto_actual': income['monto_actual'] ?? income['actual'] ?? 0,
        }),
      );
    }

    return MenudoBudget.fromJson(
      {
        'presupuesto_id': row['id'] ?? row['presupuesto_id'],
        'espacio_id': row['espacio_id'],
        'nombre': row['nombre'],
        'periodo': row['periodo'],
        'dia_inicio': row['dia_inicio'],
        'activo': row['activo'],
        'ingresos': row['ingresos'],
        'ahorro_objetivo': row['ahorro_objetivo'],
      },
      cats: cats,
      incomePlan: incomePlan,
      incomeSources: incomeSources,
    );
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(apiServiceProvider));
});
