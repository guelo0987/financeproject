import 'dart:async';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/menudo_blurred_app_bar.dart';
import '../../../core/data/models.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_destructive_dialog.dart';
import '../providers/category_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCategorySheet(
    BuildContext context, {
    MenudoCategory? parent,
    MenudoCategory? category,
  }) {
    MenudoHaptics.medium();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        if (parent != null) {
          return AddCategorySheet(parent: parent, existingCategory: category);
        }
        if (category != null) {
          return AddCategorySheet(existingCategory: category);
        }
        return const _CategoryCreationLauncherSheet();
      },
    );
  }

  Future<void> _showCategoryActions({
    required MenudoCategory category,
    MenudoCategory? parent,
  }) async {
    if (category.esSistema) return;

    final action = await showModalBottomSheet<_CategoryAction>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final safeBottom = MediaQuery.of(sheetContext).padding.bottom;
        final isParent = category.esParent;
        final label = isParent ? 'grupo' : 'categoría';

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: context.menudo.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + safeBottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.menudo.textMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: (18)),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        category.icono,
                        size: (20),
                        color: category.color,
                      ),
                    ),
                    SizedBox(width: (12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.nombre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: context.menudo.textMain,
                            ),
                          ),
                          Text(
                            'Elige qué quieres hacer con este $label.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.menudo.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (18)),
                _CategoryActionTile(
                  icon: MenudoCupertinoIcons.pencil,
                  label: isParent ? 'Editar grupo' : 'Editar categoría',
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_CategoryAction.edit),
                ),
                SizedBox(height: (10)),
                _CategoryActionTile(
                  icon: MenudoCupertinoIcons.trash2,
                  label: isParent ? 'Eliminar grupo' : 'Eliminar categoría',
                  isDestructive: true,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_CategoryAction.delete),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _CategoryAction.edit:
        _showCategorySheet(context, parent: parent, category: category);
        break;
      case _CategoryAction.delete:
        await _confirmDeleteCategory(category);
        break;
    }
  }

  Future<void> _confirmDeleteCategory(MenudoCategory category) async {
    final isParent = category.esParent;
    final label = isParent ? 'grupo' : 'categoría';
    final confirm = await MenudoDestructiveDialog.show(
      context: context,
      title: isParent ? 'Eliminar grupo' : 'Eliminar categoría',
      message:
          'Intentaremos borrar ${category.nombre}. Si ese $label ya tiene movimientos o sigue en uso, no se podrá eliminar.',
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final c = category;

    Future<void> restoreCategory() async {
      try {
        final categoryToRestore = MenudoCategory(
          id: 0,
          slug: c.slug,
          nombre: c.nombre,
          tipo: c.tipo,
          icono: c.icono,
          color: c.color,
          esSistema: false,
          categoriaParadreId: c.categoriaParadreId,
        );

        if (c.esParent) {
          await ref
              .read(categoryNotifierProvider.notifier)
              .addParentCategory(categoryToRestore);
        } else {
          await ref
              .read(categoryNotifierProvider.notifier)
              .addCategory(categoryToRestore);
        }
        MenudoHaptics.success();
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(presentError(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    try {
      await ref
          .read(categoryNotifierProvider.notifier)
          .removeCategory(category.id);
      if (!mounted) return;
      MenudoHaptics.success();

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('"${c.nombre}" fue eliminada.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () {
                unawaited(restoreCategory());
              },
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(presentError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<MapEntry<MenudoCategory, List<MenudoCategory>>> _filteredEntries(
    Map<MenudoCategory, List<MenudoCategory>> grouped,
  ) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return grouped.entries.toList();

    return grouped.entries
        .map((entry) {
          final parentMatches = entry.key.nombre.toLowerCase().contains(query);
          final matchingChildren = entry.value
              .where((child) => child.nombre.toLowerCase().contains(query))
              .toList();

          if (!parentMatches && matchingChildren.isEmpty) return null;
          return MapEntry(
            entry.key,
            parentMatches ? entry.value : matchingChildren,
          );
        })
        .whereType<MapEntry<MenudoCategory, List<MenudoCategory>>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = ref.watch(groupedCategoriesProvider);
    final entries = _filteredEntries(grouped);

    return Scaffold(
      backgroundColor: context.menudo.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const MenudoBlurredBar(),
        elevation: 0,
        leading: MenudoIconButton(
          icon: Icon(
            MenudoCupertinoIcons.chevronLeft,
            color: context.menudo.textMain,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Categorías',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: context.menudo.textMain,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MenudoIconButton(
              onPressed: () => _showCategorySheet(context),
              style: IconButton.styleFrom(
                backgroundColor: context.menudo.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: context.menudo.border),
              ),
              icon: Icon(
                MenudoCupertinoIcons.plus,
                color: context.menudo.textMain,
                size: (18),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar categoría o grupo',
                prefixIcon: Icon(
                  MenudoCupertinoIcons.search,
                  size: (18),
                  color: context.menudo.textMuted,
                ),
                suffixIcon: _searchCtrl.text.trim().isEmpty
                    ? null
                    : MenudoIconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                        icon: Icon(
                          MenudoCupertinoIcons.x,
                          size: (16),
                          color: context.menudo.textMuted,
                        ),
                      ),
                filled: true,
                fillColor: context.menudo.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: context.menudo.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: context.menudo.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppColors.e6, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: (16)),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.menudo.border),
                        ),
                        child: Text(
                          _searchCtrl.text.trim().isEmpty
                              ? 'Todavía no hay categorías para mostrar.'
                              : 'No encontramos categorías con ese nombre.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.menudo.textMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        ...entries.asMap().entries.map((entry) {
                          final groupIdx = entry.key;
                          final parent = entry.value.key;
                          final subs = entry.value.value;

                          return _CategoryGroup(
                            parent: parent,
                            subcategories: subs,
                            animDelay: groupIdx * 80,
                            onAddSub: () =>
                                _showCategorySheet(context, parent: parent),
                            onManageParent: parent.esSistema
                                ? null
                                : () => _showCategoryActions(category: parent),
                            onManageSubcategory: (subcategory) =>
                                _showCategoryActions(
                                  category: subcategory,
                                  parent: parent,
                                ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCreationLauncherSheet extends ConsumerWidget {
  const _CategoryCreationLauncherSheet();

  Future<void> _openSubcategoryCreator(
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

  Future<void> _openParentCreator(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCategorySheet(),
    );
    if (created == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parents = ref.watch(groupedCategoriesProvider).keys.toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final media = MediaQuery.of(context);
    final bottomPadding = media.padding.bottom;

    return Container(
      height: media.size.height * 0.86,
      decoration: BoxDecoration(
        color: context.menudo.background,
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
                color: context.menudo.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          SizedBox(height: (20)),
          Text(
            'Nueva categoría',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: context.menudo.textMain,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Elige un grupo para crearla o crea uno nuevo.',
            style: TextStyle(fontSize: 13, color: context.menudo.textMuted),
          ),
          SizedBox(height: (12)),
          Expanded(
            child: parents.isEmpty
                ? SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.menudo.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.menudo.border),
                      ),
                      child: Text(
                        'Todavía no hay grupos aquí. Crea uno para empezar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.menudo.textMuted,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: parents.length,
                    separatorBuilder: (_, _) => SizedBox(height: (10)),
                    itemBuilder: (context, index) {
                      final parent = parents[index];
                      return MenudoInkWell(
                        onTap: () => _openSubcategoryCreator(context, parent),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.menudo.surface,
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
                                  size: (20),
                                  color: parent.color,
                                ),
                              ),
                              SizedBox(width: (12)),
                              Expanded(
                                child: Text(
                                  parent.nombre,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: context.menudo.textMain,
                                  ),
                                ),
                              ),
                              Icon(
                                MenudoCupertinoIcons.chevronRight,
                                size: (18),
                                color: context.menudo.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: (12)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openParentCreator(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.menudo.textMain,
                side: BorderSide(color: context.menudo.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Nuevo grupo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroup extends StatefulWidget {
  final MenudoCategory parent;
  final List<MenudoCategory> subcategories;
  final int animDelay;
  final VoidCallback onAddSub;
  final VoidCallback? onManageParent;
  final ValueChanged<MenudoCategory>? onManageSubcategory;

  const _CategoryGroup({
    required this.parent,
    required this.subcategories,
    required this.animDelay,
    required this.onAddSub,
    this.onManageParent,
    this.onManageSubcategory,
  });

  @override
  State<_CategoryGroup> createState() => _CategoryGroupState();
}

class _CategoryGroupState extends State<_CategoryGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final parent = widget.parent;
    final subs = widget.subcategories;

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenudoGestureDetector(
              onTap: () {
                MenudoHaptics.light();
                setState(() => _expanded = !_expanded);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: context.menudo.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.menudo.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: parent.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        parent.icono,
                        size: (20),
                        color: parent.color,
                      ),
                    ),
                    SizedBox(width: (14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parent.nombre,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.menudo.textMain,
                            ),
                          ),
                          Text(
                            '${subs.length} categoría${subs.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.menudo.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    MenudoGestureDetector(
                      onTap: widget.onAddSub,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: parent.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              MenudoCupertinoIcons.plus,
                              size: (14),
                              color: parent.color,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Nueva',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: parent.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.onManageParent != null) ...[
                      SizedBox(width: 8),
                      MenudoGestureDetector(
                        onTap: widget.onManageParent,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: (34),
                          height: (34),
                          decoration: BoxDecoration(
                            color: context.menudo.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            MenudoCupertinoIcons.moreHorizontal,
                            size: (16),
                            color: context.menudo.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        MenudoCupertinoIcons.chevronDown,
                        size: (18),
                        color: context.menudo.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 760 ? 2 : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 72,
                      ),
                      itemCount: subs.length + 1,
                      itemBuilder: (context, i) {
                        if (i == subs.length) {
                          return _AddSubcategoryTile(onTap: widget.onAddSub);
                        }
                        return _SubcategoryTile(
                          category: subs[i],
                          onManage: widget.onManageSubcategory == null
                              ? null
                              : () => widget.onManageSubcategory!(subs[i]),
                        );
                      },
                    );
                  },
                ),
              ),

            SizedBox(height: (14)),
          ],
        )
        .animate()
        .fadeIn(duration: 350.ms, delay: widget.animDelay.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _SubcategoryTile extends StatelessWidget {
  final MenudoCategory category;
  final VoidCallback? onManage;

  const _SubcategoryTile({required this.category, this.onManage});

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onManage ?? () => MenudoHaptics.light(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.menudo.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(category.icono, size: (21), color: category.color),
            ),
            SizedBox(width: (12)),
            Expanded(
              child: Text(
                category.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
            ),
            if (onManage != null) ...[
              SizedBox(width: (8)),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.menudo.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.menudo.border),
                ),
                alignment: Alignment.center,
                child: Icon(
                  MenudoCupertinoIcons.moreHorizontal,
                  size: (17),
                  color: context.menudo.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddSubcategoryTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSubcategoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.menudo.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.menudo.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                MenudoCupertinoIcons.plus,
                size: (20),
                color: context.menudo.textMuted,
              ),
            ),
            SizedBox(width: (12)),
            Expanded(
              child: Text(
                'Nueva categoría',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Category Sheet ─────────────────────────────
class AddCategorySheet extends ConsumerStatefulWidget {
  final MenudoCategory? parent;
  final MenudoCategory? existingCategory;
  final String? initialType;
  final bool lockType;

  const AddCategorySheet({
    super.key,
    this.parent,
    this.existingCategory,
    this.initialType,
    this.lockType = false,
  });

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  static const List<IconData> _iconOptions = [
    MenudoCupertinoIcons.tag,
    MenudoCupertinoIcons.shoppingCart,
    MenudoCupertinoIcons.utensils,
    MenudoCupertinoIcons.coffee,
    MenudoCupertinoIcons.car,
    MenudoCupertinoIcons.bus,
    MenudoCupertinoIcons.plane,
    MenudoCupertinoIcons.home,
    MenudoCupertinoIcons.receipt,
    MenudoCupertinoIcons.heart,
    MenudoCupertinoIcons.pill,
    MenudoCupertinoIcons.stethoscope,
    MenudoCupertinoIcons.bookOpen,
    MenudoCupertinoIcons.graduationCap,
    MenudoCupertinoIcons.dumbbell,
    MenudoCupertinoIcons.shirt,
    MenudoCupertinoIcons.film,
    MenudoCupertinoIcons.music,
    MenudoCupertinoIcons.gamepad2,
    MenudoCupertinoIcons.gift,
    MenudoCupertinoIcons.tv,
    MenudoCupertinoIcons.laptop,
    MenudoCupertinoIcons.wifi,
    MenudoCupertinoIcons.droplets,
    MenudoCupertinoIcons.fuel,
    MenudoCupertinoIcons.briefcase,
    MenudoCupertinoIcons.trendingUp,
    MenudoCupertinoIcons.arrowLeftRight,
  ];
  static const List<Color> _colorOptions = [
    AppColors.e6,
    AppColors.o5,
    AppColors.a5,
    AppColors.b5,
    AppColors.p5,
    AppColors.pk,
    AppColors.r5,
    AppColors.e7,
  ];

  IconData _icon = MenudoCupertinoIcons.tag;
  String _selectedType = 'gasto';
  Color _color = AppColors.e6;
  bool _isSaving = false;
  bool _hasCustomIcon = false;
  bool _hasCustomColor = false;

  static const List<String> _types = ['gasto', 'ingreso', 'transferencia'];

  String get _effectiveType => widget.parent?.tipo ?? _selectedType;

  @override
  void initState() {
    super.initState();
    final existingCategory = widget.existingCategory;
    if (existingCategory != null) {
      _nameCtrl.text = existingCategory.nombre;
      _selectedType = existingCategory.tipo;
      _icon = existingCategory.icono;
      _color = existingCategory.color;
      _hasCustomColor = true;
      _hasCustomIcon = true;
    } else {
      _selectedType = widget.parent?.tipo ?? widget.initialType ?? 'gasto';
      _syncAppearance(forceDefaultIcon: true);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncAppearance({bool forceDefaultIcon = false}) {
    final parent = widget.parent;
    if (parent != null) {
      if (!_hasCustomColor || forceDefaultIcon) {
        _color = parent.color;
      }
      if (!_hasCustomIcon || forceDefaultIcon) {
        _icon = parent.icono;
      }
      return;
    }

    switch (_selectedType) {
      case 'ingreso':
        if (!_hasCustomColor || forceDefaultIcon) {
          _color = AppColors.e6;
        }
        if (!_hasCustomIcon || forceDefaultIcon) {
          _icon = MenudoCupertinoIcons.trendingUp;
        }
        break;
      case 'transferencia':
        if (!_hasCustomColor || forceDefaultIcon) {
          _color = AppColors.b5;
        }
        if (!_hasCustomIcon || forceDefaultIcon) {
          _icon = MenudoCupertinoIcons.arrowLeftRight;
        }
        break;
      default:
        if (!_hasCustomColor || forceDefaultIcon) {
          _color = AppColors.e6;
        }
        if (!_hasCustomIcon || forceDefaultIcon) {
          _icon = MenudoCupertinoIcons.tag;
        }
        break;
    }
  }

  void _selectType(String type) {
    if (widget.parent != null || widget.lockType || _selectedType == type) {
      return;
    }
    setState(() {
      _selectedType = type;
      _syncAppearance();
    });
  }

  void _selectIcon(IconData icon) {
    MenudoHaptics.selection();
    setState(() {
      _hasCustomIcon = true;
      _icon = icon;
    });
  }

  void _selectColor(Color color) {
    MenudoHaptics.selection();
    setState(() {
      _hasCustomColor = true;
      _color = color;
    });
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'ingreso':
        return 'Ingreso';
      case 'transferencia':
        return 'Transferencia';
      default:
        return 'Gasto';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'ingreso':
        return MenudoCupertinoIcons.trendingUp;
      case 'transferencia':
        return MenudoCupertinoIcons.arrowLeftRight;
      default:
        return MenudoCupertinoIcons.tag;
    }
  }

  String get _sheetTitle => widget.existingCategory != null
      ? (widget.existingCategory!.esParent
            ? 'Editar grupo'
            : 'Editar categoría')
      : (widget.parent == null ? 'Nuevo grupo' : 'Nueva categoría');

  String get _sheetSubtitle => widget.parent == null
      ? (widget.existingCategory == null
            ? 'Crea una categoría principal para organizar tus movimientos.'
            : 'Actualiza el nombre, color o icono de este grupo.')
      : (widget.existingCategory == null
            ? 'Se agregará dentro de ${widget.parent!.nombre}.'
            : 'Actualiza el nombre, color o icono de esta categoría.');

  String get _nameLabel =>
      widget.parent == null ? 'Nombre del grupo' : 'Nombre de la categoría';

  Future<void> _submitCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Escribe un nombre para la categoría.');
      return;
    }

    final parent = widget.parent;
    final existingCategory = widget.existingCategory;

    setState(() => _isSaving = true);
    try {
      final category = MenudoCategory(
        id: existingCategory?.id ?? 0,
        slug: existingCategory?.slug ?? name.toLowerCase(),
        nombre: name,
        tipo: existingCategory?.tipo ?? parent?.tipo ?? _effectiveType,
        icono: _icon,
        color: _color,
        esSistema: existingCategory?.esSistema ?? false,
        usuarioId: existingCategory?.usuarioId,
        categoriaParadreId: parent?.id ?? existingCategory?.categoriaParadreId,
      );
      if (existingCategory != null) {
        await ref
            .read(categoryNotifierProvider.notifier)
            .updateCategory(category);
      } else if (parent == null) {
        await ref
            .read(categoryNotifierProvider.notifier)
            .addParentCategory(category);
      } else {
        await ref.read(categoryNotifierProvider.notifier).addCategory(category);
      }
      if (!mounted) return;
      MenudoHaptics.success();
      Navigator.pop(context, true);
    } catch (error) {
      _showError(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets.bottom;
    final bottomPadding = media.padding.bottom;
    final footerBottomPadding = bottomPadding > 0 ? bottomPadding : 16.0;

    return Container(
      height: media.size.height * 0.86,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.menudo.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  margin: const EdgeInsets.only(bottom: 24),
                ),
                Text(
                  _sheetTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: context.menudo.textMain,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _sheetSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: context.menudo.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.menudo.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: context.menudo.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: context.menudo.textMain,
                          ),
                        ),
                        SizedBox(height: (12)),
                        TextField(
                          controller: _nameCtrl,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitCategory(),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          scrollPadding: EdgeInsets.only(
                            bottom: viewInsets + 120,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.menudo.textMain,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(_icon, color: _color, size: (18)),
                            filled: true,
                            fillColor: context.menudo.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: context.menudo.surface,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: _color, width: 1.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: (22)),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      alignment: Alignment.center,
                      child: Icon(_icon, size: (36), color: _color),
                    ),
                  ),
                  SizedBox(height: (18)),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: context.menudo.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _color.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.parent?.icono ?? _typeIcon(_effectiveType),
                            size: (15),
                            color: _color,
                          ),
                          SizedBox(width: 8),
                          Text(
                            widget.parent == null
                                ? _typeLabel(_effectiveType)
                                : widget.parent!.nombre,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: (24)),
                  if (widget.parent == null &&
                      widget.existingCategory == null) ...[
                    Text(
                      'Tipo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textSecondary,
                      ),
                    ),
                    SizedBox(height: (10)),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final type in _types)
                          MenudoGestureDetector(
                            onTap: widget.lockType
                                ? null
                                : () => _selectType(type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedType == type
                                    ? _color.withValues(alpha: 0.1)
                                    : context.menudo.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedType == type
                                      ? _color
                                      : context.menudo.border,
                                  width: _selectedType == type ? 1.6 : 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _typeIcon(type),
                                    size: (15),
                                    color: _selectedType == type
                                        ? _color
                                        : context.menudo.textMuted,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _typeLabel(type),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _selectedType == type
                                          ? _color
                                          : context.menudo.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: (24)),
                  ],
                  Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textSecondary,
                    ),
                  ),
                  SizedBox(height: (10)),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _colorOptions.length,
                      separatorBuilder: (_, _) => SizedBox(width: (10)),
                      itemBuilder: (context, index) {
                        final colorOption = _colorOptions[index];
                        final isSelected = colorOption == _color;
                        return MenudoGestureDetector(
                          onTap: () => _selectColor(colorOption),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorOption,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? context.menudo.primary
                                    : context.menudo.border,
                                width: isSelected ? 2.4 : 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorOption.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(
                                    MenudoCupertinoIcons.check,
                                    size: (16),
                                    color: context.menudo.surface,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: (24)),
                  Text(
                    'Icono',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textSecondary,
                    ),
                  ),
                  SizedBox(height: (10)),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _iconOptions.length,
                      separatorBuilder: (_, _) => SizedBox(width: (10)),
                      itemBuilder: (context, index) {
                        final icon = _iconOptions[index];
                        final isSelected = icon == _icon;
                        return MenudoGestureDetector(
                          onTap: () => _selectIcon(icon),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _color.withValues(alpha: 0.1)
                                  : context.menudo.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? _color
                                    : context.menudo.border,
                                width: isSelected ? 1.6 : 1.1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              icon,
                              size: (19),
                              color: isSelected
                                  ? _color
                                  : context.menudo.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, footerBottomPadding),
            child: MenudoButton(
              label: _isSaving
                  ? "GUARDANDO..."
                  : widget.existingCategory != null
                  ? "GUARDAR CAMBIOS"
                  : widget.parent == null
                  ? "CREAR GRUPO"
                  : "CREAR CATEGORÍA",
              isFullWidth: true,
              isDisabled: _isSaving,
              onTap: _submitCategory,
            ),
          ),
        ],
      ),
    );
  }
}

enum _CategoryAction { edit, delete }

class _CategoryActionTile extends StatelessWidget {
  const _CategoryActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.r5 : context.menudo.textMain;

    return MenudoInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.menudo.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: (18), color: color),
            SizedBox(width: (12)),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
