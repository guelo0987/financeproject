import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';


class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key});

  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends State<QuickLogScreen> {
  bool _isIncome = true;
  String _amount = '0';
  String? _selectedCategory;

  static const _incomeCategories = [
    _LogCategory('Salario', Icons.work),
    _LogCategory('Dividendos', Icons.trending_up),
    _LogCategory('Venta', Icons.sell),
    _LogCategory('Freelance', Icons.laptop),
    _LogCategory('Regalo', Icons.card_giftcard),
    _LogCategory('Otro', Icons.more_horiz),
  ];

  static const _expenseCategories = [
    _LogCategory('Vivienda', Icons.home),
    _LogCategory('Alimentación', Icons.restaurant),
    _LogCategory('Transporte', Icons.directions_car),
    _LogCategory('Entretenimiento', Icons.movie),
    _LogCategory('Salud', Icons.health_and_safety),
    _LogCategory('Servicios', Icons.electrical_services),
    _LogCategory('Inversión', Icons.trending_up),
    _LogCategory('Transferencia', Icons.swap_horiz),
    _LogCategory('Otro', Icons.more_horiz),
  ];

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
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

  void _onSave() {
    HapticFeedback.mediumImpact();
    final value = double.tryParse(_amount) ?? 0;
    if (value > 0 && _selectedCategory != null) {
      // Mock save — show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_isIncome ? "Entrada" : "Salida"} de RD\$ ${NumberFormat('#,##0').format(value)} registrada',
          ),
          backgroundColor: _isIncome ? AppColors.positive : AppColors.negative,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {
        _amount = '0';
        _selectedCategory = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.##', 'en_US');
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
                  const SizedBox(height: 16),
                  // Toggle
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
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
                                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                              ),
                              child: Center(
                                child: Text(
                                  'ENTRADA',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: _isIncome
                                        ? AppColors.positive
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
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
                                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                              ),
                              child: Center(
                                child: Text(
                                  'SALIDA',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: !_isIncome
                                        ? AppColors.negative
                                        : AppColors.textTertiary,
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
                    'RD\$',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parsedAmount > 0
                        ? formatter.format(parsedAmount)
                        : '0',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: _isIncome ? AppColors.positive : AppColors.negative,
                      fontSize: 52,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

            // ── Category Selector ──
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat.label;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat.label);
                    },
                    child: AnimatedContainer(
                      duration: AppConstants.animFast,
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (_isIncome ? AppColors.positiveDim : AppColors.negativeDim)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? (_isIncome ? AppColors.positive : AppColors.negative)
                              : AppColors.cardBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat.icon,
                            size: 22,
                            color: isSelected
                                ? (_isIncome ? AppColors.positive : AppColors.negative)
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onKeyTap(key),
                                  borderRadius: BorderRadius.circular(14),
                                  splashColor: AppColors.accent.withValues(alpha: 0.1),
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Center(
                                      child: key == 'DEL'
                                          ? const Icon(Icons.backspace_outlined,
                                              color: AppColors.textSecondary, size: 22)
                                          : Text(key, style: AppTextStyles.numpadKey),
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
                    backgroundColor: _isIncome ? AppColors.positive : AppColors.negative,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    disabledForegroundColor: AppColors.textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Registrar ${_isIncome ? "Entrada" : "Salida"}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: (parsedAmount > 0 && _selectedCategory != null)
                          ? AppColors.background
                          : AppColors.textTertiary,
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
