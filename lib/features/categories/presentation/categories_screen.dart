import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../shared/widgets/menudo_button.dart';
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
    HapticFeedback.mediumImpact();
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
            decoration: const BoxDecoration(
              color: AppColors.g0,
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
                      color: AppColors.g3,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
                        size: 20,
                        color: category.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.e8,
                            ),
                          ),
                          Text(
                            'Elige qué quieres hacer con este $label.',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.g5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _CategoryActionTile(
                  icon: LucideIcons.pencil,
                  label: isParent ? 'Editar grupo' : 'Editar categoría',
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_CategoryAction.edit),
                ),
                const SizedBox(height: 10),
                _CategoryActionTile(
                  icon: LucideIcons.trash2,
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
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final safeBottom = MediaQuery.of(sheetContext).padding.bottom;
        final label = isParent ? 'grupo' : 'categoría';

        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.g0,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + safeBottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.g3,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isParent ? 'Eliminar grupo' : 'Eliminar categoría',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intentaremos borrar ${category.nombre}. Si ese $label ya tiene movimientos o sigue en uso, no se podrá eliminar.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.g5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.r5,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: const Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(categoryNotifierProvider.notifier)
          .removeCategory(category.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: AppColors.g0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.e8),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Categorías',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.e8,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => _showCategorySheet(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: AppColors.g2),
              ),
              icon: const Icon(LucideIcons.plus, color: AppColors.e8, size: 18),
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
                  horizontal: 16,
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
                  borderSide: const BorderSide(color: AppColors.e6, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.g2),
                        ),
                        child: Text(
                          _searchCtrl.text.trim().isEmpty
                              ? 'Todavía no hay categorías para mostrar.'
                              : 'No encontramos categorías con ese nombre.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.g4,
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
          const Text(
            'Elige un grupo para crearla o crea uno nuevo.',
            style: TextStyle(fontSize: 13, color: AppColors.g4),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: parents.isEmpty
                ? SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.g0,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.g2),
                      ),
                      child: const Text(
                        'Todavía no hay grupos aquí. Crea uno para empezar.',
                        style: TextStyle(fontSize: 13, color: AppColors.g4),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: parents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final parent = parents[index];
                      return InkWell(
                        onTap: () => _openSubcategoryCreator(context, parent),
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
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openParentCreator(context),
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
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _expanded = !_expanded);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.g2),
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
                      child: Icon(parent.icono, size: 20, color: parent.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parent.nombre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.e8,
                            ),
                          ),
                          Text(
                            '${subs.length} categoría${subs.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.g4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
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
                              LucideIcons.plus,
                              size: 14,
                              color: parent.color,
                            ),
                            const SizedBox(width: 6),
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onManageParent,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.g1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            LucideIcons.moreHorizontal,
                            size: 16,
                            color: AppColors.g5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.g3,
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
                    final crossAxisCount = width >= 840
                        ? 5
                        : width >= 520
                        ? 4
                        : 3;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
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

            const SizedBox(height: 14),
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
    return GestureDetector(
      onTap: onManage ?? () => HapticFeedback.lightImpact(),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: category.color.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(category.icono, size: 24, color: category.color),
              ),
              if (onManage != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: onManage,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.g2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.moreHorizontal,
                        size: 12,
                        color: AppColors.g5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category.nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.e8,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSubcategoryTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSubcategoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.g1.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.g2, style: BorderStyle.solid),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.plus, size: 22, color: AppColors.g4),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nueva',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.g4,
            ),
          ),
        ],
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
    LucideIcons.tag,
    LucideIcons.shoppingCart,
    LucideIcons.utensils,
    LucideIcons.coffee,
    LucideIcons.car,
    LucideIcons.bus,
    LucideIcons.plane,
    LucideIcons.home,
    LucideIcons.building2,
    LucideIcons.wallet,
    LucideIcons.banknote,
    LucideIcons.walletCards,
    LucideIcons.piggyBank,
    LucideIcons.receipt,
    LucideIcons.landmark,
    LucideIcons.heart,
    LucideIcons.heartPulse,
    LucideIcons.pill,
    LucideIcons.stethoscope,
    LucideIcons.bookOpen,
    LucideIcons.graduationCap,
    LucideIcons.dumbbell,
    LucideIcons.shirt,
    LucideIcons.film,
    LucideIcons.music,
    LucideIcons.gamepad2,
    LucideIcons.gift,
    LucideIcons.tv,
    LucideIcons.laptop,
    LucideIcons.wifi,
    LucideIcons.droplets,
    LucideIcons.fuel,
    LucideIcons.briefcase,
    LucideIcons.trendingUp,
    LucideIcons.arrowLeftRight,
  ];
  static const List<Color> _colorOptions = [
    AppColors.e8,
    AppColors.e6,
    AppColors.o5,
    AppColors.a5,
    AppColors.b5,
    AppColors.p5,
    AppColors.pk,
    AppColors.r5,
    AppColors.g5,
  ];

  IconData _icon = LucideIcons.tag;
  String _selectedType = 'gasto';
  Color _color = AppColors.e8;
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
          _icon = LucideIcons.trendingUp;
        }
        break;
      case 'transferencia':
        if (!_hasCustomColor || forceDefaultIcon) {
          _color = AppColors.b5;
        }
        if (!_hasCustomIcon || forceDefaultIcon) {
          _icon = LucideIcons.arrowLeftRight;
        }
        break;
      default:
        if (!_hasCustomColor || forceDefaultIcon) {
          _color = AppColors.e8;
        }
        if (!_hasCustomIcon || forceDefaultIcon) {
          _icon = LucideIcons.tag;
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
    HapticFeedback.selectionClick();
    setState(() {
      _hasCustomIcon = true;
      _icon = icon;
    });
  }

  void _selectColor(Color color) {
    HapticFeedback.selectionClick();
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
        return LucideIcons.trendingUp;
      case 'transferencia':
        return LucideIcons.arrowLeftRight;
      default:
        return LucideIcons.tag;
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
      decoration: const BoxDecoration(
        color: AppColors.g0,
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
                    color: AppColors.g2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  margin: const EdgeInsets.only(bottom: 24),
                ),
                Text(
                  _sheetTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e8,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _sheetSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColors.g5,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.g2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.e8,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.e8,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(_icon, color: _color, size: 18),
                            filled: true,
                            fillColor: AppColors.g0,
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
                              borderSide: const BorderSide(color: AppColors.g1),
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
                  const SizedBox(height: 22),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      alignment: Alignment.center,
                      child: Icon(_icon, size: 36, color: _color),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                            size: 15,
                            color: _color,
                          ),
                          const SizedBox(width: 8),
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
                  const SizedBox(height: 24),
                  if (widget.parent == null &&
                      widget.existingCategory == null) ...[
                    const Text(
                      'Tipo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.g5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final type in _types)
                          GestureDetector(
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
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedType == type
                                      ? _color
                                      : AppColors.g2,
                                  width: _selectedType == type ? 1.6 : 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _typeIcon(type),
                                    size: 15,
                                    color: _selectedType == type
                                        ? _color
                                        : AppColors.g4,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _typeLabel(type),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _selectedType == type
                                          ? _color
                                          : AppColors.g5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.g5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colorOptions.map((colorOption) {
                      final isSelected = colorOption == _color;
                      return GestureDetector(
                        onTap: () => _selectColor(colorOption),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorOption,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.e8 : AppColors.g2,
                              width: isSelected ? 2.2 : 1.2,
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
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Icono',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.g5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _iconOptions.map((icon) {
                      final isSelected = icon == _icon;
                      return GestureDetector(
                        onTap: () => _selectIcon(icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _color.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _color : AppColors.g2,
                              width: isSelected ? 1.6 : 1.1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 18,
                            color: isSelected ? _color : AppColors.g4,
                          ),
                        ),
                      );
                    }).toList(),
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
    final color = isDestructive ? AppColors.r5 : AppColors.e8;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.g2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
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
