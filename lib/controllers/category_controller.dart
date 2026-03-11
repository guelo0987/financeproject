import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/models.dart';
import '../features/auth/auth_state.dart';
import '../services/category_service.dart';

class CategoryController extends AsyncNotifier<List<MenudoCategory>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<MenudoCategory>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid == null) return const [];
    return ref
        .read(categoryServiceProvider)
        .fetchCategoriesForUser(int.parse(uid));
  }

  Future<void> refresh() async {
    final userId = _uid();
    if (userId == 0) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(categoryServiceProvider).fetchCategoriesForUser(userId),
    );
  }

  Future<MenudoCategory?> addCategory(MenudoCategory category) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncValue.loading();
    try {
      final created = await ref
          .read(categoryServiceProvider)
          .createCategory(userId, category);
      final categories = await ref
          .read(categoryServiceProvider)
          .fetchCategoriesForUser(userId);
      state = AsyncValue.data(categories);
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<MenudoCategory?> addParentCategory(MenudoCategory category) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncValue.loading();
    try {
      final created = await ref
          .read(categoryServiceProvider)
          .createParentCategory(userId, category);
      final categories = await ref
          .read(categoryServiceProvider)
          .fetchCategoriesForUser(userId);
      state = AsyncValue.data(categories);
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<MenudoCategory?> updateCategory(MenudoCategory category) async {
    final userId = _uid();
    if (userId == 0) return null;

    state = const AsyncValue.loading();
    try {
      final updated = await ref
          .read(categoryServiceProvider)
          .updateCategory(category);
      final categories = await ref
          .read(categoryServiceProvider)
          .fetchCategoriesForUser(userId);
      state = AsyncValue.data(categories);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> removeCategory(int categoryId) async {
    final userId = _uid();
    if (userId == 0) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(categoryServiceProvider).deleteCategory(categoryId);
      final categories = await ref
          .read(categoryServiceProvider)
          .fetchCategoriesForUser(userId);
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<MenudoCategory>> fetchSystemCategories() {
    return ref.read(categoryServiceProvider).fetchSystemCategories();
  }

  Future<List<MenudoCategory>> fetchParentCategories({String? tipo}) async {
    final userId = _uid();
    if (userId == 0) return const [];
    return ref
        .read(categoryServiceProvider)
        .fetchParentCategories(userId, tipo: tipo);
  }
}

final categoryControllerProvider =
    AsyncNotifierProvider<CategoryController, List<MenudoCategory>>(
      CategoryController.new,
    );
