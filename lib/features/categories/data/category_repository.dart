import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/models.dart';
import '../../../core/utils/color_utils.dart';
import '../../../services/api_service.dart';
import '../../../utils/utils.dart';
import '../../../core/utils/icon_utils.dart';

class CategoryRepository {
  final ApiService _api;
  CategoryRepository(this._api);

  Future<List<MenudoCategory>> fetchSystemCategories() async {
    final response = await _api.get<List<dynamic>>(
      '${ApiPaths.categories}/system',
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((row) => MenudoCategory.fromJson(asJsonMap(row)))
        .toList();
  }

  Future<List<MenudoCategory>> fetchCategoriesForUser(int userId) async {
    final response = await _api.get<List<dynamic>>(
      ApiPaths.categories,
      queryParameters: {'formato': 'flat'},
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((row) => MenudoCategory.fromJson(asJsonMap(row)))
        .toList();
  }

  Future<List<MenudoCategory>> fetchParentCategories(
    int userId, {
    String? tipo,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (tipo != null) {
      queryParameters['tipo'] = tipo;
    }

    final response = await _api.get<List<dynamic>>(
      ApiPaths.categoryParents,
      queryParameters: queryParameters,
      parser: asJsonList,
    );
    return response
        .requireData()
        .map((row) => MenudoCategory.fromJson(asJsonMap(row)))
        .toList();
  }

  Future<MenudoCategory> createCategory(
    int userId,
    MenudoCategory category,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.categories,
      body: {
        'nombre': category.nombre,
        'tipo': category.tipo,
        'icono': iconToKey(category.icono),
        'color_hex': colorToHex(category.color),
        if (category.categoriaParadreId != null)
          'categoria_padre_id': category.categoriaParadreId,
      },
      parser: asJsonMap,
    );
    return MenudoCategory.fromJson(response.requireData());
  }

  Future<MenudoCategory> createParentCategory(
    int userId,
    MenudoCategory category,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiPaths.categoryParents,
      body: {
        'nombre': category.nombre,
        'tipo': category.tipo,
        'icono': iconToKey(category.icono),
        'color_hex': colorToHex(category.color),
      },
      parser: asJsonMap,
    );
    return MenudoCategory.fromJson(response.requireData());
  }

  Future<MenudoCategory> updateCategory(MenudoCategory category) async {
    final response = await _api.put<Map<String, dynamic>>(
      ApiPaths.categoryById(category.id),
      body: {
        'nombre': category.nombre,
        'tipo': category.tipo,
        'icono': iconToKey(category.icono),
        'color_hex': colorToHex(category.color),
        'categoria_padre_id': category.categoriaParadreId,
      },
      parser: asJsonMap,
    );
    return MenudoCategory.fromJson(response.requireData());
  }

  Future<void> deleteCategory(int categoryId) async {
    await _api.delete<void>(ApiPaths.categoryById(categoryId));
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(apiServiceProvider));
});
