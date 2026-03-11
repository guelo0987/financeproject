import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/categories/data/category_repository.dart';

class CategoryService {
  const CategoryService(this._repository);

  final CategoryRepository _repository;

  Future<List<MenudoCategory>> fetchSystemCategories() {
    return _repository.fetchSystemCategories();
  }

  Future<List<MenudoCategory>> fetchCategoriesForUser(int userId) {
    return _repository.fetchCategoriesForUser(userId);
  }

  Future<List<MenudoCategory>> fetchParentCategories(
    int userId, {
    String? tipo,
  }) {
    return _repository.fetchParentCategories(userId, tipo: tipo);
  }

  Future<MenudoCategory> createCategory(int userId, MenudoCategory category) {
    return _repository.createCategory(userId, category);
  }

  Future<MenudoCategory> createParentCategory(
    int userId,
    MenudoCategory category,
  ) {
    return _repository.createParentCategory(userId, category);
  }

  Future<MenudoCategory> updateCategory(MenudoCategory category) {
    return _repository.updateCategory(category);
  }

  Future<void> deleteCategory(int categoryId) {
    return _repository.deleteCategory(categoryId);
  }
}

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(categoryRepositoryProvider));
});
