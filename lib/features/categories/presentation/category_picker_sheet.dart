import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_presenter.dart';
import '../providers/category_providers.dart';
import 'categories_screen.dart';

class CategoryPickerSheet extends ConsumerStatefulWidget {
  final String? initialCatKey;
  final String? allowedType;

  const CategoryPickerSheet({super.key, this.initialCatKey, this.allowedType});

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialCatKey;
  }

  Future<void> _showAddCategory() async {
    HapticFeedback.mediumImpact();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _CategoryPickerCreateSheet(allowedType: widget.allowedType),
    );
    if (mounted && created == true) {
      setState(() {});
    }
  }

  Future<void> _showAddSubcategory(MenudoCategory parent) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(parent: parent),
    );
    if (mounted && created == true) {
      setState(() {});
    }
  }

  List<MenudoCategory> _visibleCategories(List<MenudoCategory> categories) {
    final allowedType = widget.allowedType;
    if (allowedType == null) {
      return categories;
    }
    return categories
        .where((category) => category.tipo == allowedType)
        .toList();
  }

  Map<MenudoCategory, List<MenudoCategory>> _resolvedGroups(
    List<MenudoCategory> categories,
  ) {
    final visibleCategories = _visibleCategories(categories);
    final parents =
        visibleCategories.where((category) => category.esParent).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final children = visibleCategories.where((category) => !category.esParent);

    return {
      for (final parent in parents)
        parent:
            children
                .where((category) => category.categoriaParadreId == parent.id)
                .toList()
              ..sort((a, b) => a.nombre.compareTo(b.nombre)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(effectiveCategoriesProvider);
    final grouped = _resolvedGroups(categories);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.g2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Categoría",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e8,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: _showAddCategory,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.o1,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      size: 18,
                      color: AppColors.o5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Text(
                      widget.allowedType == null
                          ? 'No hay categorias disponibles.'
                          : 'No hay categorias de ${widget.allowedType} disponibles.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.g4,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final parent = grouped.keys.elementAt(index);
                      final subs = grouped[parent]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child:
                            Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            parent.icono,
                                            size: 16,
                                            color: parent.color,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              parent.nombre.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.g5,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () =>
                                                _showAddSubcategory(parent),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: parent.color.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                LucideIcons.plus,
                                                size: 14,
                                                color: parent.color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (subs.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: AppColors.g2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Este grupo todavía no tiene subcategorías.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.g4,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _showAddSubcategory(parent),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: parent.color,
                                                side: BorderSide(
                                                  color: parent.color
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: const Text(
                                                'Crear subcategoría',
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              mainAxisSpacing: 12,
                                              crossAxisSpacing: 12,
                                              childAspectRatio: 0.9,
                                            ),
                                        itemCount: subs.length,
                                        itemBuilder: (context, subIndex) {
                                          final cat = subs[subIndex];
                                          final isSelected =
                                              _selectedKey == cat.slug;

                                          return GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              setState(
                                                () => _selectedKey = cat.slug,
                                              );
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? cat.color
                                                      : AppColors.g2,
                                                  width: isSelected ? 2.5 : 1.5,
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: cat.color
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          blurRadius: 12,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ]
                                                    : [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.02,
                                                              ),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 44,
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? cat.color
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                )
                                                          : AppColors.g1,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      cat.icono,
                                                      size: 22,
                                                      color: isSelected
                                                          ? cat.color
                                                          : AppColors.g4,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    cat.nombre,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                      color: isSelected
                                                          ? cat.color
                                                          : AppColors.e8,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                )
                                .animate()
                                .fadeIn(
                                  duration: 400.ms,
                                  delay: (index * 50).ms,
                                )
                                .slideY(begin: 0.05, end: 0),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            child: GestureDetector(
              onTap: _selectedKey == null
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, _selectedKey);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedKey != null ? AppColors.e8 : AppColors.g2,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: _selectedKey != null
                      ? [
                          BoxShadow(
                            color: AppColors.e8.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  "Confirmar",
                  style: TextStyle(
                    color: _selectedKey != null ? Colors.white : AppColors.g4,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPickerCreateSheet extends ConsumerWidget {
  const _CategoryPickerCreateSheet({this.allowedType});

  final String? allowedType;

  Future<void> _openAddSubcategory(
    BuildContext context,
    MenudoCategory parent,
  ) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(parent: parent),
    );
    if (created == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _openAddParent(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(
        initialType: allowedType,
        lockType: allowedType != null,
      ),
    );
    if (created == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(parentCategoriesProvider(allowedType));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.g2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Agregar categoría',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allowedType == null
                ? 'Primero elige el grupo padre donde quieres crear la subcategoría.'
                : 'Primero elige el grupo padre de ${allowedType == 'ingreso'
                      ? 'ingresos'
                      : allowedType == 'transferencia'
                      ? 'transferencias'
                      : 'gastos'} donde quieres crear la subcategoría.',
            style: const TextStyle(fontSize: 13, color: AppColors.g4),
          ),
          const SizedBox(height: 18),
          parentsAsync.when(
            data: (parents) {
              if (parents.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.g0,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.g2),
                  ),
                  child: const Text(
                    'No hay grupos padre disponibles todavía.',
                    style: TextStyle(fontSize: 13, color: AppColors.g4),
                  ),
                );
              }

              return Column(
                children: [
                  for (final parent in parents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _openAddSubcategory(context, parent),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: parent.color.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: parent.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  parent.icono,
                                  size: 20,
                                  color: parent.color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  parent.nombre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.e8,
                                  ),
                                ),
                              ),
                              const Icon(
                                LucideIcons.chevronRight,
                                size: 18,
                                color: AppColors.g4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                presentError(error),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.r5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openAddParent(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.e8,
                side: const BorderSide(color: AppColors.g2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Crear grupo padre'),
            ),
          ),
        ],
      ),
    );
  }
}
