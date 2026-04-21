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
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialCatKey;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddCategory() async {
    HapticFeedback.mediumImpact();
    final created = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
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
      useRootNavigator: true,
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
    final query = _searchCtrl.text.trim().toLowerCase();
    final visibleCategories = _visibleCategories(categories);
    final parents =
        visibleCategories.where((category) => category.esParent).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final children = visibleCategories.where((category) => !category.esParent);

    return {
      for (final parent in parents)
        if (query.isEmpty ||
            parent.nombre.toLowerCase().contains(query) ||
            children.any(
              (category) =>
                  category.categoriaParadreId == parent.id &&
                  category.nombre.toLowerCase().contains(query),
            ))
          parent:
              children
                  .where((category) => category.categoriaParadreId == parent.id)
                  .where(
                    (category) =>
                        query.isEmpty ||
                        parent.nombre.toLowerCase().contains(query) ||
                        category.nombre.toLowerCase().contains(query),
                  )
                  .toList()
                ..sort((a, b) => a.nombre.compareTo(b.nombre)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(effectiveCategoriesProvider);
    final grouped = _resolvedGroups(categories);
    final media = MediaQuery.of(context);
    final bottomPadding = media.padding.bottom;

    return Container(
      height: media.size.height * 0.88,
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Elegir categoría",
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
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar',
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.g4,
                    ),
                    suffixIcon: _searchCtrl.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                            icon: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: AppColors.g4,
                            ),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.g2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.g2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.e6,
                        width: 1.5,
                      ),
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
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: parent.color.withValues(alpha: 0.12),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: parent.color.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      parent.icono,
                                      size: 18,
                                      color: parent.color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          parent.nombre,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.e8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subs.isEmpty
                                              ? 'Aun no hay categorias aqui.'
                                              : '${subs.length} opcion${subs.length == 1 ? '' : 'es'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.g4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showAddSubcategory(parent),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: parent.color.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        LucideIcons.plus,
                                        size: 15,
                                        color: parent.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (subs.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.g0,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.g2),
                                  ),
                                  child: const Text(
                                    'Agrega una categoria dentro de este grupo para poder seleccionarla.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.g4,
                                      height: 1.35,
                                    ),
                                  ),
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 520;
                                    final crossAxisCount = isWide ? 3 : 2;
                                    final childAspectRatio = isWide
                                        ? 1.55
                                        : 1.72;

                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: 10,
                                            crossAxisSpacing: 10,
                                            childAspectRatio: childAspectRatio,
                                          ),
                                      itemCount: subs.length,
                                      itemBuilder: (context, subIndex) {
                                        final cat = subs[subIndex];
                                        final isSelected =
                                            _selectedKey == cat.slug;

                                        return _CategoryChoiceTile(
                                          category: cat,
                                          isSelected: isSelected,
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            setState(
                                              () => _selectedKey = cat.slug,
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.05, end: 0),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
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

class _CategoryChoiceTile extends StatelessWidget {
  const _CategoryChoiceTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final MenudoCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.08)
              : AppColors.g0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? category.color : AppColors.g2,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withValues(alpha: 0.14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                category.icono,
                size: 17,
                color: isSelected ? category.color : AppColors.g4,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? category.color : AppColors.e8,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: isSelected ? category.color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? category.color : AppColors.g3,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(LucideIcons.check, size: 9, color: Colors.white)
                  : null,
            ),
          ],
        ),
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
      useRootNavigator: true,
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
      useRootNavigator: true,
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
    final media = MediaQuery.of(context);
    final bottomPadding = media.padding.bottom;

    return Container(
      height: media.size.height * 0.86,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Column(
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
            'Nueva categoría',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allowedType == null
                ? 'Elige un grupo o crea uno nuevo.'
                : 'Elige un grupo de ${allowedType == 'ingreso'
                      ? 'ingresos'
                      : allowedType == 'transferencia'
                      ? 'transferencias'
                      : 'gastos'}.',
            style: const TextStyle(fontSize: 13, color: AppColors.g4),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: parentsAsync.when(
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
                        'Todavía no hay grupos para elegir.',
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
                                      color: parent.color.withValues(
                                        alpha: 0.12,
                                      ),
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
              child: const Text('Nuevo grupo'),
            ),
          ),
        ],
      ),
    );
  }
}
