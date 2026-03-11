import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_state.dart';

class AddWalletSheet extends ConsumerStatefulWidget {
  final WalletAccount? initialWallet;

  const AddWalletSheet({super.key, this.initialWallet});

  @override
  ConsumerState<AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends ConsumerState<AddWalletSheet> {
  String _amount = '';
  int _typeIndex = 0; // 0: Cuentas, 1: Gastos, 2: Deudas
  final _nameController = TextEditingController();
  Color _selectedColor = AppColors.e6;
  IconData _selectedIcon = LucideIcons.landmark;
  String _currency = 'DOP';
  bool _includeInNetWorth = true;

  bool get _isEditing => widget.initialWallet != null;

  final List<Map<String, dynamic>> _typeOptions = [
    {
      'label': 'Cuentas',
      'sub': 'Cuenta bancaria o cuenta de ahorros',
      'tipo': 'cuentas',
      'color': AppColors.e6,
      'defaultIcon': LucideIcons.landmark,
    },
    {
      'label': 'Gastos',
      'sub': 'Tarjeta de crédito, efectivo o fondos de uso diario',
      'tipo': 'gastos',
      'color': AppColors.b5,
      'defaultIcon': LucideIcons.creditCard,
    },
    {
      'label': 'Deudas',
      'sub': 'Préstamo, hipoteca o deuda pendiente',
      'tipo': 'deudas',
      'color': AppColors.r5,
      'defaultIcon': LucideIcons.shieldAlert,
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
  void initState() {
    super.initState();
    final initialWallet = widget.initialWallet;
    final baseCurrency = ref.read(authProvider).profile?.baseCurrency ?? 'DOP';
    _currency = initialWallet?.moneda ?? baseCurrency;
    _includeInNetWorth = initialWallet?.incluirEnPatrimonio ?? true;

    if (initialWallet == null) {
      _applyTypeDefaults(0, force: true);
      return;
    }

    _nameController.text = initialWallet.nombre;
    _amount = initialWallet.saldo.abs().toStringAsFixed(
      initialWallet.saldo.abs() % 1 == 0 ? 0 : 2,
    );
    _selectedColor = initialWallet.color;
    _selectedIcon = initialWallet.icono;
    _typeIndex = switch (initialWallet.tipo) {
      'gastos' => 1,
      'deudas' => 2,
      _ => 0,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyTypeDefaults(int index, {bool force = false}) {
    final option = _typeOptions[index];
    _typeIndex = index;
    if (force || !_isEditing) {
      _selectedColor = option['color'] as Color;
      _selectedIcon = option['defaultIcon'] as IconData;
    }
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
          _amount = _amount.isEmpty ? '0.' : '$_amount.';
        }
      } else {
        if (_amount == '0') {
          _amount = key;
        } else if (_amount.length < 10) {
          _amount += key;
        }
      }
    });
  }

  String _currencyPrefix() => _currency == 'USD' ? 'US\$' : 'RD\$';

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final tipo = _typeOptions[_typeIndex]['tipo'] as String;
    final saldo = (double.tryParse(_amount) ?? 0) * (tipo == 'deudas' ? -1 : 1);
    final wallet = WalletAccount(
      id: widget.initialWallet?.id ?? DateTime.now().millisecondsSinceEpoch,
      nombre: _nameController.text.trim(),
      tipo: tipo,
      saldo: saldo,
      color: _selectedColor,
      icono: _selectedIcon,
      moneda: _currency,
      incluirEnPatrimonio: _includeInNetWorth,
    );
    Navigator.pop(context, wallet);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
                      style: const TextStyle(
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
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.g1,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: List.generate(_typeOptions.length, (index) {
                          final isSelected = _typeIndex == index;
                          final color = _typeOptions[index]['color'] as Color;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _applyTypeDefaults(index));
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
                                  _typeOptions[index]['label'] as String,
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
                      _typeOptions[_typeIndex]['sub'] as String,
                      style: const TextStyle(fontSize: 12, color: AppColors.g4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _typeIndex == 2
                                ? 'SALDO DE DEUDA'
                                : 'SALDO INICIAL',
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
                                _typeIndex == 2
                                    ? '-${_currencyPrefix()}'
                                    : _currencyPrefix(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.g3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _amount.isEmpty ? '0' : _amount,
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
                            'Nombre de la cuenta',
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
                            decoration: const InputDecoration(
                              hintText: 'Ej. BHD León Nómina',
                              hintStyle: TextStyle(color: AppColors.g3),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Moneda',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.g4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (final currency in const ['DOP', 'USD'])
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: currency == 'DOP' ? 8 : 0,
                                      left: currency == 'USD' ? 8 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _currency = currency);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _currency == currency
                                              ? _selectedColor.withValues(
                                                  alpha: 0.12,
                                                )
                                              : AppColors.g0,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _currency == currency
                                                ? _selectedColor
                                                : AppColors.g2,
                                            width: _currency == currency
                                                ? 1.8
                                                : 1.2,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          currency == 'USD' ? 'US\$' : 'RD\$',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: _currency == currency
                                                ? _selectedColor
                                                : AppColors.g5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _includeInNetWorth
                                  ? AppColors.e0
                                  : AppColors.g0,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _includeInNetWorth
                                    ? AppColors.e1
                                    : AppColors.g2,
                                width: 1.4,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _includeInNetWorth
                                        ? AppColors.e1
                                        : AppColors.g1,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _includeInNetWorth
                                        ? Icons.pie_chart_rounded
                                        : Icons.remove_circle_outline_rounded,
                                    size: 18,
                                    color: _includeInNetWorth
                                        ? AppColors.e8
                                        : AppColors.g5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Incluir en patrimonio',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.e8,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _includeInNetWorth
                                            ? 'Esta wallet contará en la tarjeta de patrimonio neto.'
                                            : 'Úsalo para tarjetas de crédito u otras wallets que no quieras sumar al patrimonio.',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.g5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Switch.adaptive(
                                  value: _includeInNetWorth,
                                  activeThumbColor: AppColors.e8,
                                  activeTrackColor: AppColors.e8.withValues(
                                    alpha: 0.3,
                                  ),
                                  onChanged: (value) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _includeInNetWorth = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Icono',
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
                              final isSelected = icon == _selectedIcon;
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
                                    color: isSelected
                                        ? _selectedColor.withValues(alpha: 0.15)
                                        : AppColors.g1,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? _selectedColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    icon,
                                    size: 20,
                                    color: isSelected
                                        ? _selectedColor
                                        : AppColors.g4,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Color',
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
                              final isSelected = color == _selectedColor;
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
                                      color: isSelected
                                          ? AppColors.e8
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
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
                          : const [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isEditing ? 'Guardar cambios' : 'Agregar cuenta',
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
