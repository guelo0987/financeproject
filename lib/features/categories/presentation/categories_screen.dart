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

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _showAddCategory(BuildContext context, {MenudoCategory? parent}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => parent == null
          ? const _CategoryCreationLauncherSheet()
          : AddCategorySheet(parent: parent),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(groupedCategoriesProvider);
    final entries = grouped.entries.toList();

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
              onPressed: () => _showAddCategory(context),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          ...entries.asMap().entries.map((entry) {
            final groupIdx = entry.key;
            final parent = entry.value.key;
            final subs = entry.value.value;

            return _CategoryGroup(
              parent: parent,
              subcategories: subs,
              animDelay: groupIdx * 80,
              onAddSub: () => _showAddCategory(context, parent: parent),
            );
          }),
        ],
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
    final bottomInset = media.viewInsets.bottom;
    final bottomPadding = media.padding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
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
      ),
    );
  }
}

class _CategoryGroup extends StatefulWidget {
  final MenudoCategory parent;
  final List<MenudoCategory> subcategories;
  final int animDelay;
  final VoidCallback onAddSub;

  const _CategoryGroup({
    required this.parent,
    required this.subcategories,
    required this.animDelay,
    required this.onAddSub,
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
                        return _SubcategoryTile(category: subs[i]);
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
  const _SubcategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: category.color.withValues(alpha: 0.15)),
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
  final String? initialType;
  final bool lockType;

  const AddCategorySheet({
    super.key,
    this.parent,
    this.initialType,
    this.lockType = false,
  });

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  IconData _icon = LucideIcons.tag;
  String _selectedType = 'gasto';
  Color _color = AppColors.e8;
  bool _isSaving = false;

  static const List<String> _types = ['gasto', 'ingreso', 'transferencia'];

  String get _effectiveType => widget.parent?.tipo ?? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.parent?.tipo ?? widget.initialType ?? 'gasto';
    _syncAppearance();
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

  void _syncAppearance() {
    final parent = widget.parent;
    if (parent != null) {
      _color = parent.color;
      _icon = parent.icono;
      return;
    }

    switch (_selectedType) {
      case 'ingreso':
        _color = AppColors.e6;
        _icon = LucideIcons.trendingUp;
        break;
      case 'transferencia':
        _color = AppColors.b5;
        _icon = LucideIcons.arrowLeftRight;
        break;
      default:
        _color = AppColors.e8;
        _icon = LucideIcons.tag;
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

  String get _sheetTitle =>
      widget.parent == null ? 'Nuevo grupo' : 'Nueva categoría';

  String get _sheetSubtitle => widget.parent == null
      ? 'Crea una categoría principal para organizar tus movimientos.'
      : 'Se agregará dentro de ${widget.parent!.nombre}.';

  String get _nameLabel =>
      widget.parent == null ? 'Nombre del grupo' : 'Nombre de la categoría';

  String get _nameHint => widget.parent == null
      ? 'Ej. Hogar, Transporte o Salud'
      : 'Ej. Supermercado, Uber o Farmacia';

  Future<void> _createCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Escribe un nombre para la categoría.');
      return;
    }

    final parent = widget.parent;

    setState(() => _isSaving = true);
    try {
      final category = MenudoCategory(
        id: 0,
        slug: name.toLowerCase(),
        nombre: name,
        tipo: parent?.tipo ?? _effectiveType,
        icono: parent?.icono ?? _icon,
        color: parent?.color ?? _color,
        esSistema: false,
        categoriaParadreId: parent?.id,
      );
      if (parent == null) {
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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: media.size.height * 0.86,
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    if (widget.parent == null) ...[
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.e8,
                            ),
                            decoration: InputDecoration(
                              hintText: _nameHint,
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
                                borderSide: const BorderSide(
                                  color: AppColors.g1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: _color,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
              child: MenudoButton(
                label: _isSaving
                    ? "GUARDANDO..."
                    : widget.parent == null
                    ? "CREAR GRUPO"
                    : "CREAR CATEGORÍA",
                isFullWidth: true,
                isDisabled: _isSaving,
                onTap: _createCategory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
