import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/models.dart';
import '../../../core/network/supabase_client.dart';

class CategoryRepository {
  final SupabaseClient _client;
  CategoryRepository(this._client);

  /// Fetch system categories (global, available to all users).
  Future<List<MenudoCategory>> fetchSystemCategories() async {
    final data = await _client
        .from('categorias')
        .select()
        .eq('es_sistema', true)
        .order('categoria_id');
    return (data as List)
        .map((row) => MenudoCategory.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetch categories visible to a user: system + their own custom ones.
  Future<List<MenudoCategory>> fetchCategoriesForUser(int userId) async {
    final data = await _client
        .from('categorias')
        .select()
        .or('es_sistema.eq.true,usuario_id.eq.$userId')
        .order('es_sistema', ascending: false) // system first
        .order('categoria_id');
    return (data as List)
        .map((row) => MenudoCategory.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Create a user-owned custom category.
  Future<MenudoCategory> createCategory(int userId, MenudoCategory category) async {
    final row = await _client
        .from('categorias')
        .insert({
          ...category.toJson(),
          'usuario_id': userId,
          'es_sistema': false,
        })
        .select()
        .single();
    return MenudoCategory.fromJson(row);
  }

  /// Update a user-owned category (cannot update system categories).
  Future<MenudoCategory> updateCategory(MenudoCategory category) async {
    final row = await _client
        .from('categorias')
        .update(category.toJson())
        .eq('categoria_id', category.id)
        .eq('es_sistema', false) // safety: never update system cats
        .select()
        .single();
    return MenudoCategory.fromJson(row);
  }

  /// Delete a user-owned category.
  Future<void> deleteCategory(int categoryId) async {
    await _client
        .from('categorias')
        .delete()
        .eq('categoria_id', categoryId)
        .eq('es_sistema', false); // safety
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});
