import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';

class CategoryNotifier extends AsyncNotifier<List<MenudoCategory>> {
  @override
  Future<List<MenudoCategory>> build() async {
    // TODO: replace with Supabase fetch once backend is ready
    // final uid = ref.watch(authProvider).userId;
    // if (uid != null) return ref.read(categoryRepositoryProvider).fetchCategoriesForUser(int.parse(uid));
    return mockCategories;
  }

  Future<void> addCategory(MenudoCategory category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // TODO: replace with real userId from authProvider
      // await ref.read(categoryRepositoryProvider).createCategory(uid, category);
      // return ref.read(categoryRepositoryProvider).fetchCategoriesForUser(uid);
      final current = state.valueOrNull ?? mockCategories;
      return [...current, category];
    });
  }

  Future<void> removeCategory(int categoryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // TODO: await ref.read(categoryRepositoryProvider).deleteCategory(categoryId);
      final current = state.valueOrNull ?? mockCategories;
      return current.where((c) => c.id != categoryId).toList();
    });
  }
}

final categoryNotifierProvider = AsyncNotifierProvider<CategoryNotifier, List<MenudoCategory>>(
  CategoryNotifier.new,
);

// Lookup a category by its slug
final categoryBySlugProvider = Provider.family<MenudoCategory?, String>((ref, slug) {
  final cats = ref.watch(categoryNotifierProvider).valueOrNull ?? mockCategories;
  try {
    return cats.firstWhere((c) => c.slug == slug);
  } catch (_) {
    return null;
  }
});

// All category IDs by slug — used when creating transactions
final categoryIdBySlugProvider = Provider<Map<String, int>>((ref) {
  final cats = ref.watch(categoryNotifierProvider).valueOrNull ?? mockCategories;
  return {for (final c in cats) c.slug: c.id};
});

// Returns parent categories with their subcategories grouped
// Map<parent, List<subcategories>>
final groupedCategoriesProvider = Provider<Map<MenudoCategory, List<MenudoCategory>>>((ref) {
  final cats = ref.watch(categoryNotifierProvider).valueOrNull ?? mockCategories;
  final parents = cats.where((c) => c.esParent).toList();
  return {
    for (final parent in parents)
      parent: cats.where((c) => c.categoriaParadreId == parent.id).toList(),
  };
});
