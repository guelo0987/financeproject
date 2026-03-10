import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/models.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';

class RecurringRepository {
  final ApiService _api;
  RecurringRepository(this._api);

  Future<List<RecurringTransaction>> fetchRecurring(int userId) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.recurringTransactions,
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((row) => _recurringFromApi(asJsonMap(row)))
        .toList();
  }

  Future<RecurringTransaction> createRecurring(
    int userId,
    int categoriaId,
    RecurringTransaction rec,
  ) async {
    if (rec.presupuestoId == null) {
      throw StateError(
        'A recurring transaction requires a budgetId before it can be sent to the API.',
      );
    }

    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.recurringTransactions,
      body: {
        'budgetId': rec.presupuestoId,
        'walletId': rec.accountId,
        'catKey': rec.catKey.isEmpty ? null : rec.catKey,
        'tipo': rec.tipo,
        'monto': rec.monto.abs(),
        'moneda': 'DOP',
        'descripcion': rec.desc,
        'nota': rec.nota,
        'frecuencia': rec.frecuencia,
        'diaEjecucion': rec.diaEjecucion,
        'activo': rec.activo,
      },
      parser: asJsonMap,
    );
    return _recurringFromApi(response.requireData());
  }

  Future<void> toggleActive(int recurrenteId, bool activo) async {
    await _api.patch<void>(ApiPaths.toggleRecurring(recurrenteId));
  }

  Future<void> deleteRecurring(int recurrenteId) async {
    await _api.delete<void>(ApiPaths.recurringById(recurrenteId));
  }

  RecurringTransaction _recurringFromApi(Map<String, dynamic> row) {
    return RecurringTransaction.fromJson({
      'recurrente_id': row['id'] ?? row['recurrente_id'],
      'presupuesto_id': row['budgetId'] ?? row['presupuesto_id'],
      'activo_id': row['walletId'] ?? row['activo_id'],
      'categoria_id': row['categoriaId'] ?? row['categoria_id'],
      'descripcion': row['descripcion'],
      'tipo': row['tipo'],
      'monto': row['monto'],
      'categoria_icono': row['categoria_icono'] ?? 'circle',
      'frecuencia': row['frecuencia'],
      'dia_ejecucion': row['diaEjecucion'] ?? row['dia_ejecucion'],
      'activo': row['activo'],
      'nota': row['nota'],
    }, catKey: row['catKey'] as String? ?? '');
  }
}

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(apiServiceProvider));
});
