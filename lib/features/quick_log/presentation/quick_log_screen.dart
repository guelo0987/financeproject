import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key});

  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends State<QuickLogScreen> {
  bool _isIncome = true;
  String _amount = '0';
  String _description = '';
  String? _selectedCategory;
  bool _isRecommendingCategory = false;
  double? _iaConfidence;

  static const _incomeCategories = [
    _LogCategory('Salario', MenudoCupertinoIcons.work),
    _LogCategory('Dividendos', MenudoCupertinoIcons.trending_up),
    _LogCategory('Venta', MenudoCupertinoIcons.sell),
    _LogCategory('Freelance', MenudoCupertinoIcons.laptop),
    _LogCategory('Regalo', MenudoCupertinoIcons.card_giftcard),
    _LogCategory('Otro', MenudoCupertinoIcons.more_horiz),
  ];

  static const _expenseCategories = [
    _LogCategory('Vivienda', MenudoCupertinoIcons.home),
    _LogCategory('Alimentación', MenudoCupertinoIcons.restaurant),
    _LogCategory('Transporte', MenudoCupertinoIcons.directions_car),
    _LogCategory('Entretenimiento', MenudoCupertinoIcons.movie),
    _LogCategory('Salud', MenudoCupertinoIcons.health_and_safety),
    _LogCategory('Servicios', MenudoCupertinoIcons.electrical_services),
    _LogCategory('Inversión', MenudoCupertinoIcons.trending_up),
    _LogCategory('Transferencia', MenudoCupertinoIcons.swap_horiz),
    _LogCategory('Otro', MenudoCupertinoIcons.more_horiz),
  ];

  void _onKeyTap(String key) {
    MenudoHaptics.light();
    setState(() {
      if (key == 'DEL') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0') {
          _amount = key;
        } else {
          _amount += key;
        }
      }
    });
  }

  void _suggestCategoryWithIa() {
    if (_description.isEmpty) return;

    setState(() {
      _isRecommendingCategory = true;
      _selectedCategory = null;
      _iaConfidence = null;
    });

    // Mock API Call to Claude
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      setState(() {
        _isRecommendingCategory = false;

        // Simple mock matching based on words
        final lowerDesc = _description.toLowerCase();
        if (lowerDesc.contains('supermercado') ||
            lowerDesc.contains('comida') ||
            lowerDesc.contains('restaurante')) {
          _selectedCategory = 'Alimentación';
          _iaConfidence = 0.95;
        } else if (lowerDesc.contains('uber') ||
            lowerDesc.contains('gasolina') ||
            lowerDesc.contains('transporte')) {
          _selectedCategory = 'Transporte';
          _iaConfidence = 0.92;
        } else if (lowerDesc.contains('netflix') ||
            lowerDesc.contains('cine') ||
            lowerDesc.contains('suscripción')) {
          _selectedCategory = 'Entretenimiento';
          _iaConfidence = 0.98;
        } else if (lowerDesc.contains('pago') ||
            lowerDesc.contains('salario') ||
            lowerDesc.contains('sueldo')) {
          _selectedCategory = 'Salario';
          _iaConfidence = 0.90;
        } else {
          _selectedCategory = 'Otro';
          _iaConfidence = 0.65;
        }
      });
      MenudoHaptics.light();
    });
  }

  void _onSave() {
    final value = double.tryParse(_amount) ?? 0;
    if (value > 0 && _selectedCategory != null) {
      MenudoHaptics.success();
      setState(() {
        _amount = '0';
        _description = '';
        _selectedCategory = null;
        _iaConfidence = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.##', currentLocaleTag());
    final parsedAmount = double.tryParse(_amount) ?? 0;
    final categories = _isIncome ? _incomeCategories : _expenseCategories;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header & Toggle ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Text('Registro Rápido', style: AppTextStyles.headlineLarge),
                  SizedBox(height: (16)),
                  // Toggle
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.menudo.surfaceElevated,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusRound,
                      ),
                      border: Border.all(color: context.menudo.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: MenudoGestureDetector(
                            onTap: () {
                              MenudoHaptics.selection();
                              setState(() {
                                _isIncome = true;
                                _selectedCategory = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: AppConstants.animFast,
                              decoration: BoxDecoration(
                                color: _isIncome
                                    ? AppColors.positive.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusRound,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'ENTRADA',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: _isIncome
                                        ? AppColors.positive
                                        : context.menudo.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: MenudoGestureDetector(
                            onTap: () {
                              MenudoHaptics.selection();
                              setState(() {
                                _isIncome = false;
                                _selectedCategory = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: AppConstants.animFast,
                              decoration: BoxDecoration(
                                color: !_isIncome
                                    ? AppColors.negative.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusRound,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'SALIDA',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: !_isIncome
                                        ? AppColors.negative
                                        : context.menudo.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Amount Display ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    currentCurrencyPrefix(),
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    parsedAmount > 0 ? formatter.format(parsedAmount) : '0',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: _isIncome
                          ? AppColors.positive
                          : AppColors.negative,
                      fontSize: 52,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

            // ── Description Input ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: context.menudo.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.menudo.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => _description = val,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Descripción (ej. "Uber al trabajo")',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: context.menudo.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_description.isNotEmpty)
                      MenudoGestureDetector(
                        onTap: _isRecommendingCategory
                            ? null
                            : _suggestCategoryWithIa,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: _isRecommendingCategory
                              ? SizedBox(
                                  width: (16),
                                  height: (16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  ),
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      MenudoCupertinoIcons.smart_toy,
                                      size: (16),
                                      color: AppColors.accent,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Sugerir con IA',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

            SizedBox(height: (24)),

            // ── Category Selector ──
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, _) => SizedBox(width: (10)),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat.label;
                  return MenudoGestureDetector(
                    onTap: () {
                      MenudoHaptics.selection();
                      setState(() => _selectedCategory = cat.label);
                    },
                    child: AnimatedContainer(
                      duration: AppConstants.animFast,
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (_isIncome
                                  ? context.menudo.successLight
                                  : context.menudo.dangerLight)
                            : context.menudo.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? (_isIncome
                                    ? AppColors.positive
                                    : AppColors.negative)
                              : context.menudo.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat.icon,
                            size: (22),
                            color: isSelected
                                ? (_isIncome
                                      ? AppColors.positive
                                      : AppColors.negative)
                                : context.menudo.textSecondary,
                          ),
                          SizedBox(height: 4),
                          Text(
                            cat.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? context.menudo.textMain
                                  : context.menudo.textSecondary,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isSelected && _iaConfidence != null) ...[
                            SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.menudo.surfaceElevated
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(_iaConfidence! * 100).toInt()}% IA',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: _iaConfidence! > 0.8
                                      ? AppColors.positive
                                      : AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

            const Spacer(),

            // ── Number Pad ──
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
              child: Column(
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['.', '0', 'DEL'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: row.map((key) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: MenudoInkWell(
                                  onTap: () => _onKeyTap(key),
                                  borderRadius: BorderRadius.circular(14),
                                  splashColor: AppColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: context.menudo.surfaceElevated,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: context.menudo.border,
                                      ),
                                    ),
                                    child: Center(
                                      child: key == 'DEL'
                                          ? Icon(
                                              MenudoCupertinoIcons
                                                  .backspace_outlined,
                                              color:
                                                  context.menudo.textSecondary,
                                              size: (22),
                                            )
                                          : Text(
                                              key,
                                              style: AppTextStyles.numpadKey,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 300.ms),

            // ── Save Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 4, 32, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (parsedAmount > 0 && _selectedCategory != null)
                      ? _onSave
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isIncome
                        ? AppColors.positive
                        : AppColors.negative,
                    foregroundColor: context.menudo.background,
                    disabledBackgroundColor: context.menudo.surfaceElevated,
                    disabledForegroundColor: context.menudo.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Registrar ${_isIncome ? "Entrada" : "Salida"}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: (parsedAmount > 0 && _selectedCategory != null)
                          ? context.menudo.background
                          : context.menudo.textMuted,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _LogCategory {
  final String label;
  final IconData icon;
  const _LogCategory(this.label, this.icon);
}
