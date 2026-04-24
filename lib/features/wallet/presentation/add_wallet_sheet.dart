import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
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
  IconData _selectedIcon = MenudoCupertinoIcons.landmark;
  String _currency = AppFormattingPreferences.currencyCode;
  bool _includeInNetWorth = true;

  bool get _isEditing => widget.initialWallet != null;

  final List<Map<String, dynamic>> _typeOptions = [
    {
      'label': 'Cuentas',
      'sub': 'Banco, ahorro o efectivo',
      'tipo': 'cuentas',
      'color': AppColors.e6,
      'defaultIcon': MenudoCupertinoIcons.landmark,
    },
    {
      'label': 'Gastos',
      'sub': 'Tarjeta o dinero de uso diario',
      'tipo': 'gastos',
      'color': AppColors.b5,
      'defaultIcon': MenudoCupertinoIcons.creditCard,
    },
    {
      'label': 'Deudas',
      'sub': 'Préstamo o saldo pendiente',
      'tipo': 'deudas',
      'color': AppColors.r5,
      'defaultIcon': MenudoCupertinoIcons.shieldAlert,
    },
  ];

  final List<IconData> _iconOptions = [
    MenudoCupertinoIcons.landmark,
    MenudoCupertinoIcons.creditCard,
    MenudoCupertinoIcons.banknote,
    MenudoCupertinoIcons.piggyBank,
    MenudoCupertinoIcons.shieldAlert,
    MenudoCupertinoIcons.building,
    MenudoCupertinoIcons.wallet,
    MenudoCupertinoIcons.coins,
  ];

  final List<Color> _colorOptions = [
    AppColors.b5,
    AppColors.e6,
    AppColors.o5,
    AppColors.p5,
    AppColors.pk,
    AppColors.a5,
    AppColors.r5,
    AppColors.o5,
  ];

  @override
  void initState() {
    super.initState();
    final initialWallet = widget.initialWallet;
    final baseCurrency =
        ref.read(authProvider).profile?.baseCurrency ??
        AppFormattingPreferences.currencyCode;
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
    MenudoHaptics.light();
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

  String _currencyPrefix() => currencyPrefix(_currency);

  String _formattedAmountDisplay() {
    if (_amount.isEmpty) return '0';
    final parts = _amount.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    if (parts.length == 1) return whole;
    return '$whole.${parts.sublist(1).join()}';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Ponle un nombre a esta cuenta.');
      return;
    }

    if ((double.tryParse(_amount) ?? 0) <= 0) {
      _showError('Escribe un monto mayor que cero.');
      return;
    }

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
    MenudoHaptics.success();
    Navigator.pop(context, wallet);
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = double.tryParse(_amount) ?? 0;
    final canSave = _nameController.text.trim().isNotEmpty && amountValue > 0;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final showCustomNumpad = keyboardBottom == 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
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
                    color: context.menudo.border,
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMain,
                      ),
                    ),
                    MenudoGestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: (32),
                        height: (32),
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          MenudoCupertinoIcons.x,
                          size: (18),
                          color: context.menudo.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: context.menudo.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: List.generate(_typeOptions.length, (index) {
                          final isSelected = _typeIndex == index;
                          final color = _typeOptions[index]['color'] as Color;
                          return Expanded(
                            child: MenudoGestureDetector(
                              onTap: () {
                                MenudoHaptics.selection();
                                setState(() => _applyTypeDefaults(index));
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.menudo.textOnDark
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
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
                                    color: isSelected
                                        ? color
                                        : context.menudo.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _typeOptions[_typeIndex]['sub'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.menudo.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: (20)),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _typeIndex == 2
                                ? 'SALDO DE DEUDA'
                                : 'SALDO INICIAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.menudo.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _typeIndex == 2
                                    ? '-${_currencyPrefix()}'
                                    : _currencyPrefix(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: context.menudo.textMuted,
                                ),
                              ),
                              SizedBox(width: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.08),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: Text(
                                  _formattedAmountDisplay(),
                                  key: ValueKey('$_typeIndex:$_amount'),
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.5,
                                    color: _typeIndex == 2
                                        ? AppColors.r5
                                        : context.menudo.textMain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: (20)),
                    Container(
                      decoration: BoxDecoration(
                        color: context.menudo.textOnDark,
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
                          Text(
                            'Nombre de la cuenta',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.menudo.textMuted,
                            ),
                          ),
                          SizedBox(height: (10)),
                          TextField(
                            controller: _nameController,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.done,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.menudo.textMain,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ej. Cuenta nómina',
                              hintStyle: TextStyle(
                                color: context.menudo.textMuted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(height: (14)),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _includeInNetWorth
                                  ? AppColors.e0
                                  : context.menudo.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _includeInNetWorth
                                    ? AppColors.e1
                                    : context.menudo.border,
                                width: 1.4,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: (38),
                                  height: (38),
                                  decoration: BoxDecoration(
                                    color: _includeInNetWorth
                                        ? AppColors.e1
                                        : context.menudo.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _includeInNetWorth
                                        ? MenudoCupertinoIcons.pie_chart_rounded
                                        : MenudoCupertinoIcons
                                              .remove_circle_outline_rounded,
                                    size: (18),
                                    color: _includeInNetWorth
                                        ? context.menudo.primary
                                        : context.menudo.textSecondary,
                                  ),
                                ),
                                SizedBox(width: (12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Incluir en patrimonio',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: context.menudo.textMain,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        _includeInNetWorth
                                            ? 'Esta cuenta contará dentro de tu patrimonio.'
                                            : 'Úsalo para tarjetas de crédito u otras cuentas que prefieras dejar aparte.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: context.menudo.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: (10)),
                                Switch.adaptive(
                                  value: _includeInNetWorth,
                                  activeThumbColor: context.menudo.textMain,
                                  activeTrackColor: context.menudo.textMain
                                      .withValues(alpha: 0.3),
                                  onChanged: (value) {
                                    MenudoHaptics.selection();
                                    setState(() => _includeInNetWorth = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: (14)),
                          Text(
                            'Icono',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.menudo.textMuted,
                            ),
                          ),
                          SizedBox(height: (10)),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _iconOptions.map((icon) {
                              final isSelected = icon == _selectedIcon;
                              return MenudoGestureDetector(
                                onTap: () {
                                  MenudoHaptics.selection();
                                  setState(() => _selectedIcon = icon);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _selectedColor.withValues(alpha: 0.15)
                                        : context.menudo.surface,
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
                                    size: (20),
                                    color: isSelected
                                        ? _selectedColor
                                        : context.menudo.textMuted,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: (14)),
                          Text(
                            'Color',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.menudo.textMuted,
                            ),
                          ),
                          SizedBox(height: (10)),
                          Wrap(
                            spacing: 10,
                            children: _colorOptions.map((color) {
                              final isSelected = color == _selectedColor;
                              return MenudoGestureDetector(
                                onTap: () {
                                  MenudoHaptics.selection();
                                  setState(() => _selectedColor = color);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: (34),
                                  height: (34),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? context.menudo.primary
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? Icon(
                                          MenudoCupertinoIcons.check,
                                          size: (16),
                                          color: context.menudo.textOnDark,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: showCustomNumpad ? 12 : 24),
                  ],
                ),
              ),
              Container(
                color: Colors.transparent,
                padding: EdgeInsets.fromLTRB(
                  24,
                  showCustomNumpad ? 12 : 0,
                  24,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showCustomNumpad) ...[
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
                      SizedBox(height: (16)),
                    ],
                    MenudoGestureDetector(
                      onTap: canSave ? _save : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: canSave ? AppColors.o5 : context.menudo.border,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: canSave
                              ? [
                                  BoxShadow(
                                    color: Color(0x44F97316),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isEditing ? 'Guardar cuenta' : 'Crear cuenta',
                          style: TextStyle(
                            color: canSave
                                ? context.menudo.textOnDark
                                : context.menudo.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKey(String value, {bool isIcon = false}) {
    return MenudoGestureDetector(
      onTapDown: (_) => _onKeyTap(value),
      child: Container(
        decoration: BoxDecoration(
          color: context.menudo.textOnDark,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isIcon
            ? Icon(
                MenudoCupertinoIcons.backspace_outlined,
                color: context.menudo.textMain,
                size: (22),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: context.menudo.textMain,
                ),
              ),
      ),
    );
  }
}
