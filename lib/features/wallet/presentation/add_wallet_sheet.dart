import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/menudo_toast.dart';
import '../../auth/auth_state.dart';

class AddWalletSheet extends ConsumerStatefulWidget {
  final WalletAccount? initialWallet;

  const AddWalletSheet({super.key, this.initialWallet});

  @override
  ConsumerState<AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends ConsumerState<AddWalletSheet> {
  final _amountController = TextEditingController();
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
    MenudoCupertinoIcons.pieChart,
    MenudoCupertinoIcons.shieldAlert,
    MenudoCupertinoIcons.briefcase,
    MenudoCupertinoIcons.home,
    MenudoCupertinoIcons.tag,
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
    final baseCurrency =
        ref.read(authProvider).profile?.baseCurrency ??
        AppFormattingPreferences.currencyCode;
    final initialCurrency = initialWallet?.moneda.trim();
    final normalizedBaseCurrency = baseCurrency.trim().toUpperCase();
    final normalizedInitialCurrency = initialCurrency?.toUpperCase();
    _currency = initialCurrency == null || initialCurrency.isEmpty
        ? normalizedBaseCurrency
        : normalizedInitialCurrency == 'DOP' && normalizedBaseCurrency != 'DOP'
        ? normalizedBaseCurrency
        : normalizedInitialCurrency!;
    _includeInNetWorth = initialWallet?.incluirEnPatrimonio ?? true;

    if (initialWallet == null) {
      _applyTypeDefaults(0, force: true);
      return;
    }

    _nameController.text = initialWallet.nombre;
    _amountController.text = formatMoneyInputValue(
      initialWallet.saldo.abs(),
      currency: _currency,
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
    _amountController.dispose();
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

  String _currencyPrefix() => currencyPrefix(_currency);

  void _showError(String message) {
    if (!mounted) return;
    MenudoToast.error(context, title: 'Revisa la cuenta', message: message);
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Ponle un nombre a esta cuenta.');
      return;
    }

    final amount = parseMoneyInput(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showError('Escribe un monto mayor que cero.');
      return;
    }

    final tipo = _typeOptions[_typeIndex]['tipo'] as String;
    final saldo = amount * (tipo == 'deudas' ? -1 : 1);
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
    final amountValue = parseMoneyInput(_amountController.text) ?? 0;
    final canSave = _nameController.text.trim().isNotEmpty && amountValue > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.menudo.background,
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
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
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
                                      ? context.menudo.surfaceElevated
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: context.menudo.background
                                                .withValues(alpha: 0.1),
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
                          IntrinsicWidth(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: const [
                                ThousandsNumberInputFormatter(),
                              ],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                                color: _typeIndex == 2
                                    ? AppColors.r5
                                    : context.menudo.textMain,
                              ),
                              decoration: InputDecoration(
                                prefixText: _currencyPrefix(),
                                prefixStyle: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: context.menudo.textMuted,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: context.menudo.textMuted.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              onTapOutside: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: (20)),
                    Column(
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
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(height: (24)),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _includeInNetWorth
                                ? context.menudo.successLight
                                : context.menudo.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _includeInNetWorth
                                  ? context.menudo.successLight
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
                                      ? context.menudo.successLight
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        SizedBox(height: (24)),
                        Text(
                          'Icono',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.menudo.textMuted,
                          ),
                        ),
                        SizedBox(height: (10)),
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _iconOptions.length,
                            separatorBuilder: (_, _) => SizedBox(width: (8)),
                            itemBuilder: (context, index) {
                              final icon = _iconOptions[index];
                              final isSelected = icon == _selectedIcon;
                              return MenudoGestureDetector(
                                onTap: () {
                                  MenudoHaptics.selection();
                                  setState(() => _selectedIcon = icon);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _selectedColor.withValues(alpha: 0.15)
                                        : context.menudo.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? _selectedColor
                                          : context.menudo.border,
                                      width: isSelected ? 2 : 1,
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
                            },
                          ),
                        ),
                        SizedBox(height: (24)),
                        Text(
                          'Color',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.menudo.textMuted,
                          ),
                        ),
                        SizedBox(height: (10)),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _colorOptions.length,
                            separatorBuilder: (_, _) => SizedBox(width: (10)),
                            itemBuilder: (context, index) {
                              final color = _colorOptions[index];
                              final isSelected = color == _selectedColor;
                              return MenudoGestureDetector(
                                onTap: () {
                                  MenudoHaptics.selection();
                                  setState(() => _selectedColor = color);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? context.menudo.primary
                                          : context.menudo.border,
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? Icon(
                                          MenudoCupertinoIcons.check,
                                          size: (16),
                                          color: context.menudo.surface,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  (MediaQuery.viewInsetsOf(context).bottom > 0
                          ? MediaQuery.viewInsetsOf(context).bottom
                          : MediaQuery.paddingOf(context).bottom) +
                      16,
                ),
                child: MenudoGestureDetector(
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
                            ? context.menudo.surface
                            : context.menudo.textMuted,
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
}
