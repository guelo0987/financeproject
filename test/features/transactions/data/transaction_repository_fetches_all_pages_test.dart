import 'package:financeproject/features/transactions/data/transaction_repository.dart';
import 'package:financeproject/services/api_service.dart';
import 'package:financeproject/types/api_response.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiService extends ApiService {
  _FakeApiService(this._pages);

  final Map<int, List<Map<String, dynamic>>> _pages;
  final List<Map<String, dynamic>?> calls = [];

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? payload)? parser,
  }) async {
    calls.add(queryParameters);
    final page = int.parse(queryParameters?['page']?.toString() ?? '1');
    final payload = _pages[page] ?? const <Map<String, dynamic>>[];
    final parsed = parser != null ? parser(payload) : payload as T;

    return ApiResponse<T>(
      statusCode: 200,
      success: true,
      data: parsed,
      meta: {'hasMore': page < _pages.length},
    );
  }
}

Map<String, dynamic> _txnRow(
  int id, {
  required String fecha,
  required String tipo,
  required num monto,
  required String slug,
}) {
  return {
    'id': id,
    'budgetId': 9,
    'fecha': fecha,
    'descripcion': 'Movimiento $id',
    'monto': monto,
    'tipo': tipo,
    'catKey': slug,
    'categoria': {'slug': slug, 'icono': 'circle'},
  };
}

void main() {
  test('fetchTransactions trae todas las páginas disponibles', () async {
    final api = _FakeApiService({
      1: [
        _txnRow(
          1,
          fecha: '2026-03-01',
          tipo: 'gasto',
          monto: 300,
          slug: 'delivery',
        ),
        _txnRow(
          2,
          fecha: '2026-03-02',
          tipo: 'ingreso',
          monto: 1200,
          slug: 'salario',
        ),
      ],
      2: [
        _txnRow(
          3,
          fecha: '2026-03-03',
          tipo: 'gasto',
          monto: 150,
          slug: 'cafe',
        ),
      ],
    });
    final repository = TransactionRepository(api);

    final transactions = await repository.fetchTransactions(1, budgetId: 9);

    expect(transactions, hasLength(3));
    expect(transactions.map((txn) => txn.id), [1, 2, 3]);
    expect(api.calls, hasLength(2));
    expect(api.calls.first?['page'], '1');
    expect(api.calls.last?['page'], '2');
  });
}
