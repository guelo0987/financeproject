import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

// Default category definition
class _CategoryDef {
  final String key;
  final String label;
  final IconData icono;
  final Color color;
  final String descripcion;
  final bool isDefault;

  const _CategoryDef({
    required this.key,
    required this.label,
    required this.icono,
    required this.color,
    required this.descripcion,
    this.isDefault = true,
  });
}

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final List<_CategoryDef> _defaults = const [
    _CategoryDef(key: 'vivienda',       label: 'Vivienda',        icono: LucideIcons.home,          color: AppColors.e7,  descripcion: 'Alquiler, hipoteca, mantenimiento del hogar'),
    _CategoryDef(key: 'comida',         label: 'Comida',          icono: LucideIcons.utensils,      color: AppColors.o5,  descripcion: 'Supermercado, restaurantes, delivery'),
    _CategoryDef(key: 'transporte',     label: 'Transporte',      icono: LucideIcons.car,           color: AppColors.p5,  descripcion: 'Gasolina, Uber, metro, parking'),
    _CategoryDef(key: 'estiloVida',     label: 'Estilo de vida',  icono: LucideIcons.sparkles,      color: AppColors.pk,  descripcion: 'Ropa, accesorios, suscripciones lifestyle'),
    _CategoryDef(key: 'salud',          label: 'Salud',           icono: LucideIcons.heartPulse,    color: AppColors.e6,  descripcion: 'Médico, farmacia, seguro médico'),
    _CategoryDef(key: 'educacion',      label: 'Educación',       icono: LucideIcons.graduationCap, color: AppColors.b5,  descripcion: 'Cursos, libros, universidades'),
    _CategoryDef(key: 'entretenimiento',label: 'Entretenimiento', icono: LucideIcons.gamepad2,      color: AppColors.pk,  descripcion: 'Streaming, cine, conciertos, juegos'),
    _CategoryDef(key: 'servicios',      label: 'Servicios',       icono: LucideIcons.lightbulb,     color: AppColors.a5,  descripcion: 'Luz, agua, internet, teléfono'),
    _CategoryDef(key: 'inversion',      label: 'Inversión',       icono: LucideIcons.trendingUp,    color: AppColors.e8,  descripcion: 'CDPs, acciones, fondos mutuos'),
    _CategoryDef(key: 'otro',           label: 'Otro',            icono: LucideIcons.moreHorizontal, color: AppColors.g4, descripcion: 'Gastos no clasificados'),
  ];

  final List<_CategoryDef> _custom = [];
  bool _showAddForm = false;
  final _nameController = TextEditingController();
  IconData _selectedIcon = LucideIcons.tag;
  Color _selectedColor = AppColors.e6;

  final List<IconData> _iconOptions = [
    LucideIcons.tag, LucideIcons.gift, LucideIcons.coffee, LucideIcons.shoppingBag,
    LucideIcons.dumbbell, LucideIcons.plane, LucideIcons.dog, LucideIcons.baby,
    LucideIcons.music, LucideIcons.camera, LucideIcons.wrench, LucideIcons.briefcase,
  ];

  final List<Color> _colorOptions = [
    AppColors.e6, AppColors.o5, AppColors.b5, AppColors.p5,
    AppColors.pk, AppColors.a5, AppColors.r5, AppColors.e8,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addCustomCategory() {
    if (_nameController.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _custom.add(_CategoryDef(
        key: _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
        label: _nameController.text.trim(),
        icono: _selectedIcon,
        color: _selectedColor,
        descripcion: 'Categoría personalizada',
        isDefault: false,
      ));
      _nameController.clear();
      _showAddForm = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Categoría creada', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.e6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.e8, size: 22),
          ),
        ),
        title: const Text('Herramientas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [const BoxShadow(color: Color(0x33065F46), blurRadius: 32, offset: Offset(0, 10))],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.layoutGrid, size: 26, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Categorías", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("${_defaults.length} por defecto · ${_custom.length} tuyas", style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 24),

          // Default categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Categorías por defecto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
              Text("${_defaults.length}", style: const TextStyle(fontSize: 13, color: AppColors.g4, fontWeight: FontWeight.w600)),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          const SizedBox(height: 4),
          const Text("Disponibles en todos tus presupuestos", style: TextStyle(fontSize: 12, color: AppColors.g4)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: List.generate(_defaults.length, (i) {
                final cat = _defaults[i];
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 68, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Icon(cat.icono, size: 19, color: cat.color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8)),
                                const SizedBox(height: 2),
                                Text(cat.descripcion, style: const TextStyle(fontSize: 11, color: AppColors.g4), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.e1, borderRadius: BorderRadius.circular(6)),
                            child: const Text("Default", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.e6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 150.ms),

          const SizedBox(height: 24),

          // Custom categories header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Mis categorías", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _showAddForm = !_showAddForm);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.o5,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [const BoxShadow(color: Color(0x44F97316), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: const Text("+ Nueva", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 250.ms),

          // Add form
          if (_showAddForm) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.o5.withValues(alpha: 0.4), width: 1.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nueva categoría", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.e8)),
                  const SizedBox(height: 14),
                  // Name field
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.e8),
                    decoration: InputDecoration(
                      hintText: "Nombre de la categoría",
                      hintStyle: const TextStyle(color: AppColors.g4),
                      filled: true,
                      fillColor: AppColors.g0,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Icon selector
                  const Text("Icono", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.g4)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _iconOptions.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedIcon = icon); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? _selectedColor.withValues(alpha: 0.15) : AppColors.g1,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? _selectedColor : Colors.transparent, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, size: 20, color: isSelected ? _selectedColor : AppColors.g4),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Color selector
                  const Text("Color", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.g4)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _colorOptions.map((color) {
                      final isSelected = color == _selectedColor;
                      return GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedColor = color); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? AppColors.e8 : Colors.transparent, width: 3),
                          ),
                          alignment: Alignment.center,
                          child: isSelected ? const Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showAddForm = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: const Text("Cancelar", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.g5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _addCustomCategory,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.o5,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [const BoxShadow(color: Color(0x44F97316), blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            alignment: Alignment.center,
                            child: const Text("Guardar", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0, duration: 300.ms),
          ],

          const SizedBox(height: 12),

          // Custom categories list
          if (_custom.isEmpty && !_showAddForm)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.plus, size: 26, color: AppColors.g3),
                  ),
                  const SizedBox(height: 12),
                  const Text("Sin categorías personalizadas", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8)),
                  const SizedBox(height: 4),
                  const Text("Crea una nueva para organizar tus finanzas a tu manera", style: TextStyle(fontSize: 12, color: AppColors.g4), textAlign: TextAlign.center),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 300.ms)
          else if (_custom.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: List.generate(_custom.length, (i) {
                  final cat = _custom[i];
                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 68, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.center,
                              child: Icon(cat.icono, size: 19, color: cat.color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(cat.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8)),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setState(() => _custom.removeAt(i));
                              },
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: AppColors.r1, borderRadius: BorderRadius.circular(10)),
                                alignment: Alignment.center,
                                child: const Icon(LucideIcons.trash2, size: 15, color: AppColors.r5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
        ],
      ),
    );
  }
}
