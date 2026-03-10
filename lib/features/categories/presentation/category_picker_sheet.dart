import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import 'categories_screen.dart';

class CategoryPickerSheet extends StatefulWidget {
  final String? initialCatKey;

  const CategoryPickerSheet({super.key, this.initialCatKey});

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialCatKey;
  }

  void _showAddCategory() async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCategorySheet(),
    );
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    // Group categories
    final Map<MenudoCategory, List<MenudoCategory>> grouped = {};
    for (var parent in mockCategories.where((c) => c.esParent)) {
      grouped[parent] = mockCategories.where((c) => c.categoriaParadreId == parent.id).toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 5, width: 40,
              decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(3)),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Categoría", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.e8, letterSpacing: -0.5)),
                IconButton(
                  onPressed: _showAddCategory,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.o1, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.plus, size: 18, color: AppColors.o5),
                  ),
                ),
              ],
            ),
          ),

          // Grouped Categories List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final parent = grouped.keys.elementAt(index);
                final subs = grouped[parent]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Row(
                          children: [
                            Icon(parent.icono, size: 16, color: parent.color),
                            const SizedBox(width: 8),
                            Text(
                              parent.nombre.toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.g5, letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: subs.length,
                        itemBuilder: (context, subIndex) {
                          final cat = subs[subIndex];
                          final bool isSelected = _selectedKey == cat.slug;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedKey = cat.slug);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected ? cat.color : AppColors.g2,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: cat.color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
                                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: isSelected ? cat.color.withValues(alpha: 0.1) : AppColors.g1,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(cat.icono, size: 22, color: isSelected ? cat.color : AppColors.g4),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat.nombre,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? cat.color : AppColors.e8,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.05, end: 0),
                );
              },
            ),
          ),

          // Confirm button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
            child: GestureDetector(
              onTap: _selectedKey != null
                  ? () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, _selectedKey);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedKey != null ? AppColors.e8 : AppColors.g2,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: _selectedKey != null
                      ? [BoxShadow(color: AppColors.e8.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
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

