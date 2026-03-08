import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/models.dart';
import '../../../core/network/supabase_client.dart';

class WalletRepository {
  final SupabaseClient _client;
  WalletRepository(this._client);

  Future<List<WalletAccount>> fetchWallets(int userId) async {
    final data = await _client
        .from('activos')
        .select()
        .eq('usuario_id', userId)
        .eq('activo', true)
        .order('activo_id');
    return data.map((row) => WalletAccount.fromJson(row)).toList();
  }

  Future<WalletAccount> createWallet(int userId, WalletAccount wallet) async {
    final row = await _client
        .from('activos')
        .insert({
          ...wallet.toJson(),
          'usuario_id': userId,
          'tipo': _tipoActivoFromSubtipo(wallet.tipo),
          'activo': true,
        })
        .select()
        .single();
    return WalletAccount.fromJson(row);
  }

  Future<WalletAccount> updateWallet(WalletAccount wallet) async {
    final row = await _client
        .from('activos')
        .update(wallet.toJson())
        .eq('activo_id', wallet.id)
        .select()
        .single();
    return WalletAccount.fromJson(row);
  }

  Future<void> deleteWallet(int walletId) async {
    await _client.from('activos').update({'activo': false}).eq('activo_id', walletId);
  }

  // Maps Flutter WalletAccount.tipo ("ahorro"/"gasto"/"deuda") to DB tipo_activo enum
  String _tipoActivoFromSubtipo(String subtipo) {
    switch (subtipo) {
      case 'deuda': return 'cuenta_bancaria';
      case 'ahorro': return 'cuenta_bancaria';
      default: return 'efectivo';
    }
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(supabaseClientProvider));
});
