import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class CategoryOption {
  final String key;
  final String label;
  final IconData icono;
  final Color color;

  const CategoryOption({required this.key, required this.label, required this.icono, required this.color});
}

class CategoryPickerSheet extends StatefulWidget {
  final String? initialCatKey;

  const CategoryPickerSheet({super.key, this.initialCatKey});

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String? _selectedKey;

  static const List<CategoryOption> _categories = [
    CategoryOption(key: 'vivienda', label: 'Vivienda', icono: LucideIcons.home, color: AppColors.e7),
    CategoryOption(key: 'comida', label: 'Comida', icono: LucideIcons.utensils, color: AppColors.o5),
    CategoryOption(key: 'transporte', label: 'Transporte', icono: LucideIcons.car, color: AppColors.p5),
    CategoryOption(key: 'estiloVida', label: 'Estilo de vida', icono: LucideIcons.sparkles, color: AppColors.pk),
    CategoryOption(key: 'salud', label: 'Salud', icono: LucideIcons.heartPulse, color: AppColors.e6),
    CategoryOption(key: 'educacion', label: 'Educacion', icono: LucideIcons.graduationCap, color: AppColors.b5),
    CategoryOption(key: 'entretenimiento', label: 'Entretenimiento', icono: LucideIcons.gamepad2, color: AppColors.a5),
    CategoryOption(key: 'servicios', label: 'Servicios', icono: LucideIcons.wrench, color: Color(0xFF6B7280)),
    CategoryOption(key: 'otro', label: 'Otro', icono: LucideIcons.moreHorizontal, color: AppColors.g5),
  ];

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialCatKey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 5,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.g2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Categoria", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.e8)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.x, size: 18, color: AppColors.g5),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Grid of categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final bool isSelected = _selectedKey == cat.key;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedKey = cat.key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? cat.color : const Color(0xFFF3F4F6),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: cat.color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                          : [const BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? cat.color.withValues(alpha: 0.15) : AppColors.g1,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(cat.icono, size: 22, color: isSelected ? cat.color : AppColors.g4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? cat.color : AppColors.g5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: (50 + index * 30).ms).slideY(begin: 0.08, end: 0, duration: 300.ms, delay: (50 + index * 30).ms);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Confirm button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  color: _selectedKey != null ? AppColors.o5 : AppColors.g2,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: _selectedKey != null
                      ? [const BoxShadow(color: Color(0x44F97316), blurRadius: 20, offset: Offset(0, 8))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  "Confirmar",
                  style: TextStyle(
                    color: _selectedKey != null ? Colors.white : AppColors.g4,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
