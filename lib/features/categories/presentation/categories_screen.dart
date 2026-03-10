import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../providers/category_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _showAddCategory(BuildContext context, {MenudoCategory? parent}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(parent: parent),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(groupedCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.e8),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Categorías',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.e8, letterSpacing: -0.8),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => _showAddCategory(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.o5, shape: BoxShape.circle),
                child: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: grouped.entries.length,
        itemBuilder: (context, groupIdx) {
          final entry = grouped.entries.elementAt(groupIdx);
          final parent = entry.key;
          final subs = entry.value;

          return _CategoryGroup(
            parent: parent,
            subcategories: subs,
            animDelay: groupIdx * 80,
            onAddSub: () => _showAddCategory(context, parent: parent),
          );
        },
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.g2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: parent.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Icon(parent.icono, size: 20, color: parent.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(parent.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.e8)),
                      Text('${subs.length} subcategorías', style: const TextStyle(fontSize: 12, color: AppColors.g4, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(LucideIcons.chevronDown, size: 18, color: AppColors.g3),
                ),
              ],
            ),
          ),
        ),

        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: subs.length + 1,
              itemBuilder: (context, i) {
                if (i == subs.length) {
                  return _AddSubcategoryTile(onTap: widget.onAddSub);
                }
                return _SubcategoryTile(category: subs[i]);
              },
            ),
          ),

        const SizedBox(height: 14),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: widget.animDelay.ms).slideY(begin: 0.05, end: 0);
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
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: category.color.withValues(alpha: 0.15)),
              boxShadow: [BoxShadow(color: category.color.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            alignment: Alignment.center,
            child: Icon(category.icono, size: 22, color: category.color),
          ),
          const SizedBox(height: 8),
          Text(category.nombre, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.e8)),
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
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.g1.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.g2, style: BorderStyle.solid),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.plus, size: 20, color: AppColors.g4),
          ),
          const SizedBox(height: 8),
          const Text('Nueva', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.g4)),
        ],
      ),
    );
  }
}

// ── Add Category Sheet ─────────────────────────────
class AddCategorySheet extends StatefulWidget {
  final MenudoCategory? parent;
  const AddCategorySheet({super.key, this.parent});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  IconData _icon = LucideIcons.tag;
  Color _color = AppColors.e8;

  @override
  void initState() {
    super.initState();
    if (widget.parent != null) {
      _color = widget.parent!.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(3)), margin: const EdgeInsets.only(bottom: 24)),
          Text(widget.parent == null ? "Nueva Categoría" : "Nueva Subcategoría", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.e8)),
          const SizedBox(height: 24),
          
          // Icon & Color Picker
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Show icon picker
            },
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(_icon, size: 32, color: _color),
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: "Nombre de la categoría",
              filled: true,
              fillColor: AppColors.g0,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const Spacer(),
          MenudoButton(
            label: "CREAR CATEGORÍA",
            isFullWidth: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
