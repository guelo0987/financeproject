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
    final response = await _api.get<Map<String, dynamic>>(
      ApiPaths.budgetSpending(presupuestoId),
      parser: asJsonMap,
    );
    final data = response.requireData();
    final result = <String, double>{};
    final categories = asJsonList(data['categorias'] ?? const []);
    final others = asJsonList(data['otros_gastos'] ?? const []);

    for (final row in categories) {
      final map = asJsonMap(row);
      final slug = map['slug'] as String? ?? '';
      final monto =
          (map['spent'] ?? map['gastado'] ?? map['monto'] ?? 0) as num;
      result[slug] = (result[slug] ?? 0) + monto;
    }
    for (final row in others) {
      final map = asJsonMap(row);
      final slug =
          map['slug'] as String? ??
          'other:${(map['categoriaId'] ?? map['categoria_id'] ?? 'na')}';
      final monto = (map['gastado'] ?? map['monto'] ?? 0) as num;
      result[slug] = (result[slug] ?? 0) + monto;
    }
    return result;
  }

  Future<MenudoBudget> createBudget(
    int userId,
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails,
    List<String> invitedEmails,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.budgets,
      body: _budgetBody(
        budget,
        catSlugToId,
        incomeDetails,
        invitedEmails: invitedEmails,
      ),
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

  Future<void> deleteBudget(int budgetId) {
    return _api.delete<void>(ApiPaths.budgetById(budgetId));
  }

  Future<List<BudgetMember>> fetchBudgetMembers(int budgetId) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.budgetMembers(budgetId),
      parser: asJsonList,
    );
    return response.requireData().map((row) {
      return BudgetMember.fromJson(asJsonMap(row));
    }).toList();
  }

  Future<void> removeBudgetMember(int budgetId, int userId) {
    return _api.delete<void>(ApiPaths.budgetMemberById(budgetId, userId));
  }

  Future<void> inviteBudgetMember(int budgetId, String email) {
    return _api.post<void>(
      ApiPaths.budgetInvite(budgetId),
      body: {'email': email.trim()},
    );
  }

  Map<String, dynamic> _budgetBody(
    MenudoBudget budget,
    Map<String, int> catSlugToId,
    Map<int, double> incomeDetails, {
    List<String> invitedEmails = const [],
  }) {
    return {
      'nombre': budget.nombre,
      'periodo': budget.periodo,
      'dia_inicio': budget.diaInicio,
      'ingresos': budget.ingresos,
      'ahorro_objetivo': budget.ahorroObjetivo,
      'activo': budget.activo,
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
      if (invitedEmails.isNotEmpty)
        'invitados': invitedEmails.map((email) => email.trim()).toList(),
    };
  }

  MenudoBudget _budgetFromApi(Map<String, dynamic> row) {
    final categories = asJsonList(row['categorias'] ?? const []);
    final otherExpensesRaw = asJsonList(row['otros_gastos'] ?? const []);
    final cats = <String, BudgetCategory>{};
    final otherExpenses = <BudgetCategory>[];
    final incomePlan = <int, double>{};
    final incomeSources = <BudgetIncomeSource>[];
    final otherIncomeSources = <BudgetIncomeSource>[];

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

    for (final item in otherExpensesRaw) {
      final category = asJsonMap(item);
      otherExpenses.add(
        BudgetCategory.fromJson({
          'categoria_id': category['categoriaId'] ?? category['categoria_id'],
          'categoria_padre_id':
              category['categoria_padre_id'] ?? category['parentCategoryId'],
          'slug': category['slug'],
          'nombre': category['nombre'],
          'tipo': category['tipo'],
          'icono': category['icono'],
          'color_hex': category['color_hex'],
          'limite': 0,
          'gastado': category['gastado'],
        }),
      );
    }

    final actualIncomePayload = row['ingresos_actuales'];
    final incomeDetails = actualIncomePayload is Map<String, dynamic>
        ? asJsonList(actualIncomePayload['detalle'] ?? const [])
        : asJsonList(row['ingresos_detalle'] ?? const []);
    final otherIncomeDetails = actualIncomePayload is Map<String, dynamic>
        ? asJsonList(actualIncomePayload['otros_ingresos'] ?? const [])
        : const <dynamic>[];

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

    for (final item in otherIncomeDetails) {
      final income = asJsonMap(item);
      otherIncomeSources.add(
        BudgetIncomeSource.fromJson({
          'categoria_id':
              income['categoriaId'] ??
              income['categoria_id'] ??
              income['id'] ??
              income['categoryId'],
          'categoria_padre_id':
              income['categoria_padre_id'] ?? income['parentCategoryId'],
          'slug': income['slug'],
          'nombre': income['nombre'] ?? 'Ingreso extra',
          'tipo': income['tipo'] ?? 'ingreso',
          'icono': income['icono'] ?? 'trendingUp',
          'color_hex': income['color_hex'] ?? '#10B981',
          'monto_planeado': 0,
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
      otherExpenses: otherExpenses,
      incomePlan: incomePlan,
      incomeSources: incomeSources,
      otherIncomeSources: otherIncomeSources,
      totalSpentReal: (row['total_gastado_real'] as num?)?.toDouble(),
      totalIncomeActual: actualIncomePayload is Map<String, dynamic>
          ? (actualIncomePayload['total_actual'] as num?)?.toDouble()
          : null,
    );
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(apiServiceProvider));
});
