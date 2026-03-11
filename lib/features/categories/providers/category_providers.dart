import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/category_controller.dart' as category_controller;
import '../../../controllers/demo_mode_controller.dart';
import '../../../core/data/models.dart';
import '../../../features/auth/auth_state.dart';
import '../../../services/category_service.dart';

final categoryNotifierProvider = category_controller.categoryControllerProvider;
final categoryControllerProvider =
    category_controller.categoryControllerProvider;

final effectiveCategoriesProvider = Provider<List<MenudoCategory>>((ref) {
  final categories = ref.watch(categoryNotifierProvider).valueOrNull;
  final demoMode = ref.watch(demoModeProvider);

  if (categories != null && categories.isNotEmpty) {
    return categories;
  }
  if (demoMode) {
    return mockCategories;
  }
  return categories ?? const [];
});

final parentCategoriesProvider =
    FutureProvider.family<List<MenudoCategory>, String?>((ref, tipo) async {
      final userId = ref.watch(authProvider).userId;
      if (userId == null) {
        return const [];
      }
      return ref
          .read(categoryServiceProvider)
          .fetchParentCategories(int.parse(userId), tipo: tipo);
    });

// Lookup a category by its slug
final categoryBySlugProvider = Provider.family<MenudoCategory?, String>((
  ref,
  slug,
) {
  final cats = ref.watch(effectiveCategoriesProvider);
  try {
    return cats.firstWhere((c) => c.slug == slug);
  } catch (_) {
    return null;
  }
});

// All category IDs by slug — used when creating transactions
final categoryIdBySlugProvider = Provider<Map<String, int>>((ref) {
  final cats = ref.watch(effectiveCategoriesProvider);
  return {for (final c in cats) c.slug: c.id};
});

// Returns parent categories with their subcategories grouped
// Map<parent, List<subcategories>>
final groupedCategoriesProvider =
    Provider<Map<MenudoCategory, List<MenudoCategory>>>((ref) {
      final cats = ref.watch(effectiveCategoriesProvider);
      final parents = cats.where((c) => c.esParent).toList();
      return {
        for (final parent in parents)
          parent: cats.where((c) => c.categoriaParadreId == parent.id).toList(),
      };
    });
