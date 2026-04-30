import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/shared/widgets/menudo_blurred_app_bar.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        flexibleSpace: const MenudoBlurredBar(),
        centerTitle: false,
        leading: MenudoGestureDetector(
          onTap: () {
            MenudoHaptics.light();
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              MenudoCupertinoIcons.arrowLeft,
              color: context.menudo.textMain,
              size: (24),
            ),
          ),
        ),
        title: Text(
          'Herramientas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
          16,
          100,
        ),
        children: [
          // ── Quick Links ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Accesos rápidos",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.menudo.textMain,
                letterSpacing: 0.2,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          Row(
            children: [
              _quickLink(
                icon: MenudoCupertinoIcons.pieChart,
                label: "Categorías",
                color: AppColors.e6,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
              const SizedBox(width: (10)),
              _quickLink(
                icon: MenudoCupertinoIcons.repeat2,
                label: "Automáticas",
                color: AppColors.o5,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecurringScreen()),
                ),
              ),
              const SizedBox(width: (10)),
              _quickLink(
                icon: MenudoCupertinoIcons.clock,
                label: "Historial",
                color: AppColors.p5,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/history');
                },
              ),
              const SizedBox(width: (10)),
              _quickLink(
                icon: MenudoCupertinoIcons.wallet,
                label: "Cuentas",
                color: AppColors.b5,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/wallet');
                },
              ),
            ],
          ).animate().fadeIn(duration: 380.ms, delay: 50.ms),

          if (_showsIosShortcuts) ...[
            const SizedBox(height: (16)),
            _shortcutLauncherCard(
              context,
            ).animate().fadeIn(duration: 380.ms, delay: 80.ms),
          ],

          const SizedBox(height: (32)),

          // ── Loan calculator ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Calculadoras",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.menudo.textMain,
                letterSpacing: 0.2,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          MenudoGestureDetector(
            onTap: () {
              MenudoHaptics.light();
              setState(() => _loanExpanded = !_loanExpanded);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.menudo.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _loanExpanded
                      ? AppColors.r5.withValues(alpha: 0.3)
                      : context.menudo.border.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: _loanExpanded
                    ? [
                        BoxShadow(
                          color: AppColors.r5.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.r5.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          MenudoCupertinoIcons.percent,
                          size: (24),
                          color: AppColors.r5,
                        ),
                      ),
                      const SizedBox(width: (16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Préstamo",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.menudo.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Cuota mensual e intereses",
                              style: TextStyle(
                                fontSize: 13,
                                color: context.menudo.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _loanExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.menudo.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            MenudoCupertinoIcons.chevronDown,
                            size: (16),
                            color: context.menudo.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_loanExpanded) ...[
                    const SizedBox(height: (24)),
                    _sliderRow(
                      "Monto",
                      _fmt(_loanMonto),
                      _loanMonto,
                      10000,
                      2000000,
                      (v) => setState(() => _loanMonto = v),
                      AppColors.r5,
                    ),
                    const SizedBox(height: (16)),
                    _sliderRow(
                      "Tasa anual",
                      "${_loanTasa.round()}%",
                      _loanTasa,
                      1,
                      50,
                      (v) => setState(() => _loanTasa = v),
                      AppColors.r5,
                    ),
                    const SizedBox(height: (16)),
                    _sliderRow(
                      "Plazo",
                      "$_loanMeses meses",
                      _loanMeses.toDouble(),
                      3,
                      60,
                      (v) => setState(() => _loanMeses = v.round()),
                      AppColors.r5,
                    ),
                    const SizedBox(height: (24)),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.menudo.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.r5.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "CUOTA MENSUAL",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.r5.withValues(alpha: 0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _fmt(_loanCuota),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.r5,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: AppColors.r5.withValues(alpha: 0.1),
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "INTERESES",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.menudo.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _fmt(_loanIntereses),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.menudo.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: AppColors.r5.withValues(alpha: 0.1),
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TOTAL A PAGAR",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: context.menudo.textMain,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _fmt(_loanTotal),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: context.menudo.textMain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 380.ms, delay: 150.ms),

          const SizedBox(height: (16)),

          // ── CDP Calculator ─────────────────────────────────────────
          MenudoGestureDetector(
            onTap: () {
              MenudoHaptics.light();
              setState(() => _cdpExpanded = !_cdpExpanded);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.menudo.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _cdpExpanded
                      ? AppColors.e6.withValues(alpha: 0.3)
                      : context.menudo.border.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: _cdpExpanded
                    ? [
                        BoxShadow(
                          color: AppColors.e6.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.e6.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          MenudoCupertinoIcons.building2,
                          size: (24),
                          color: AppColors.e6,
                        ),
                      ),
                      const SizedBox(width: (16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Simulador CDP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.menudo.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Proyecta tus rendimientos",
                              style: TextStyle(
                                fontSize: 13,
                                color: context.menudo.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _cdpExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.menudo.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            MenudoCupertinoIcons.chevronDown,
                            size: (16),
                            color: context.menudo.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_cdpExpanded) ...[
                    const SizedBox(height: (24)),
                    _sliderRow(
                      "Capital inicial",
                      _fmt(_cdpMonto),
                      _cdpMonto,
                      5000,
                      1000000,
                      (v) => setState(() => _cdpMonto = v),
                      AppColors.e6,
                    ),
                    const SizedBox(height: (16)),
                    _sliderRow(
                      "Tasa anual",
                      "${_cdpTasa.round()}%",
                      _cdpTasa,
                      1,
                      25,
                      (v) => setState(() => _cdpTasa = v),
                      AppColors.e6,
                    ),
                    const SizedBox(height: (16)),
                    _sliderRow(
                      "Plazo",
                      "$_cdpMeses meses",
                      _cdpMeses.toDouble(),
                      1,
                      36,
                      (v) => setState(() => _cdpMeses = v.round()),
                      AppColors.e6,
                    ),
                    const SizedBox(height: (24)),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.menudo.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.e6.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "RENDIMIENTO",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.e6.withValues(alpha: 0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "+${_fmt(_cdpRendimiento)}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.e6,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: AppColors.e6.withValues(alpha: 0.1),
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "CAPITAL INICIAL",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.menudo.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _fmt(_cdpMonto),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.menudo.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: AppColors.e6.withValues(alpha: 0.1),
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TOTAL FINAL",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: context.menudo.textMain,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _fmt(_cdpTotal),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: context.menudo.textMain,
                                ),
                              ),
                            ],
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
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: MenudoGestureDetector(
        onTap: () {
          MenudoHaptics.light();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: (22), color: color),
              ),
              const SizedBox(height: (10)),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    Color activeColor,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.menudo.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: activeColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 2,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: activeColor,
            inactiveTrackColor: context.menudo.surface,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.15),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.menudo.border.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.o5.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                MenudoCupertinoIcons.zap,
                color: AppColors.o5,
                size: (24),
              ),
            ),
            const SizedBox(width: (16)),
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
                  const SizedBox(height: 4),
                  Text(
                    "Gasto rápido desde accesos del dispositivo",
                    style: TextStyle(
                      fontSize: 13,
                      color: context.menudo.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.menudo.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                MenudoCupertinoIcons.chevronRight,
                color: context.menudo.textSecondary,
                size: (16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
