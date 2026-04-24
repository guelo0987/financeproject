import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import 'package:go_router/go_router.dart';

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
  bool get _showsIosShortcuts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String _fmt(double val) => formatMoney(val);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.menudo.background,
      appBar: AppBar(
        backgroundColor: context.menudo.surface,
        elevation: 0,
        leading: MenudoGestureDetector(
          onTap: () {
            MenudoHaptics.light();
            Navigator.pop(context);
          },
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              MenudoCupertinoIcons.arrowLeft,
              color: context.menudo.textMain,
              size: (22),
            ),
          ),
        ),
        title: Text(
          'Herramientas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // ── Quick Links ────────────────────────────────────────────
          Text(
            "Accesos rápidos",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.menudo.textMuted,
              letterSpacing: 0.3,
            ),
          ).animate().fadeIn(duration: 300.ms),
          SizedBox(height: (10)),

          Row(
            children: [
              _quickLink(
                icon: MenudoCupertinoIcons.pieChart,
                label: "Categorías",
                color: AppColors.e6,
                bg: AppColors.e1,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
              SizedBox(width: (10)),
              _quickLink(
                icon: MenudoCupertinoIcons.repeat2,
                label: "Automáticas",
                color: AppColors.o5,
                bg: AppColors.o1,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecurringScreen()),
                ),
              ),
              SizedBox(width: (10)),
              _quickLink(
                icon: MenudoCupertinoIcons.clock,
                label: "Historial",
                color: AppColors.p5,
                bg: const Color(0xFFF3EEFF),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/history');
                },
              ),
              SizedBox(width: (10)),
              _quickLink(
                icon: MenudoCupertinoIcons.wallet,
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

          if (_showsIosShortcuts) ...[
            SizedBox(height: (14)),
            _shortcutLauncherCard(
              context,
            ).animate().fadeIn(duration: 380.ms, delay: 80.ms),
          ],

          SizedBox(height: (28)),

          // ── Loan calculator ────────────────────────────────────────
          Text(
            "Calculadoras financieras",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.menudo.textMuted,
              letterSpacing: 0.3,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          SizedBox(height: (10)),

          MenudoGestureDetector(
            onTap: () {
              MenudoHaptics.light();
              setState(() => _loanExpanded = !_loanExpanded);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.menudo.textOnDark,
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
                        child: Icon(
                          MenudoCupertinoIcons.percent,
                          size: (22),
                          color: AppColors.r5,
                        ),
                      ),
                      SizedBox(width: (14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Calculadora de préstamo",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: context.menudo.textMain,
                              ),
                            ),
                            Text(
                              "Cuota mensual e intereses totales",
                              style: TextStyle(
                                fontSize: 12,
                                color: context.menudo.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _loanExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          MenudoCupertinoIcons.chevronDown,
                          size: (18),
                          color: context.menudo.textMuted,
                        ),
                      ),
                    ],
                  ),

                  if (_loanExpanded) ...[
                    SizedBox(height: (20)),
                    _sliderRow(
                      "Monto",
                      _fmt(_loanMonto),
                      _loanMonto,
                      10000,
                      2000000,
                      (v) => setState(() => _loanMonto = v),
                    ),
                    SizedBox(height: (14)),
                    _sliderRow(
                      "Tasa anual",
                      "${_loanTasa.round()}%",
                      _loanTasa,
                      1,
                      50,
                      (v) => setState(() => _loanTasa = v),
                    ),
                    SizedBox(height: (14)),
                    _sliderRow(
                      "Plazo",
                      "$_loanMeses meses",
                      _loanMeses.toDouble(),
                      3,
                      60,
                      (v) => setState(() => _loanMeses = v.round()),
                    ),
                    SizedBox(height: (20)),
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
                              context.menudo.primary,
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

          SizedBox(height: (12)),

          // ── CDP Calculator ─────────────────────────────────────────
          MenudoGestureDetector(
            onTap: () {
              MenudoHaptics.light();
              setState(() => _cdpExpanded = !_cdpExpanded);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.menudo.textOnDark,
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
                        child: Icon(
                          MenudoCupertinoIcons.building2,
                          size: (22),
                          color: AppColors.e6,
                        ),
                      ),
                      SizedBox(width: (14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Simulador de CDP",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: context.menudo.textMain,
                              ),
                            ),
                            Text(
                              "Proyecta tus rendimientos en pesos",
                              style: TextStyle(
                                fontSize: 12,
                                color: context.menudo.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _cdpExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          MenudoCupertinoIcons.chevronDown,
                          size: (18),
                          color: context.menudo.textMuted,
                        ),
                      ),
                    ],
                  ),

                  if (_cdpExpanded) ...[
                    SizedBox(height: (20)),
                    _sliderRow(
                      "Capital inicial",
                      _fmt(_cdpMonto),
                      _cdpMonto,
                      5000,
                      1000000,
                      (v) => setState(() => _cdpMonto = v),
                    ),
                    SizedBox(height: (14)),
                    _sliderRow(
                      "Tasa anual",
                      "${_cdpTasa.round()}%",
                      _cdpTasa,
                      1,
                      25,
                      (v) => setState(() => _cdpTasa = v),
                    ),
                    SizedBox(height: (14)),
                    _sliderRow(
                      "Plazo",
                      "$_cdpMeses meses",
                      _cdpMeses.toDouble(),
                      1,
                      36,
                      (v) => setState(() => _cdpMeses = v.round()),
                    ),
                    SizedBox(height: (20)),
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
                              context.menudo.primary,
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
      child: MenudoGestureDetector(
        onTap: () {
          MenudoHaptics.light();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: context.menudo.textOnDark,
            border: Border.all(color: context.menudo.border, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: (38),
                height: (38),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: (18), color: color),
              ),
              SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textSecondary,
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.menudo.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.menudo.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
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
            inactiveTrackColor: context.menudo.surface,
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
        SizedBox(height: 4),
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

  Widget _shortcutLauncherCard(BuildContext context) {
    return MenudoGestureDetector(
      onTap: () {
        MenudoHaptics.medium();
        context.push('/shortcuts');
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.menudo.textOnDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.o1,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(
                MenudoCupertinoIcons.zap,
                color: AppColors.o5,
                size: (24),
              ),
            ),
            SizedBox(width: (14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Automatizaciones",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Gasto rápido desde accesos del dispositivo",
                    style: TextStyle(
                      fontSize: 13,
                      color: context.menudo.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              MenudoCupertinoIcons.chevronRight,
              color: context.menudo.textMuted,
              size: (18),
            ),
          ],
        ),
      ),
    );
  }
}
