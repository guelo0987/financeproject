import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import '../../../features/auth/auth_state.dart';
import '../data/category_repository.dart';

class CategoryNotifier extends AsyncNotifier<List<MenudoCategory>> {
  int _uid() {
    final uid = ref.read(authProvider).userId;
    return uid != null ? int.parse(uid) : 0;
  }

  @override
  Future<List<MenudoCategory>> build() async {
    final uid = ref.watch(authProvider).userId;
    if (uid != null) {
      return ref
          .read(categoryRepositoryProvider)
          .fetchCategoriesForUser(int.parse(uid));
    }
    return mockCategories;
  }

  Future<void> addCategory(MenudoCategory category) async {
    final userId = _uid();
    if (userId == 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(categoryRepositoryProvider)
          .createCategory(userId, category);
      return ref
          .read(categoryRepositoryProvider)
          .fetchCategoriesForUser(userId);
    });
  }

  Future<void> removeCategory(int categoryId) async {
    final userId = _uid();
    if (userId == 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).deleteCategory(categoryId);
      return ref
          .read(categoryRepositoryProvider)
          .fetchCategoriesForUser(userId);
    });
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<MenudoCategory>>(
      CategoryNotifier.new,
    );

// Lookup a category by its slug
final categoryBySlugProvider = Provider.family<MenudoCategory?, String>((
  ref,
  slug,
) {
  final cats =
      ref.watch(categoryNotifierProvider).valueOrNull ?? mockCategories;
  try {
    return cats.firstWhere((c) => c.slug == slug);
  } catch (_) {
    return null;
  }
});

// All category IDs by slug — used when creating transactions
final categoryIdBySlugProvider = Provider<Map<String, int>>((ref) {
  final cats =
      ref.watch(categoryNotifierProvider).valueOrNull ?? mockCategories;
  return {for (final c in cats) c.slug: c.id};
});

// Returns parent categories with their subcategories grouped
// Map<parent, List<subcategories>>
final groupedCategoriesProvider =
    Provider<Map<MenudoCategory, List<MenudoCategory>>>((ref) {
      final cats =
          ref.watch(categoryNotifierProvider).valueOrNull ?? mockCategories;
      final parents = cats.where((c) => c.esParent).toList();
      return {
        for (final parent in parents)
          parent: cats.where((c) => c.categoriaParadreId == parent.id).toList(),
      };
    });
