import 'dart:async';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import 'package:financeproject/shared/widgets/menudo_destructive_dialog.dart';

import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/menudo_blurred_app_bar.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../shared/widgets/menudo_loading_view.dart';
import '../../../shared/widgets/menudo_toast.dart';
import '../../budgets/budget_providers.dart';
import '../../categories/presentation/category_picker_sheet.dart';
import '../../categories/providers/category_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../providers/recurring_providers.dart';

enum _RecurringAction { edit, delete }

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  String fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}";

  String _weekdayLabel(int dia) {
    const names = <int, String>{
      1: 'lunes',
      2: 'martes',
      3: 'miercoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sabado',
      7: 'domingo',
    };
    return names[dia] ?? 'dia $dia';
  }

  String _frecuenciaLabel(String frecuencia, int dia) {
    switch (frecuencia) {
      case 'mensual':
        return 'Cada mes · dia $dia';
      case 'quincenal':
        return 'Cada 15 dias';
      case 'semanal':
        return 'Cada ${_weekdayLabel(dia)}';
      default:
        return frecuencia;
    }
  }

  void _showError(BuildContext context, Object error) {
    MenudoToast.error(
      context,
      title: 'No se pudo actualizar',
      message: presentError(error),
    );
  }

  Future<void> _showRecurringSheet(
    BuildContext context, {
    RecurringTransaction? recurring,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecurringSheet(recurring: recurring),
    );
  }

  Future<void> _toggleRecurring(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction recurring,
  ) async {
    MenudoHaptics.light();
    try {
      await ref
          .read(recurringNotifierProvider.notifier)
          .toggle(recurring.id, recurring.activo);
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  Future<void> _deleteRecurring(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction recurring,
  ) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final confirm = await MenudoDestructiveDialog.show(
      context: context,
      title: 'Eliminar automática',
      message:
          'Eliminarás "${recurring.desc}" y dejará de registrarse automáticamente.',
      confirmLabel: 'Sí, eliminar',
    );

    if (confirm != true) return;

    final r = recurring;

    Future<void> restoreRecurring() async {
      try {
        await ref
            .read(recurringNotifierProvider.notifier)
            .addRecurring(
              RecurringTransaction(
                id: 0,
                desc: r.desc,
                monto: r.monto,
                tipo: r.tipo,
                frecuencia: r.frecuencia,
                diaEjecucion: r.diaEjecucion,
                catKey: r.catKey,
                accountId: r.accountId,
                presupuestoId: r.presupuestoId,
                nota: r.nota,
                icono: r.icono,
              ),
            );
        MenudoHaptics.success();
        if (rootContext.mounted) {
          MenudoToast.success(
            rootContext,
            title: 'Automática restaurada',
            message: r.desc,
          );
        }
      } catch (error) {
        if (rootContext.mounted) {
          MenudoToast.error(
            rootContext,
            title: 'No se pudo restaurar',
            message: presentError(error),
          );
        }
      }
    }

    try {
      await ref.read(recurringNotifierProvider.notifier).remove(recurring.id);
      if (!context.mounted) return;
      MenudoHaptics.success();

      MenudoToast.undo(
        rootContext,
        title: 'Automática eliminada',
        message: r.desc,
        onUndo: () {
          unawaited(restoreRecurring());
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringNotifierProvider);

    if (recurringAsync.isLoading && recurringAsync.valueOrNull == null) {
      return Scaffold(
        backgroundColor: context.menudo.background,
        body: MenudoLoadingView(
          title: 'Cargando automáticas',
          message: 'Estamos preparando tus cobros y pagos recurrentes.',
          logoSize: 88,
        ),
      );
    }

    if (recurringAsync.hasError && recurringAsync.valueOrNull == null) {
      return Scaffold(
        backgroundColor: context.menudo.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: const MenudoBlurredBar(),
          leading: MenudoIconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              MenudoCupertinoIcons.arrowLeft,
              color: context.menudo.textMain,
            ),
          ),
          title: Text(
            'Automáticas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.menudo.textMain,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No pudimos cargar tus automáticas.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.menudo.textMain,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Revisa tu conexión e inténtalo otra vez.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.menudo.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: (12)),
                FilledButton(
                  onPressed: () =>
                      ref.read(recurringNotifierProvider.notifier).refresh(),
                  child: Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = ref.watch(selectedBudgetRecurringProvider);
    final ingresos = items.where(
      (item) => item.tipo == 'ingreso' && item.activo,
    );
    final gastos = items.where((item) => item.tipo == 'gasto' && item.activo);
    final transferencias = items.where(
      (item) => item.tipo == 'transferencia' && item.activo,
    );
    final inactivos = items.where((item) => !item.activo);

    final totalEntrada = ingresos.fold(0.0, (sum, item) => sum + item.monto);
    final totalSalida = gastos.fold(0.0, (sum, item) => sum + item.monto);

    return Scaffold(
      backgroundColor: context.menudo.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const MenudoBlurredBar(),
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
          'Automáticas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: context.menudo.divider, height: 0.5),
        ),
        actions: [
          MenudoGestureDetector(
            onTap: () {
              MenudoHaptics.light();
              _showRecurringSheet(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.o5,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x44F97316),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                "+ Nueva",
                style: TextStyle(
                  color: context.menudo.textOnDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recurringNotifierProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
            16,
            100,
          ),
          children: [
            Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.menudo.hero,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33065F46),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ENTRAN",
                              style: TextStyle(
                                fontSize: 10,
                                color: context.menudo.textOnDarkSub,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              fmt(totalEntrada),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.menudo.success,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: (10)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          border: Border.all(color: context.menudo.border),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SALEN",
                              style: TextStyle(
                                fontSize: 10,
                                color: context.menudo.textMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              fmt(totalSalida),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.r5,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0, duration: 400.ms),
            if (items.isEmpty) ...[
              SizedBox(height: (28)),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.menudo.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.menudo.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      MenudoCupertinoIcons.repeat,
                      color: context.menudo.textMuted,
                      size: (28),
                    ),
                    SizedBox(height: (12)),
                    Text(
                      'Todavía no tienes automáticas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.menudo.textMain,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Cuando quieras automatizar algo, lo verás aquí.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.menudo.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            if (ingresos.isNotEmpty) ...[
              SizedBox(height: (24)),
              Text(
                "Ingresos recurrentes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
              SizedBox(height: (12)),
              _RecurringList(
                items: ingresos.toList(),
                isIngreso: true,
                frecuenciaLabel: _frecuenciaLabel,
                amountFormatter: fmt,
                onToggle: (item) => _toggleRecurring(context, ref, item),
                onEdit: (item) => _showRecurringSheet(context, recurring: item),
                onDelete: (item) => _deleteRecurring(context, ref, item),
              ),
            ],
            if (gastos.isNotEmpty) ...[
              SizedBox(height: (20)),
              Text(
                "Gastos recurrentes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
              SizedBox(height: (12)),
              _RecurringList(
                items: gastos.toList(),
                isIngreso: false,
                frecuenciaLabel: _frecuenciaLabel,
                amountFormatter: fmt,
                onToggle: (item) => _toggleRecurring(context, ref, item),
                onEdit: (item) => _showRecurringSheet(context, recurring: item),
                onDelete: (item) => _deleteRecurring(context, ref, item),
              ),
            ],
            if (transferencias.isNotEmpty) ...[
              SizedBox(height: (20)),
              Text(
                "Movimientos entre cuentas",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
              SizedBox(height: (12)),
              _RecurringList(
                items: transferencias.toList(),
                isIngreso: false,
                isTransfer: true,
                frecuenciaLabel: _frecuenciaLabel,
                amountFormatter: fmt,
                onToggle: (item) => _toggleRecurring(context, ref, item),
                onDelete: (item) => _deleteRecurring(context, ref, item),
              ),
            ],
            if (inactivos.isNotEmpty) ...[
              SizedBox(height: (20)),
              Text(
                "Pausadas",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
              SizedBox(height: (12)),
              _RecurringList(
                items: inactivos.toList(),
                isIngreso: false,
                isInactive: true,
                frecuenciaLabel: _frecuenciaLabel,
                amountFormatter: fmt,
                onToggle: (item) => _toggleRecurring(context, ref, item),
                onEdit: (item) => _showRecurringSheet(context, recurring: item),
                onDelete: (item) => _deleteRecurring(context, ref, item),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecurringList extends StatelessWidget {
  final List<RecurringTransaction> items;
  final bool isIngreso;
  final bool isInactive;
  final bool isTransfer;
  final String Function(String frecuencia, int dia) frecuenciaLabel;
  final String Function(double amount) amountFormatter;
  final Future<void> Function(RecurringTransaction item) onToggle;
  final Future<void> Function(RecurringTransaction item)? onEdit;
  final Future<void> Function(RecurringTransaction item) onDelete;

  const _RecurringList({
    required this.items,
    required this.isIngreso,
    required this.frecuenciaLabel,
    required this.amountFormatter,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.isInactive = false,
    this.isTransfer = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isTransfer
        ? AppColors.b5
        : isIngreso
        ? AppColors.e6
        : AppColors.r5;

    return Container(
          decoration: BoxDecoration(
            color: context.menudo.surface,
            border: Border.all(color: context.menudo.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: context.menudo.divider,
                      indent: 68,
                      endIndent: 16,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: isInactive ? 0.07 : 0.13,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icono,
                            size: (19),
                            color: isInactive
                                ? context.menudo.textMuted
                                : accentColor,
                          ),
                        ),
                        SizedBox(width: (12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.desc,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isInactive
                                      ? context.menudo.textMuted
                                      : context.menudo.textMain,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                frecuenciaLabel(
                                  item.frecuencia,
                                  item.diaEjecucion,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.menudo.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isIngreso
                                  ? '+'
                                  : isTransfer
                                  ? ''
                                  : '-'} ${amountFormatter(item.monto)}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isInactive
                                    ? context.menudo.textMuted
                                    : accentColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            MenudoGestureDetector(
                              onTap: () => onToggle(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: item.activo
                                      ? context.menudo.successLight
                                      : context.menudo.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.activo ? "Activa" : "Pausada",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: item.activo
                                        ? AppColors.e6
                                        : context.menudo.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<_RecurringAction>(
                          icon: Icon(
                            MenudoCupertinoIcons.moreVertical,
                            size: (18),
                            color: context.menudo.textMuted,
                          ),
                          onSelected: (action) async {
                            switch (action) {
                              case _RecurringAction.edit:
                                if (onEdit != null) {
                                  await onEdit!(item);
                                }
                              case _RecurringAction.delete:
                                await onDelete(item);
                            }
                          },
                          itemBuilder: (_) => [
                            if (onEdit != null && item.tipo != 'transferencia')
                              const PopupMenuItem(
                                value: _RecurringAction.edit,
                                child: Text('Editar'),
                              ),
                            const PopupMenuItem(
                              value: _RecurringAction.delete,
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms, delay: 150.ms)
        .slideY(begin: 0.04, end: 0, duration: 350.ms, delay: 150.ms);
  }
}

class _AddRecurringSheet extends ConsumerStatefulWidget {
  final RecurringTransaction? recurring;

  const _AddRecurringSheet({this.recurring});

  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  String _amount = "";
  int _typeIndex = 0; // 0: Gasto, 1: Ingreso
  String _frecuencia = "mensual";
  int _dia = 1;
  final _descController = TextEditingController();

  String? _catKey;
  int? _accountId;
  int? _presupuestoId;
  bool _isSaving = false;

  bool get _isEditing => widget.recurring != null;

  @override
  void initState() {
    super.initState();
    final recurring = widget.recurring;

    if (recurring != null) {
      _amount = recurring.monto.toStringAsFixed(
        recurring.monto % 1 == 0 ? 0 : 2,
      );
      _typeIndex = recurring.tipo == 'ingreso' ? 1 : 0;
      _frecuencia = recurring.frecuencia;
      _dia = recurring.diaEjecucion;
      _descController.text = recurring.desc;
      _catKey = recurring.catKey;
      _accountId = recurring.accountId;
      _presupuestoId = recurring.presupuestoId;
      return;
    }

    final wallets = ref.read(effectiveWalletsProvider);
    final defaultWalletId = ref.read(defaultWalletIdProvider);
    _accountId =
        defaultWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
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
          _amount = _amount.isEmpty ? "0." : "$_amount.";
        }
      } else {
        if (_amount == "0") {
          _amount = key;
        } else if (_amount.length < 9) {
          _amount += key;
        }
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    MenudoToast.error(context, title: 'Revisa la automática', message: message);
  }

  void _setTypeIndex(int index) {
    final categories = ref.read(effectiveCategoriesProvider);
    final selectedCategory = _catKey == null
        ? null
        : categories.where((category) => category.slug == _catKey).firstOrNull;
    final nextType = index == 1 ? 'ingreso' : 'gasto';

    setState(() {
      _typeIndex = index;
      if (selectedCategory != null && selectedCategory.tipo != nextType) {
        _catKey = null;
      }
    });
  }

  String _weekdayLabel(int dia) {
    const names = <int, String>{
      1: 'Lunes',
      2: 'Martes',
      3: 'Miercoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sabado',
      7: 'Domingo',
    };
    return names[dia] ?? 'Dia $dia';
  }

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

  String _frequencySummary() {
    switch (_frecuencia) {
      case 'mensual':
        return 'Se registrará el dia $_dia de cada mes.';
      case 'quincenal':
        return 'Se registrará cada 15 dias.';
      case 'semanal':
        return 'Se registra cada ${_weekdayLabel(_dia).toLowerCase()}.';
      default:
        return '';
    }
  }

  String _weekdayShortLabel(int dia) {
    const names = <int, String>{
      1: 'Lun',
      2: 'Mar',
      3: 'Mie',
      4: 'Jue',
      5: 'Vie',
      6: 'Sab',
      7: 'Dom',
    };
    return names[dia] ?? '$dia';
  }

  void _selectFrequency(String frecuencia) {
    MenudoHaptics.selection();
    setState(() {
      _frecuencia = frecuencia;
      if (frecuencia == 'semanal' && _dia > 7) {
        _dia = 1;
      } else if (frecuencia == 'mensual' && _dia > 28) {
        _dia = 28;
      }
    });
  }

  void _selectExecutionDay(int day) {
    MenudoHaptics.selection();
    setState(() => _dia = day);
  }

  String _walletName(int? id, List<WalletAccount> wallets) {
    if (id == null) return "Seleccionar";
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet.nombre;
    }
    return "Seleccionar";
  }

  String _budgetName(int? id, List<MenudoBudget> budgets) {
    if (id == null) return "General";
    for (final budget in budgets) {
      if (budget.id == id) return budget.nombre;
    }
    return "General";
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryPickerSheet(
        initialCatKey: _catKey,
        allowedType: _typeIndex == 1 ? 'ingreso' : 'gasto',
      ),
    );

    if (selected != null && mounted) {
      setState(() => _catKey = selected);
    }
  }

  Future<void> _pickWallet(List<WalletAccount> wallets) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimplePickerSheet(
        title: 'Cuenta',
        items: [
          for (final wallet in wallets)
            _PickerItem(
              id: wallet.id,
              label: wallet.nombre,
              icon: wallet.icono,
              color: wallet.color,
            ),
        ],
        selectedId: _accountId,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _accountId = selected);
    }
  }

  Future<void> _pickBudget(List<MenudoBudget> budgets) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimplePickerSheet(
        title: 'Presupuesto',
        items: [
          _PickerItem(
            id: 0,
            label: 'General',
            icon: MenudoCupertinoIcons.layoutGrid,
            color: context.menudo.textMuted,
          ),
          for (final budget in budgets)
            _PickerItem(
              id: budget.id,
              label: budget.nombre,
              icon: MenudoCupertinoIcons.layoutGrid,
              color: AppColors.p5,
            ),
        ],
        selectedId: _presupuestoId ?? 0,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _presupuestoId = selected <= 0 ? null : selected);
    }
  }

  Future<void> _saveRecurring() async {
    if (_isSaving) return;

    final amountValue = double.tryParse(_amount);
    if (_amount.isEmpty) {
      _showError('Escribe un monto para guardar esta automática.');
      return;
    }

    if (amountValue == null || amountValue == 0) {
      _showError('El monto debe ser mayor que cero.');
      return;
    }

    if (_catKey == null || _catKey!.isEmpty) {
      _showError('Elige una categoría para continuar.');
      return;
    }
    if (_accountId == null) {
      _showError('Elige la cuenta donde se registrará.');
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showError('Ponle un nombre para reconocerla más fácil.');
      return;
    }

    final categories = ref.read(effectiveCategoriesProvider);
    MenudoCategory? selectedCategory;
    for (final category in categories) {
      if (category.slug == _catKey) {
        selectedCategory = category;
        break;
      }
    }

    final recurring = RecurringTransaction(
      id: widget.recurring?.id ?? 0,
      desc: _descController.text.trim(),
      catKey: _catKey!,
      monto: amountValue,
      tipo: _typeIndex == 1 ? 'ingreso' : 'gasto',
      icono:
          selectedCategory?.icono ??
          widget.recurring?.icono ??
          MenudoCupertinoIcons.circle,
      frecuencia: _frecuencia,
      diaEjecucion: _dia,
      activo: widget.recurring?.activo ?? true,
      nota: widget.recurring?.nota,
      accountId: _accountId,
      presupuestoId: _presupuestoId,
    );

    final rootContext = Navigator.of(context, rootNavigator: true).context;
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(recurringNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateRecurring(recurring);
      } else {
        await notifier.addRecurring(recurring);
      }
      if (!mounted) return;
      MenudoHaptics.success();
      Navigator.pop(context);
      if (rootContext.mounted) {
        MenudoToast.success(
          rootContext,
          title: _isEditing ? 'Automática actualizada' : 'Automática creada',
          message: recurring.desc,
        );
      }
    } catch (error) {
      _showError(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = double.tryParse(_amount) ?? 0;
    final accentColor = _typeIndex == 1
        ? AppColors.e6
        : context.menudo.textMain;
    final wallets = ref.watch(effectiveWalletsProvider);
    final budgets = ref.watch(effectiveBudgetsProvider);
    final categories = ref.watch(effectiveCategoriesProvider);

    MenudoCategory? selectedCategory;
    for (final category in categories) {
      if (category.slug == _catKey) {
        selectedCategory = category;
        break;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.menudo.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: context.menudo.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? "Editar automática" : "Nueva automática",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.menudo.textMain,
                        letterSpacing: -0.5,
                      ),
                    ),
                    MenudoGestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          MenudoCupertinoIcons.x,
                          color: context.menudo.textSecondary,
                          size: (18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.menudo.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [_buildSeg('Gasto', 0), _buildSeg('Ingreso', 1)],
                  ),
                ),
              ),
              SizedBox(height: (20)),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child:
                    Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _typeIndex == 1 ? '+RD\$' : '-RD\$',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: accentColor.withValues(alpha: 0.4),
                              ),
                            ),
                            SizedBox(width: 8),
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
                                key: ValueKey('${_typeIndex}_$_amount'),
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        )
                        .animate(key: ValueKey(_typeIndex))
                        .fadeIn()
                        .scale(begin: const Offset(0.95, 0.95)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: context.menudo.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: context.menudo.border),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: MenudoCupertinoIcons.tag,
                            color: AppColors.o5,
                            label: "Categoría",
                            value: selectedCategory?.nombre ?? "Seleccionar",
                            onTap: _pickCategory,
                          ),
                          _DetailRow(
                            icon: MenudoCupertinoIcons.landmark,
                            color: AppColors.b5,
                            label: "Cuenta",
                            value: _walletName(_accountId, wallets),
                            onTap: () => _pickWallet(wallets),
                          ),
                          _DetailRow(
                            icon: MenudoCupertinoIcons.layoutGrid,
                            color: AppColors.p5,
                            label: "Presupuesto",
                            value: _budgetName(_presupuestoId, budgets),
                            onTap: () => _pickBudget(budgets),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: (20)),
                    TextField(
                      controller: _descController,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.menudo.textMain,
                      ),
                      decoration: InputDecoration(
                        hintText: "Nombre de la automática",
                        hintStyle: TextStyle(
                          color: context.menudo.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: context.menudo.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.menudo.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: context.menudo.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: context.menudo.textMain,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),
                    SizedBox(height: (16)),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.menudo.surface,
                        border: Border.all(color: context.menudo.border),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Frecuencia",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: context.menudo.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: (12)),
                          Row(
                            children:
                                [
                                  ('mensual', 'Mes'),
                                  ('quincenal', '15 dias'),
                                  ('semanal', 'Semana'),
                                ].map((item) {
                                  final frecuencia = item.$1;
                                  final label = item.$2;
                                  final isSelected = _frecuencia == frecuencia;
                                  return Expanded(
                                    child: MenudoGestureDetector(
                                      onTap: () => _selectFrequency(frecuencia),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? context.menudo.primary
                                              : context.menudo.surface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? context.menudo.surface
                                                : context.menudo.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          SizedBox(height: (14)),
                          Text(
                            _frequencySummary(),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.menudo.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: (16)),
                          if (_frecuencia == 'quincenal')
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.menudo.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.menudo.border,
                                ),
                              ),
                              child: Text(
                                'No tienes que elegir un dia. La automatica se repetira cada 15 dias.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.menudo.textMuted,
                                  height: 1.35,
                                ),
                              ),
                            )
                          else ...[
                            Text(
                              _frecuencia == 'mensual'
                                  ? 'Día del mes'
                                  : 'Día de la semana',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.menudo.textMain,
                              ),
                            ),
                            SizedBox(height: (16)),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _frecuencia == 'mensual' ? 28 : 7,
                              itemBuilder: (context, index) {
                                final i = index + 1;
                                return _RecurringDayChip(
                                  label: _frecuencia == 'mensual'
                                      ? '$i'
                                      : _weekdayShortLabel(i),
                                  selected: _dia == i,
                                  onTap: () => _selectExecutionDay(i),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: (24)),
                    GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.8,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [...'123456789.0'.split(''), 'backspace']
                          .map(
                            (key) => _NumpadKey(
                              value: key,
                              onTap: () => _onKeyTap(key),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: (32)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: MenudoGestureDetector(
                  onTap: amountValue > 0 && !_isSaving ? _saveRecurring : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: amountValue > 0 && !_isSaving
                          ? context.menudo.primary
                          : context.menudo.border,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: amountValue > 0 && !_isSaving
                          ? [
                              BoxShadow(
                                color: context.menudo.textMain.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isSaving
                          ? "Guardando automática..."
                          : _isEditing
                          ? "Guardar automática"
                          : "Crear automática",
                      style: TextStyle(
                        color: amountValue > 0 && !_isSaving
                            ? context.menudo.surface
                            : context.menudo.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
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

  Widget _buildSeg(String title, int index) {
    final isSelected = _typeIndex == index;
    return Expanded(
      child: MenudoGestureDetector(
        onTap: () {
          MenudoHaptics.selection();
          _setTypeIndex(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? context.menudo.surfaceElevated
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: context.menudo.background.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? context.menudo.primary
                  : context.menudo.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurringDayChip extends StatelessWidget {
  const _RecurringDayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? context.menudo.primary : context.menudo.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? context.menudo.primary : context.menudo.border,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected
                  ? context.menudo.surface
                  : context.menudo.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: (18), color: color),
                ),
                SizedBox(width: (14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: context.menudo.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.menudo.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    MenudoCupertinoIcons.chevronRight,
                    size: (16),
                    color: context.menudo.textMuted,
                  ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 0.5,
              color: context.menudo.surface,
              indent: 56,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _NumpadKey({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBack = value == 'backspace';
    return MenudoGestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: context.menudo.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: context.menudo.background.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isBack
            ? Icon(
                MenudoCupertinoIcons.delete,
                color: context.menudo.textMain,
                size: (22),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textMain,
                ),
              ),
      ),
    );
  }
}

class _PickerItem {
  final int id;
  final String label;
  final IconData icon;
  final Color color;

  const _PickerItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _SimplePickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;
  final int? selectedId;

  const _SimplePickerSheet({
    required this.title,
    required this.items,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: context.menudo.border,
              borderRadius: BorderRadius.circular(3),
            ),
            margin: const EdgeInsets.only(bottom: 24),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.menudo.textMain,
            ),
          ),
          SizedBox(height: (24)),
          ...items.map(
            (item) => MenudoGestureDetector(
              onTap: () {
                MenudoHaptics.light();
                Navigator.pop(context, item.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.id == selectedId
                      ? context.menudo.primary
                      : context.menudo.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: item.id == selectedId
                          ? context.menudo.surface
                          : item.color,
                    ),
                    SizedBox(width: (16)),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: item.id == selectedId
                              ? context.menudo.surface
                              : context.menudo.textMain,
                        ),
                      ),
                    ),
                    if (item.id == selectedId)
                      Icon(
                        MenudoCupertinoIcons.check,
                        color: context.menudo.surface,
                        size: (18),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
