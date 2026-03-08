import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../budget_providers.dart';
import 'budget_detail_sheet.dart';
import 'wizard/create_budget_wizard.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  String _filtro = "Todos";
  final List<String> _filtros = ["Todos", "Mensual", "Quincenal", "Semanal", "Único"];

  String _fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  void _showDetail(MenudoBudget b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetDetailSheet(budget: b),
    );
  }

  void _showCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateBudgetWizard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIdx = ref.watch(selectedBudgetIdxProvider);

    final filteredBudgets = _filtro == "Todos"
        ? mockBudgets
        : mockBudgets.where((b) => b.periodo.toLowerCase() == _filtro.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Presupuestos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.e8)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.g2, height: 1),
        ),
        actions: [
          GestureDetector(
            onTap: _showCreate,
            child: Container(
              margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.o5,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [const BoxShadow(color: Color(0x44F97316), blurRadius: 14, offset: Offset(0, 5))],
              ),
              alignment: Alignment.center,
              child: const Text("+ Nuevo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [

          // ── "Activo en Dashboard" callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.e1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.e8.withValues(alpha: 0.15), width: 1),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.layoutDashboard, size: 15, color: AppColors.e7),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: AppColors.e8, fontFamily: 'PlusJakartaSans'),
                      children: [
                        const TextSpan(text: "Dashboard muestra: ", style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: mockBudgets[selectedIdx].nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const TextSpan(text: ". Toca otro presupuesto para cambiarlo."),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.04, end: 0, duration: 300.ms),

          // ── Period filters
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filtros.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = _filtros[i];
                final selected = p == _filtro;
                return GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _filtro = p); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.e8 : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: selected ? AppColors.e8 : AppColors.g2, width: 1.5),
                    ),
                    child: Text(p, style: TextStyle(color: selected ? Colors.white : AppColors.g5, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 80.ms),

          const SizedBox(height: 14),

          // ── Budget Cards
          ...filteredBudgets.asMap().entries.map((entry) {
            final globalIdx = mockBudgets.indexOf(entry.value);
            final b = entry.value;
            final double sp = b.cats.values.fold(0, (s, c) => s + c.gastado);
            final int usedPct = (sp / (b.ingresos > 0 ? b.ingresos : 1) * 100).round();
            final bool isDashboardActive = globalIdx == selectedIdx;

            return GestureDetector(
              onTap: () => _showDetail(b),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isDashboardActive ? AppColors.e8 : AppColors.g2,
                    width: isDashboardActive ? 2 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isDashboardActive
                      ? [const BoxShadow(color: Color(0x22065F46), blurRadius: 20, offset: Offset(0, 6))]
                      : [const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    // Dark header
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      decoration: BoxDecoration(
                        color: isDashboardActive ? AppColors.e8 : AppColors.g0,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isDashboardActive) ...[
                                      MenudoChip.custom(
                                        label: "En Dashboard",
                                        color: Colors.white,
                                        bgColor: Colors.white.withValues(alpha: 0.2),
                                        isSmall: true,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    MenudoChip.custom(
                                      label: b.periodo,
                                      color: isDashboardActive ? Colors.white.withValues(alpha: 0.7) : AppColors.g4,
                                      bgColor: isDashboardActive ? Colors.white.withValues(alpha: 0.15) : AppColors.g1,
                                      isSmall: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  b.nombre,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDashboardActive ? Colors.white : AppColors.e8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Member avatars
                          Row(
                            children: List.generate(b.miembros.length, (i) {
                              final m = b.miembros[i];
                              return Align(
                                widthFactor: i > 0 ? 0.7 : 1.0,
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: m.c,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDashboardActive ? AppColors.e8 : Colors.white, width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(m.i, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    // Stats + actions row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _statCol("GASTADO", _fmt(sp), AppColors.r5),
                              _statCol("RESTANTE", _fmt(b.ingresos - sp), AppColors.e6, center: true),
                              _statCol("TOTAL", _fmt(b.ingresos), AppColors.e8, right: true),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 7,
                            decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(4)),
                            child: LayoutBuilder(builder: (_, constraints) => AnimatedContainer(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              height: 7,
                              width: constraints.maxWidth * min(usedPct / 100, 1.0),
                              decoration: BoxDecoration(
                                color: usedPct > 90 ? AppColors.r5 : usedPct > 70 ? AppColors.a5 : AppColors.o5,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("$usedPct% usado · Día ${b.diaInicio}", style: const TextStyle(fontSize: 11, color: AppColors.g4)),
                              // "Usar en Dashboard" button
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(selectedBudgetIdxProvider.notifier).state = globalIdx;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${b.nombre} seleccionado en Dashboard', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      backgroundColor: AppColors.e8,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDashboardActive ? AppColors.e8 : AppColors.g1,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isDashboardActive ? LucideIcons.checkCircle : LucideIcons.layoutDashboard,
                                        size: 11,
                                        color: isDashboardActive ? Colors.white : AppColors.g5,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isDashboardActive ? "Activo" : "Usar",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDashboardActive ? Colors.white : AppColors.g5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 380.ms, delay: (100 + entry.key * 80).ms).slideY(begin: 0.04, end: 0, duration: 380.ms, delay: (100 + entry.key * 80).ms);
          }),

          // ── Create card
          GestureDetector(
            onTap: _showCreate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.o1,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.o5.withValues(alpha: 0.3), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.o5.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(LucideIcons.clipboardList, size: 26, color: AppColors.o5),
                  ),
                  const SizedBox(height: 8),
                  const Text("Crear nuevo presupuesto", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.e8)),
                  const SizedBox(height: 3),
                  const Text("Mensual · Quincenal · Semanal · Único", style: TextStyle(fontSize: 12, color: AppColors.g5)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color valueColor, {bool center = false, bool right = false}) {
    return Column(
      crossAxisAlignment: right ? CrossAxisAlignment.end : center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.g4, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor)),
      ],
    );
  }
}
