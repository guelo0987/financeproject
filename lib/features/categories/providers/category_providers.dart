import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models.dart';
import '../data/category_repository.dart';

class CategoryNotifier extends AsyncNotifier<List<MenudoCategory>> {
  @override
  Future<List<MenudoCategory>> build() async {
    // TODO: replace 1 with real userId from authProvider
    return ref.read(categoryRepositoryProvider).fetchCategoriesForUser(1);
  }

  Future<void> addCategory(MenudoCategory category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // TODO: replace 1 with real userId from authProvider
      await ref.read(categoryRepositoryProvider).createCategory(1, category);
      return ref.read(categoryRepositoryProvider).fetchCategoriesForUser(1);
    });
  }

  Future<void> removeCategory(int categoryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).deleteCategory(categoryId);
      return ref.read(categoryRepositoryProvider).fetchCategoriesForUser(1);
    });
  }
}

final categoryNotifierProvider = AsyncNotifierProvider<CategoryNotifier, List<MenudoCategory>>(
  CategoryNotifier.new,
);

// Lookup a category by its slug (useful in UI to resolve catKey → MenudoCategory)
final categoryBySlugProvider = Provider.family<MenudoCategory?, String>((ref, slug) {
  final cats = ref.watch(categoryNotifierProvider).valueOrNull ?? [];
  try {
    return cats.firstWhere((c) => c.slug == slug);
  } catch (_) {
    return null;
  }
});

// All category IDs by slug — used when creating transactions
final categoryIdBySlugProvider = Provider<Map<String, int>>((ref) {
  final cats = ref.watch(categoryNotifierProvider).valueOrNull ?? [];
  return {for (final c in cats) c.slug: c.id};
});
