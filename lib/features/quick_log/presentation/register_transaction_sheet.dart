import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_chip.dart';

class RegisterTransactionSheet extends StatefulWidget {
  const RegisterTransactionSheet({super.key});

  @override
  State<RegisterTransactionSheet> createState() => _RegisterTransactionSheetState();
}

class _RegisterTransactionSheetState extends State<RegisterTransactionSheet> {
  String _amount = "0";
  int _selectedTypeIndex = 0; // 0: Gasto, 1: Ingresos, 2: Transferencia

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'backspace') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = "0";
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == "0") {
          _amount = key;
        } else if (_amount.length < 10) {
          _amount += key;
        }
      }
    });
  }

  void _saveTransaction() {
    if (double.parse(_amount) == 0) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    // show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transacción registrada'),
        backgroundColor: MenudoColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(_amount) ?? 0;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: MenudoColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Text('Nueva transacción', style: MenudoTextStyles.h3),
                    IconButton(
                      icon: const Icon(Icons.close, color: MenudoColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Amount Display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('RD\$', style: TextStyle(fontSize: 22, color: MenudoColors.textMuted, fontWeight: FontWeight.w500)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Text(
                        _amount.isEmpty ? "0" : _amount.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                        key: ValueKey<String>(_amount),
                        style: MenudoTextStyles.heroAmount.copyWith(
                          color: MenudoColors.textMain,
                          fontSize: 52,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Type Selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: Row(
                  children: [
                    _buildSegment('GASTO', 0),
                    _buildSegment('INGRESOS', 1),
                    _buildSegment('TRANSFER', 2),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Details List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDetailRow(
                      Icons.fastfood, 'Categoría', 'Comidas', 
                      iconBgColor: MenudoColors.primaryLight,
                      iconColor: MenudoColors.primary,
                      aiSuggested: false,
                    ),
                    const Divider(height: 1, color: MenudoColors.divider),
                    _buildDetailRow(
                      Icons.account_balance_wallet, 'Desde', 'BHD León',
                      iconBgColor: MenudoColors.successLight,
                      iconColor: MenudoColors.success,
                    ),
                    const Divider(height: 1, color: MenudoColors.divider),
                    _buildTextInputRow(),
                    const Divider(height: 1, color: MenudoColors.divider),
                    _buildDetailRow(
                      Icons.calendar_today, 'Fecha', 'Hoy',
                      iconBgColor: MenudoColors.border,
                      iconColor: MenudoColors.textSecondary,
                    ),
                    const Divider(height: 1, color: MenudoColors.divider),
                    _buildDetailRow(
                      Icons.repeat, 'Repetir', 'No repetir',
                      iconBgColor: MenudoColors.border,
                      iconColor: MenudoColors.textSecondary,
                    ),
                    const Divider(height: 1, color: MenudoColors.divider),
                    _buildDetailRow(
                      Icons.people_alt, 'Espacio', 'Personal',
                      iconBgColor: MenudoColors.border,
                      iconColor: MenudoColors.textSecondary,
                    ),
                  ],
                ),
              ),
              
              // Keypad
              Container(
                height: 260,
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildKey('1'), _buildKey('2'), _buildKey('3'),
                    _buildKey('4'), _buildKey('5'), _buildKey('6'),
                    _buildKey('7'), _buildKey('8'), _buildKey('9'),
                    _buildKey('.'), _buildKey('0'), _buildKey('backspace', isIcon: true),
                  ],
                ),
              ),
              
              // Save Button
              Container(
                color: const Color(0xFFF9FAFB),
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: MenudoPrimaryButton(
                  label: "GUARDAR",
                  isDisabled: amountValue == 0,
                  onTap: _saveTransaction,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment(String title, int index) {
    final isSelected = _selectedTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTypeIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? MenudoColors.cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : MenudoColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {required Color iconBgColor, required Color iconColor, bool aiSuggested = false}) {
    return InkWell(
      onTap: () {}, // Pick logic goes here
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: MenudoTextStyles.bodySmall.copyWith(color: MenudoColors.textMuted)),
                  Row(
                    children: [
                      Text(value, style: MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      if (aiSuggested) ...[
                        const SizedBox(width: 8),
                        const MenudoChip('IA', variant: MenudoChipVariant.primary, isSmall: true),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: MenudoColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MenudoColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit, size: 20, color: MenudoColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción', style: MenudoTextStyles.bodySmall.copyWith(color: MenudoColors.textMuted)),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Nota (opcional)',
                    hintStyle: TextStyle(color: MenudoColors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value, {bool isIcon = false}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: MenudoColors.border),
      ),
      child: InkWell(
        onTap: () => _onKeyTap(value),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: isIcon
            ? const Icon(Icons.backspace_outlined, color: MenudoColors.textMuted)
            : Text(value, style: MenudoTextStyles.h2.copyWith(color: MenudoColors.textMain)),
        ),
      ),
    );
  }
}
