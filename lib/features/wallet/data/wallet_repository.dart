import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/models.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/icon_utils.dart';

class WalletRepository {
  final ApiService _api;
  WalletRepository(this._api);

  Future<List<WalletAccount>> fetchWallets(int userId) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.wallets,
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((row) => _walletFromApi(asJsonMap(row)))
        .toList();
  }

  Future<WalletAccount> createWallet(int userId, WalletAccount wallet) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.wallets,
      body: _walletBody(wallet),
      parser: asJsonMap,
    );
    return _walletFromApi(response.requireData());
  }

  Future<WalletAccount> updateWallet(WalletAccount wallet) async {
    final response = await _api.put<Map<String, dynamic>>(
      ApiPaths.walletById(wallet.id),
      body: _walletBody(wallet),
      parser: asJsonMap,
    );
    return _walletFromApi(response.requireData());
  }

  Future<void> deleteWallet(int walletId) async {
    await _api.delete<void>(ApiPaths.walletById(walletId));
  }

  Map<String, dynamic> _walletBody(WalletAccount wallet) {
    return {
      'nombre': wallet.nombre,
      'tipo': _walletTypeForApi(wallet.tipo),
      'saldo': wallet.saldo.abs(),
      'moneda': wallet.moneda,
      'color_hex': colorToHex(wallet.color),
      'icono': iconToKey(wallet.icono),
    };
  }

  WalletAccount _walletFromApi(Map<String, dynamic> row) {
    final saldo = (row['saldo'] as num?)?.toDouble();
    final valorActual =
        saldo?.abs() ?? (row['valor_actual'] as num?)?.toDouble() ?? 0;

    return WalletAccount.fromJson({
      'activo_id': row['id'] ?? row['activo_id'],
      'nombre': row['nombre'],
      'tipo': row['tipo'],
      'valor_actual': valorActual,
      'color_hex': row['color_hex'],
      'icono': row['icono'],
      'moneda': row['moneda'],
    });
  }

  String _walletTypeForApi(String subtipo) {
    switch (subtipo) {
      case 'deuda':
      case 'deudas':
        return 'deudas';
      case 'ahorro':
      case 'cuentas':
        return 'cuentas';
      case 'gasto':
      case 'gastos':
        return 'gastos';
      default:
        return 'cuentas';
    }
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiServiceProvider));
});
