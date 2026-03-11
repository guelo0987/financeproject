import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';
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

  String _frecuenciaLabel(String frecuencia, int dia) {
    switch (frecuencia) {
      case 'mensual':
        return 'Mensual · día $dia';
      case 'quincenal':
        return 'Quincenal · días 1 y 15';
      case 'semanal':
        return 'Semanal · día $dia';
      default:
        return frecuencia;
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
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
    HapticFeedback.lightImpact();
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar automática'),
        content: Text('Se eliminará "${recurring.desc}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(recurringNotifierProvider.notifier).remove(recurring.id);
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringNotifierProvider);
    final selectedBudget = ref.watch(selectedBudgetProvider);

    if (recurringAsync.isLoading && recurringAsync.valueOrNull == null) {
      return const Scaffold(
        backgroundColor: AppColors.g0,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (recurringAsync.hasError && recurringAsync.valueOrNull == null) {
      return Scaffold(
        backgroundColor: AppColors.g0,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.e8),
          ),
          title: const Text(
            'Automáticas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.e8,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No se pudieron cargar las automáticas.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.e8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(recurringNotifierProvider.notifier).refresh(),
                  child: const Text('Reintentar'),
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
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.e8, size: 22),
          ),
        ),
        title: const Text(
          'Automáticas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.e8,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showRecurringSheet(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.o5,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44F97316),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                "+ Nueva",
                style: TextStyle(
                  color: Colors.white,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            if (selectedBudget != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.p5.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.layoutGrid,
                        color: AppColors.p5,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRESUPUESTO ACTIVO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.g4,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedBudget.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.e8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.03, end: 0),
            if (selectedBudget != null) const SizedBox(height: 16),
            Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.e8,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
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
                              "ENTRADAS/MES",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fmt(totalEntrada),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6EE7B7),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFF3F4F6),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SALIDAS/MES",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.g4,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fmt(totalSalida),
                              style: const TextStyle(
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
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFF3F4F6),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.repeat,
                      color: AppColors.g4,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedBudget == null
                          ? 'No hay automáticas registradas.'
                          : 'No hay automáticas para ${selectedBudget.nombre}.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.e8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Crea una para que el backend la procese automáticamente.',
                      style: TextStyle(fontSize: 12, color: AppColors.g4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            if (ingresos.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                "Ingresos recurrentes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Se aplican automáticamente",
                style: TextStyle(fontSize: 12, color: AppColors.g4),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              const Text(
                "Gastos recurrentes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Descuentos automáticos del presupuesto",
                style: TextStyle(fontSize: 12, color: AppColors.g4),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              const Text(
                "Transferencias recurrentes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Se muestran, pero esta UI todavía no las edita.",
                style: TextStyle(fontSize: 12, color: AppColors.g4),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              const Text(
                "Pausadas",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "No se aplican al presupuesto",
                style: TextStyle(fontSize: 12, color: AppColors.g4),
              ),
              const SizedBox(height: 12),
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
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  if (index > 0)
                    const Divider(
                      height: 1,
                      color: Color(0xFFF3F4F6),
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
                            size: 19,
                            color: isInactive ? AppColors.g4 : accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                      ? AppColors.g4
                                      : AppColors.e8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                frecuenciaLabel(
                                  item.frecuencia,
                                  item.diaEjecucion,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.g4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                color: isInactive ? AppColors.g4 : accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => onToggle(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: item.activo
                                      ? AppColors.e1
                                      : AppColors.g1,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.activo ? "Activa" : "Pausada",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: item.activo
                                        ? AppColors.e6
                                        : AppColors.g4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<_RecurringAction>(
                          icon: const Icon(
                            LucideIcons.moreVertical,
                            size: 18,
                            color: AppColors.g4,
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
    final budgets = ref.read(effectiveBudgetsProvider);
    final defaultWalletId = ref.read(defaultWalletIdProvider);
    final selectedBudgetId = ref.read(selectedBudgetIdProvider);

    _accountId =
        defaultWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null);
    _presupuestoId =
        selectedBudgetId ?? (budgets.isNotEmpty ? budgets.first.id : null);
  }

  @override
  void dispose() {
    _descController.dispose();
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
        } else if (_amount.length < 9) {
          _amount += key;
        }
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  String _walletName(int? id, List<WalletAccount> wallets) {
    if (id == null) return "Seleccionar";
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet.nombre;
    }
    return "Seleccionar";
  }

  String _budgetName(int? id, List<MenudoBudget> budgets) {
    if (id == null) return "Seleccionar";
    for (final budget in budgets) {
      if (budget.id == id) return budget.nombre;
    }
    return "Seleccionar";
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
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
      backgroundColor: Colors.transparent,
      builder: (_) => _SimplePickerSheet(
        title: 'Presupuesto',
        items: [
          for (final budget in budgets)
            _PickerItem(
              id: budget.id,
              label: budget.nombre,
              icon: LucideIcons.layoutGrid,
              color: AppColors.p5,
            ),
        ],
        selectedId: _presupuestoId,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _presupuestoId = selected);
    }
  }

  Future<void> _saveRecurring() async {
    if (_isSaving) return;

    final amountValue = double.tryParse(_amount);
    if (amountValue == null || amountValue == 0) return;

    if (_catKey == null || _catKey!.isEmpty) {
      _showError('Selecciona una categoria antes de continuar.');
      return;
    }
    if (_accountId == null) {
      _showError('Selecciona una cuenta antes de continuar.');
      return;
    }
    if (_presupuestoId == null) {
      _showError('Selecciona un presupuesto antes de continuar.');
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showError('La descripcion es requerida.');
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
          LucideIcons.circle,
      frecuencia: _frecuencia,
      diaEjecucion: _dia,
      activo: widget.recurring?.activo ?? true,
      nota: widget.recurring?.nota,
      accountId: _accountId,
      presupuestoId: _presupuestoId,
    );

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(recurringNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateRecurring(recurring);
      } else {
        await notifier.addRecurring(recurring);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = double.tryParse(_amount) ?? 0;
    final accentColor = _typeIndex == 1 ? AppColors.e6 : AppColors.e8;
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
          decoration: const BoxDecoration(
            color: AppColors.g0,
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
                    color: AppColors.g2,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.e8,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.g1,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          color: AppColors.g5,
                          size: 18,
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
                    color: AppColors.g1,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [_buildSeg('Gasto', 0), _buildSeg('Ingreso', 1)],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                            const SizedBox(width: 8),
                            Text(
                              _amount.isEmpty
                                  ? "0"
                                  : _amount.replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (match) => '${match[1]},',
                                    ),
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                                color: accentColor,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.g2),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: LucideIcons.tag,
                            color: AppColors.o5,
                            label: "Categoría",
                            value: selectedCategory?.nombre ?? "Seleccionar",
                            onTap: _pickCategory,
                          ),
                          _DetailRow(
                            icon: LucideIcons.landmark,
                            color: AppColors.b5,
                            label: "Cuenta",
                            value: _walletName(_accountId, wallets),
                            onTap: () => _pickWallet(wallets),
                          ),
                          _DetailRow(
                            icon: LucideIcons.layoutGrid,
                            color: AppColors.p5,
                            label: "Presupuesto",
                            value: _budgetName(_presupuestoId, budgets),
                            onTap: () => _pickBudget(budgets),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _descController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.e8,
                      ),
                      decoration: InputDecoration(
                        hintText: "Descripción (ej. Sueldo, Netflix)",
                        hintStyle: const TextStyle(
                          color: AppColors.g4,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.g2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFFF3F4F6),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.e8,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFF3F4F6),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Frecuencia",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.g4,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: ['mensual', 'quincenal', 'semanal'].map((
                              frecuencia,
                            ) {
                              final isSelected = _frecuencia == frecuencia;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _frecuencia = frecuencia);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.e8
                                          : AppColors.g1,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      frecuencia[0].toUpperCase() +
                                          frecuencia.substring(1),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.g5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_frecuencia != 'quincenal') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  _frecuencia == 'mensual'
                                      ? "Día del mes:"
                                      : "Día de semana:",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.e8,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _dia = (_dia - 1).clamp(
                                        1,
                                        _frecuencia == 'mensual' ? 28 : 7,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.g1,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      LucideIcons.minus,
                                      size: 18,
                                      color: AppColors.g5,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    "$_dia",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.e8,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _dia = (_dia + 1).clamp(
                                        1,
                                        _frecuencia == 'mensual' ? 28 : 7,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.g1,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      LucideIcons.plus,
                                      size: 18,
                                      color: AppColors.g5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 32),
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
                child: GestureDetector(
                  onTap: amountValue > 0 && !_isSaving ? _saveRecurring : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: amountValue > 0 && !_isSaving
                          ? AppColors.e8
                          : AppColors.g2,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: amountValue > 0 && !_isSaving
                          ? [
                              BoxShadow(
                                color: AppColors.e8.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isSaving
                          ? "GUARDANDO..."
                          : _isEditing
                          ? "ACTUALIZAR AUTOMÁTICA"
                          : "GUARDAR AUTOMÁTICA",
                      style: TextStyle(
                        color: amountValue > 0 && !_isSaving
                            ? Colors.white
                            : AppColors.g4,
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _setTypeIndex(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
              color: isSelected ? AppColors.e8 : AppColors.g4,
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
    return GestureDetector(
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
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.g4,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.e8,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.g3,
                  ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              color: AppColors.g1,
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
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isBack
            ? const Icon(LucideIcons.delete, color: AppColors.e8, size: 22)
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.e8,
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: AppColors.g2,
              borderRadius: BorderRadius.circular(3),
            ),
            margin: const EdgeInsets.only(bottom: 24),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 24),
          ...items.map(
            (item) => GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, item.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.id == selectedId ? AppColors.e8 : AppColors.g0,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: item.id == selectedId ? Colors.white : item.color,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: item.id == selectedId
                              ? Colors.white
                              : AppColors.e8,
                        ),
                      ),
                    ),
                    if (item.id == selectedId)
                      const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 18,
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
