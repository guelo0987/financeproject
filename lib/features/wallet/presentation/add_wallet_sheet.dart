import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';

class AddWalletSheet extends StatefulWidget {
  const AddWalletSheet({super.key});

  @override
  State<AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<AddWalletSheet> {
  String _amount = "";
  int _typeIndex = 0; // 0: Gastos, 1: Ahorro, 2: Deuda
  final _nameController = TextEditingController();
  Color _selectedColor = AppColors.b5;
  IconData _selectedIcon = LucideIcons.landmark;

  final List<Map<String, dynamic>> _typeOptions = [
    {
      'label': 'Gastos',
      'sub': 'Cuenta corriente o efectivo',
      'tipo': 'gasto',
      'color': AppColors.e6,
    },
    {
      'label': 'Ahorro',
      'sub': 'Ahorros, fondos, inversiones',
      'tipo': 'ahorro',
      'color': AppColors.b5,
    },
    {
      'label': 'Deuda',
      'sub': 'Tarjeta de crédito, préstamo',
      'tipo': 'deuda',
      'color': AppColors.r5,
    },
  ];

  final List<IconData> _iconOptions = [
    LucideIcons.landmark,
    LucideIcons.creditCard,
    LucideIcons.banknote,
    LucideIcons.piggyBank,
    LucideIcons.shieldAlert,
    LucideIcons.building,
    LucideIcons.wallet,
    LucideIcons.coins,
  ];

  final List<Color> _colorOptions = [
    AppColors.b5,
    AppColors.e6,
    AppColors.o5,
    AppColors.p5,
    AppColors.pk,
    AppColors.a5,
    AppColors.r5,
    AppColors.e8,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'backspace') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount = _amount.isEmpty ? "0." : "$_amount.";
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

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final tipo = _typeOptions[_typeIndex]['tipo'] as String;
    final saldo = (double.tryParse(_amount) ?? 0) * (tipo == 'deuda' ? -1 : 1);
    final w = WalletAccount(
      id: DateTime.now().millisecondsSinceEpoch,
      nombre: _nameController.text.trim(),
      tipo: tipo,
      saldo: saldo,
      color: _selectedColor,
      icono: _selectedIcon,
    );
    Navigator.pop(context, w);
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = double.tryParse(_amount) ?? 0;
    final canSave = _nameController.text.trim().isNotEmpty && amountValue > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Nueva cuenta",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.g1,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.g5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    // Type selector
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.g1,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: List.generate(_typeOptions.length, (i) {
                          final isSelected = _typeIndex == i;
                          final color = _typeOptions[i]['color'] as Color;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _typeIndex = i);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [
                                          const BoxShadow(
                                            color: Color(0x11000000),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  _typeOptions[i]['label'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? color : AppColors.g4,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _typeOptions[_typeIndex]['sub'],
                      style: const TextStyle(fontSize: 12, color: AppColors.g4),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Balance display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _typeIndex == 2
                                ? "SALDO DE DEUDA"
                                : "SALDO INICIAL",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.g4,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _typeIndex == 2 ? '-RD\$' : 'RD\$',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.g3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _amount.isEmpty ? "0" : _amount,
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5,
                                  color: _typeIndex == 2
                                      ? AppColors.r5
                                      : AppColors.e8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFF3F4F6),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Nombre de la cuenta",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.g4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.e8,
                            ),
                            decoration: InputDecoration(
                              hintText: "Ej. BHD León Nómina",
                              hintStyle: const TextStyle(color: AppColors.g3),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Icono",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.g4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _iconOptions.map((icon) {
                              final isSel = icon == _selectedIcon;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedIcon = icon);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? _selectedColor.withValues(alpha: 0.15)
                                        : AppColors.g1,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel
                                          ? _selectedColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    icon,
                                    size: 20,
                                    color: isSel
                                        ? _selectedColor
                                        : AppColors.g4,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Color",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.g4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: _colorOptions.map((color) {
                              final isSel = color == _selectedColor;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedColor = color);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSel
                                          ? AppColors.e8
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSel
                                      ? const Icon(
                                          LucideIcons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Numpad
                    GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2.1,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildKey('1'),
                        _buildKey('2'),
                        _buildKey('3'),
                        _buildKey('4'),
                        _buildKey('5'),
                        _buildKey('6'),
                        _buildKey('7'),
                        _buildKey('8'),
                        _buildKey('9'),
                        _buildKey('.'),
                        _buildKey('0'),
                        _buildKey('backspace', isIcon: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              Container(
                color: Colors.transparent,
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: GestureDetector(
                  onTap: canSave ? _save : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: canSave ? AppColors.o5 : AppColors.g2,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: canSave
                          ? [
                              const BoxShadow(
                                color: Color(0x44F97316),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Agregar cuenta",
                      style: TextStyle(
                        color: canSave ? Colors.white : AppColors.g4,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKey(String value, {bool isIcon = false}) {
    return GestureDetector(
      onTapDown: (_) => _onKeyTap(value),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isIcon
            ? const Icon(
                Icons.backspace_outlined,
                color: AppColors.e8,
                size: 22,
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.e8,
                ),
              ),
      ),
    );
  }
}
