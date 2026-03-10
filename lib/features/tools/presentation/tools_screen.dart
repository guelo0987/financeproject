import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  // Loan calculator state
  bool _loanExpanded = false;
  double _loanMonto = 100000;
  double _loanTasa = 18;
  int _loanMeses = 12;

  // CDP calculator state
  bool _cdpExpanded = false;
  double _cdpMonto = 50000;
  double _cdpTasa = 10;
  int _cdpMeses = 12;

  double get _loanCuota {
    final r = _loanTasa / 100 / 12;
    if (r == 0) return _loanMonto / _loanMeses;
    return _loanMonto *
        r *
        pow(1 + r, _loanMeses) /
        (pow(1 + r, _loanMeses) - 1);
  }

  double get _loanTotal => _loanCuota * _loanMeses;
  double get _loanIntereses => _loanTotal - _loanMonto;

  double get _cdpRendimiento => _cdpMonto * (_cdpTasa / 100) * (_cdpMeses / 12);
  double get _cdpTotal => _cdpMonto + _cdpRendimiento;

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.e8, size: 22),
          ),
        ),
        title: const Text(
          'Herramientas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.e8,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // ── Quick Links ────────────────────────────────────────────
          const Text(
            "Accesos rápidos",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.g4,
              letterSpacing: 0.3,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 10),

          Row(
            children: [
              _quickLink(
                icon: LucideIcons.pieChart,
                label: "Categorías",
                color: AppColors.e6,
                bg: AppColors.e1,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
              const SizedBox(width: 10),
              _quickLink(
                icon: LucideIcons.repeat2,
                label: "Automáticas",
                color: AppColors.o5,
                bg: AppColors.o1,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecurringScreen()),
                ),
              ),
              const SizedBox(width: 10),
              _quickLink(
                icon: LucideIcons.clock,
                label: "Historial",
                color: AppColors.p5,
                bg: const Color(0xFFF3EEFF),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/history');
                },
              ),
              const SizedBox(width: 10),
              _quickLink(
                icon: LucideIcons.wallet,
                label: "Cuentas",
                color: AppColors.b5,
                bg: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/wallet');
                },
              ),
            ],
          ).animate().fadeIn(duration: 380.ms, delay: 50.ms),

          const SizedBox(height: 28),

          // ── Loan calculator ────────────────────────────────────────
          const Text(
            "Calculadoras financieras",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.g4,
              letterSpacing: 0.3,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _loanExpanded = !_loanExpanded);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _loanExpanded
                      ? AppColors.r5.withValues(alpha: 0.3)
                      : const Color(0xFFF3F4F6),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.r1,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.percent,
                          size: 22,
                          color: AppColors.r5,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Calculadora de préstamo",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.e8,
                              ),
                            ),
                            Text(
                              "Cuota mensual e intereses totales",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.g4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _loanExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: AppColors.g4,
                        ),
                      ),
                    ],
                  ),

                  if (_loanExpanded) ...[
                    const SizedBox(height: 20),
                    _sliderRow(
                      "Monto",
                      _fmt(_loanMonto),
                      _loanMonto,
                      10000,
                      2000000,
                      (v) => setState(() => _loanMonto = v),
                    ),
                    const SizedBox(height: 14),
                    _sliderRow(
                      "Tasa anual",
                      "${_loanTasa.round()}%",
                      _loanTasa,
                      1,
                      50,
                      (v) => setState(() => _loanTasa = v),
                    ),
                    const SizedBox(height: 14),
                    _sliderRow(
                      "Plazo",
                      "$_loanMeses meses",
                      _loanMeses.toDouble(),
                      3,
                      60,
                      (v) => setState(() => _loanMeses = v.round()),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.r1,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _resultColumn(
                              "CUOTA MENSUAL",
                              _fmt(_loanCuota),
                              AppColors.r5,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.r5.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _resultColumn(
                              "INTERESES TOTALES",
                              _fmt(_loanIntereses),
                              AppColors.r5,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.r5.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _resultColumn(
                              "TOTAL A PAGAR",
                              _fmt(_loanTotal),
                              AppColors.e8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 380.ms, delay: 150.ms),

          const SizedBox(height: 12),

          // ── CDP Calculator ─────────────────────────────────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _cdpExpanded = !_cdpExpanded);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _cdpExpanded
                      ? AppColors.e6.withValues(alpha: 0.3)
                      : const Color(0xFFF3F4F6),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.e1,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.building2,
                          size: 22,
                          color: AppColors.e6,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Simulador de CDP",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.e8,
                              ),
                            ),
                            Text(
                              "Proyecta tus rendimientos en pesos",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.g4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _cdpExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: AppColors.g4,
                        ),
                      ),
                    ],
                  ),

                  if (_cdpExpanded) ...[
                    const SizedBox(height: 20),
                    _sliderRow(
                      "Capital inicial",
                      _fmt(_cdpMonto),
                      _cdpMonto,
                      5000,
                      1000000,
                      (v) => setState(() => _cdpMonto = v),
                    ),
                    const SizedBox(height: 14),
                    _sliderRow(
                      "Tasa anual",
                      "${_cdpTasa.round()}%",
                      _cdpTasa,
                      1,
                      25,
                      (v) => setState(() => _cdpTasa = v),
                    ),
                    const SizedBox(height: 14),
                    _sliderRow(
                      "Plazo",
                      "$_cdpMeses meses",
                      _cdpMeses.toDouble(),
                      1,
                      36,
                      (v) => setState(() => _cdpMeses = v.round()),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.e1,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _resultColumn(
                              "RENDIMIENTO",
                              _fmt(_cdpRendimiento),
                              AppColors.e6,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppColors.e6.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _resultColumn(
                              "TOTAL FINAL",
                              _fmt(_cdpTotal),
                              AppColors.e8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 380.ms, delay: 200.ms),

          const SizedBox(height: 28),

          // ── Data & Export ──────────────────────────────────────────
          const Text(
            "Gestión de datos",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.g4,
              letterSpacing: 0.3,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 250.ms),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
            ),
            child: Column(
              children: [
                _actionRow(
                  icon: LucideIcons.fileDown,
                  iconColor: AppColors.b5,
                  bgColor: const Color(0xFFEFF6FF),
                  label: "Exportar historial (CSV)",
                  subtitle: "Descarga todas tus transacciones",
                  showDivider: true,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Exportando historial a CSV...',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: AppColors.b5,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                _actionRow(
                  icon: LucideIcons.share2,
                  iconColor: AppColors.p5,
                  bgColor: const Color(0xFFF3EEFF),
                  label: "Compartir resumen mensual",
                  subtitle: "Genera una imagen de tu mes financiero",
                  showDivider: false,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Generando imagen del resumen...',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: AppColors.p5,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 380.ms, delay: 280.ms),
        ],
      ),
    );
  }

  Widget _quickLink({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.g2, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.g5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderRow(
    String label,
    String valueLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.g5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.g1,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                valueLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.e8,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackHeight: 4,
            activeTrackColor: AppColors.o5,
            inactiveTrackColor: AppColors.g1,
            thumbColor: AppColors.o5,
            overlayColor: AppColors.o5.withValues(alpha: 0.15),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _resultColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.6),
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String subtitle,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.e8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.g4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.g3,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: Color(0xFFF3F4F6),
            indent: 68,
            endIndent: 16,
          ),
      ],
    );
  }
}
