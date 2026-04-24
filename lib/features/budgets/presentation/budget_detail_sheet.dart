import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/menudo_loading_view.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../../auth/auth_state.dart';
import '../budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../transactions/presentation/transaction_presentation_utils.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../../utils/storage_keys.dart';
import 'wizard/create_budget_wizard.dart';
import '../../quick_log/presentation/register_transaction_sheet.dart';

class BudgetDetailSheet extends ConsumerStatefulWidget {
  final MenudoBudget budget;

  const BudgetDetailSheet({super.key, required this.budget});

  @override
  ConsumerState<BudgetDetailSheet> createState() => _BudgetDetailSheetState();
}

class _BudgetDetailSheetState extends ConsumerState<BudgetDetailSheet> {
  String _tab = "resumen"; // plan, resumen, insights
  List<BudgetMember> _members = [];
  bool _isLoadingMembers = false;
  String? _membersError;
  List<BudgetHistorySnapshot> _history = [];
  bool _isLoadingHistory = false;
  bool _isLoadingMoreHistory = false;
  bool _historyLoaded = false;
  bool _historyHasMore = false;
  int _historyPage = 0;
  String? _historyError;
  double _dismissDragOffset = 0;

  String _fmt(double val) => formatMoney(val);

  bool get _shouldLoadMembers {
    return widget.budget.espacioId != null || widget.budget.miembros.isNotEmpty;
  }

  bool get _supportsHistory {
    return widget.budget.periodo != 'unico';
  }

  MenudoBudget _currentBudget() {
    for (final budget in ref.read(effectiveBudgetsProvider)) {
      if (budget.id == widget.budget.id) {
        return budget;
      }
    }
    return widget.budget;
  }

  bool _isCurrentUserOwner(MenudoBudget budget, int? currentUserId) {
    if (currentUserId == null) return false;
    if (budget.ownerUserId != null && budget.ownerUserId == currentUserId) {
      return true;
    }

    final members = _members.isNotEmpty ? _members : budget.miembros;
    return members.any(
      (member) => member.userId == currentUserId && member.isOwner,
    );
  }

  @override
  void initState() {
    super.initState();
    _members = widget.budget.miembros;
    _loadMembers();
  }

  @override
  void didUpdateWidget(covariant BudgetDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budget.id != widget.budget.id ||
        oldWidget.budget.espacioId != widget.budget.espacioId) {
      _members = widget.budget.miembros;
      _resetHistoryState();
      _loadMembers();
      if (_tab == 'insights') {
        _ensureHistoryLoaded();
      }
    }
  }

  Future<void> _openBudgetEditor() async {
    MenudoHaptics.light();
    final navigator = Navigator.of(context);
    MenudoBudget latestBudget = widget.budget;
    for (final budget in ref.read(effectiveBudgetsProvider)) {
      if (budget.id == widget.budget.id) {
        latestBudget = budget;
        break;
      }
    }
    final updated = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CreateBudgetWizard(initialBudget: latestBudget, initialStep: 2),
    );
    if (updated == true && mounted) {
      navigator.pop();
    }
  }

  Future<void> _deleteBudget() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final safeBottom = MediaQuery.of(sheetContext).padding.bottom;
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: context.menudo.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + safeBottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.menudo.textMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: (18)),
                Center(
                  child: Text(
                    'Eliminar presupuesto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: context.menudo.textMain,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Esto borrará ${widget.budget.nombre} y todo lo relacionado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: context.menudo.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: (16)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.o1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.o5.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Se eliminará',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: context.menudo.textMain,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Movimientos del presupuesto\n• Historial del presupuesto\n• Plan de ingresos\n• Límites por categoría\n• Espacio compartido e invitaciones',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: context.menudo.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: (18)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: (12)),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.r5,
                          foregroundColor: context.menudo.textOnDark,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: Text('Sí, eliminar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(budgetControllerProvider.notifier)
          .deleteBudget(widget.budget.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(presentError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _leaveBudget() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final safeBottom = MediaQuery.of(sheetContext).padding.bottom;
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: context.menudo.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + safeBottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.menudo.textMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: (18)),
                Text(
                  'Salir del presupuesto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: context.menudo.textMain,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Se quitará de tu lista, pero seguirá intacto para quien lo creó y para el resto del equipo.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: context.menudo.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: (14)),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.menudo.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.menudo.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: (34),
                        height: (34),
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          MenudoCupertinoIcons.users,
                          size: (15),
                          color: context.menudo.textMain,
                        ),
                      ),
                      SizedBox(width: (12)),
                      Expanded(
                        child: Text(
                          _currentBudget().nombre,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.menudo.textMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: (18)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: Text('Quedarme'),
                      ),
                    ),
                    SizedBox(width: (12)),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: context.menudo.primary,
                          foregroundColor: context.menudo.textOnDark,
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: Text('Salir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(budgetControllerProvider.notifier)
          .leaveBudget(widget.budget.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(presentError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openBudgetActions() async {
    MenudoHaptics.light();
    final currentBudget = _currentBudget();
    final currentUserId = int.tryParse(ref.read(authProvider).userId ?? '');
    final isOwner = _isCurrentUserOwner(currentBudget, currentUserId);
    final members = _members.isNotEmpty ? _members : currentBudget.miembros;
    final isMember = members.any((member) => member.userId == currentUserId);
    final canLeave = !isOwner && (currentBudget.espacioId != null || isMember);
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: context.menudo.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.menudo.textMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: (20)),
                _BudgetActionOption(
                  icon: MenudoCupertinoIcons.pencil,
                  label: 'Editar presupuesto',
                  onTap: () => Navigator.pop(sheetContext, 'edit'),
                ),
                if (isOwner) ...[
                  SizedBox(height: (10)),
                  _BudgetActionOption(
                    icon: MenudoCupertinoIcons.trash2,
                    label: 'Eliminar presupuesto',
                    color: AppColors.r5,
                    onTap: () => Navigator.pop(sheetContext, 'delete'),
                  ),
                ] else if (canLeave) ...[
                  SizedBox(height: (10)),
                  _BudgetActionOption(
                    icon: MenudoCupertinoIcons.logOut,
                    label: 'Salir del presupuesto',
                    color: AppColors.o5,
                    onTap: () => Navigator.pop(sheetContext, 'leave'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'edit') {
      await _openBudgetEditor();
    } else if (action == 'delete') {
      await _deleteBudget();
    } else if (action == 'leave') {
      await _leaveBudget();
    }
  }

  Future<void> _loadMembers() async {
    if (!_shouldLoadMembers) {
      if (mounted) {
        setState(() => _membersError = null);
      }
      return;
    }

    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
    });

    try {
      final members = await ref
          .read(budgetControllerProvider.notifier)
          .fetchBudgetMembers(widget.budget.id);
      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _membersError = presentError(error);
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _openMembersManager() async {
    MenudoHaptics.light();
    final updatedMembers = await showModalBottomSheet<List<BudgetMember>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetMembersSheet(
        budgetId: widget.budget.id,
        initialMembers: _members,
        allowInviteWhenEmpty: widget.budget.espacioId == null,
      ),
    );

    if (!mounted) return;
    if (updatedMembers != null) {
      setState(() {
        _members = updatedMembers;
        _membersError = null;
      });
    } else {
      await _loadMembers();
    }
  }

  void _resetHistoryState() {
    _history = [];
    _isLoadingHistory = false;
    _isLoadingMoreHistory = false;
    _historyLoaded = false;
    _historyHasMore = false;
    _historyPage = 0;
    _historyError = null;
  }

  void _ensureHistoryLoaded() {
    if (!_supportsHistory || _historyLoaded || _isLoadingHistory) return;
    _loadHistory();
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (!_supportsHistory) return;
    if (loadMore) {
      if (_isLoadingMoreHistory || !_historyHasMore) return;
    } else if (_isLoadingHistory) {
      return;
    }

    final nextPage = loadMore ? _historyPage + 1 : 1;

    setState(() {
      if (loadMore) {
        _isLoadingMoreHistory = true;
      } else {
        _isLoadingHistory = true;
        _historyError = null;
      }
    });

    try {
      final result = await ref
          .read(budgetControllerProvider.notifier)
          .fetchBudgetHistory(widget.budget.id, page: nextPage, limit: 12);
      if (!mounted) return;
      setState(() {
        _history = loadMore ? [..._history, ...result.items] : result.items;
        _historyPage = result.page;
        _historyHasMore = result.hasMore;
        _historyLoaded = true;
        _historyError = null;
        _isLoadingHistory = false;
        _isLoadingMoreHistory = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _historyError = presentError(error);
        _historyLoaded = true;
        _isLoadingHistory = false;
        _isLoadingMoreHistory = false;
      });
    }
  }

  void _onTabChanged(String value) {
    MenudoHaptics.selection();
    setState(() => _tab = value);
    if (value == 'insights') {
      _ensureHistoryLoaded();
    }
  }

  void _onDismissDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      _dismissDragOffset += details.delta.dy;
    }
  }

  void _onDismissDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldClose = _dismissDragOffset > 56 || velocity > 700;
    _dismissDragOffset = 0;
    if (shouldClose && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  String _fmtAmount(double value, {String currency = '', bool signed = false}) {
    return formatMoney(value, currency: currency, signed: signed);
  }

  String _historyRangeLabel(BudgetHistorySnapshot snapshot) {
    final from = snapshot.desde;
    final to = snapshot.hasta;
    if (from == null || to == null) return 'Período anterior';
    return '${_historyDateLabel(from)} - ${_historyDateLabel(to)}';
  }

  String _historyDateLabel(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _historyEmptyMessage(String periodo) {
    switch (periodo) {
      case 'semanal':
        return 'Todavía no hay semanas cerradas para mostrar. Cuando termine la primera, aparecerá aquí.';
      case 'quincenal':
        return 'Todavía no hay quincenas cerradas para mostrar. Aquí aparecerán cuando se complete la primera.';
      default:
        return 'Todavía no hay períodos cerrados para mostrar. Cuando cierre el primero, lo verás aquí.';
    }
  }

  List<MenudoTransaction> _transactionsForBudgetPeriod(
    MenudoBudget budget,
    List<MenudoTransaction> transactions,
    DateTime referenceDate,
  ) {
    final scoped = transactions
        .where((transaction) => transaction.budgetId == budget.id)
        .toList();
    final range = budgetRangeFor(budget, referenceDate: referenceDate);
    if (range == null) return scoped;

    return scoped.where((transaction) {
      final date = DateTime.tryParse(transaction.dateString);
      if (date == null) return false;
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList();
  }

  MenudoCategory? _resolveTransactionCategory(
    MenudoTransaction transaction,
    List<MenudoCategory> categories,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final categoryId = transaction.categoryId;
    if (categoryId != null) {
      return categoriesById[categoryId];
    }

    final slug = transaction.catKey.trim();
    if (slug.isEmpty) return null;

    for (final category in categories) {
      if (category.slug == slug) return category;
    }

    return null;
  }

  List<_BudgetExpenseBreakdownItem> _expenseBreakdownForBudget(
    List<MenudoTransaction> transactions,
    List<MenudoCategory> categories,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final grouped = <String, _BudgetExpenseBreakdownSeed>{};

    for (final transaction in transactions) {
      if (transaction.tipo != 'gasto') continue;

      final resolvedCategory = _resolveTransactionCategory(
        transaction,
        categories,
        categoriesById,
      );
      final key = resolvedCategory?.id.toString() ?? transaction.catKey;
      final parentLabel = resolvedCategory?.categoriaParadreId != null
          ? categoriesById[resolvedCategory!.categoriaParadreId!]?.nombre ?? ''
          : '';

      final seed =
          grouped[key] ??
          _BudgetExpenseBreakdownSeed(
            label: resolvedCategory?.nombre ?? 'Sin categoría',
            parentLabel: parentLabel,
            icon: resolvedCategory?.icono ?? transaction.icono,
            color: resolvedCategory?.color ?? context.menudo.textMuted,
          );

      seed.total += transaction.monto.abs();
      seed.count += 1;
      grouped[key] = seed;
    }

    final items =
        grouped.values
            .map(
              (seed) => _BudgetExpenseBreakdownItem(
                label: seed.label,
                parentLabel: seed.parentLabel,
                icon: seed.icon,
                color: seed.color,
                total: seed.total,
                count: seed.count,
              ),
            )
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));

    return items;
  }

  Widget _buildTransactionsByCategorySection(
    List<_BudgetExpenseBreakdownItem> items,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 18),
        child: _InlineInfoCard(
          text:
              'Cuando registres gastos en este presupuesto, aquí verás cuáles categorías se están llevando más dinero.',
        ),
      );
    }

    final visibleItems = items.take(6).toList();
    final totalSpent = items.fold(0.0, (sum, item) => sum + item.total);
    final totalMovements = items.fold(0, (sum, item) => sum + item.count);

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: (36),
                height: (36),
                decoration: BoxDecoration(
                  color: AppColors.o5.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  MenudoCupertinoIcons.pieChart,
                  size: (16),
                  color: AppColors.o5,
                ),
              ),
              SizedBox(width: (12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gasto por categoría',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMain,
                      ),
                    ),
                    Text(
                      '$totalMovements movimiento${totalMovements == 1 ? '' : 's'} en el ciclo actual',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.menudo.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _fmt(totalSpent),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.o5,
                ),
              ),
            ],
          ),
          SizedBox(height: (16)),
          ...visibleItems.asMap().entries.map((entry) {
            final item = entry.value;
            final share = totalSpent <= 0 ? 0.0 : item.total / totalSpent;
            final subtitle = _joinDistinctSecondaryLabels([
              _distinctSecondaryLabel(item.parentLabel, against: item.label),
              '${item.count} mov.',
            ]);

            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == visibleItems.length - 1 ? 0 : 14,
              ),
              child: _BudgetExpenseBreakdownRow(
                item: item,
                share: share,
                subtitle: subtitle,
                amountLabel: _fmt(item.total),
              ),
            );
          }),
          if (items.length > visibleItems.length) ...[
            SizedBox(height: (12)),
            Text(
              '+${items.length - visibleItems.length} categoría${items.length - visibleItems.length == 1 ? '' : 's'} más',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.menudo.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomeByCategorySection(
    List<BudgetIncomeSource> sources,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final visibleSources =
        sources
            .where((source) => source.actual > 0 || source.planned > 0)
            .toList()
          ..sort((a, b) => b.actual.compareTo(a.actual));

    if (visibleSources.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 18),
        child: _InlineInfoCard(
          text:
              'Cuando registres ingresos en este presupuesto, aquí verás de dónde está entrando el dinero.',
        ),
      );
    }

    final totalActual = visibleSources.fold<double>(
      0,
      (sum, source) => sum + source.actual,
    );

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: (36),
                height: (36),
                decoration: BoxDecoration(
                  color: AppColors.e6.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  MenudoCupertinoIcons.trendingUp,
                  size: (16),
                  color: AppColors.e6,
                ),
              ),
              SizedBox(width: (12)),
              Expanded(
                child: Text(
                  'Ingresos por categoría',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.menudo.textMain,
                  ),
                ),
              ),
              Text(
                _fmt(totalActual),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e6,
                ),
              ),
            ],
          ),
          SizedBox(height: (16)),
          ...visibleSources.take(6).toList().asMap().entries.map((entry) {
            final source = entry.value;
            final visibleCount = min(visibleSources.length, 6);
            final parentLabel = _distinctSecondaryLabel(
              _parentLabelForIncome(source, categoriesById),
              against: source.label,
            );
            final subtitle = _joinDistinctSecondaryLabels([
              parentLabel,
              source.planned > 0 ? 'Plan ${_fmt(source.planned)}' : 'Sin plan',
            ]);
            final share = totalActual <= 0 ? 0.0 : source.actual / totalActual;

            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == visibleCount - 1 ? 0 : 14,
              ),
              child: _BudgetExpenseBreakdownRow(
                item: _BudgetExpenseBreakdownItem(
                  label: source.label,
                  parentLabel: parentLabel,
                  icon: source.icono,
                  color: source.color,
                  total: source.actual,
                  count: 0,
                ),
                share: share,
                subtitle: subtitle,
                amountLabel: _fmt(source.actual),
                amountColor: AppColors.e6,
              ),
            );
          }),
          if (visibleSources.length > 6) ...[
            SizedBox(height: (12)),
            Text(
              '+${visibleSources.length - 6} categoría${visibleSources.length - 6 == 1 ? '' : 's'} más',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.menudo.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var displayBudget = widget.budget;
    for (final budget in ref.watch(effectiveBudgetsProvider)) {
      if (budget.id == widget.budget.id) {
        displayBudget = budget;
        break;
      }
    }

    final categories = ref.watch(effectiveCategoriesProvider);
    final categoriesById = <int, MenudoCategory>{
      for (final category in categories) category.id: category,
    };
    final referenceDate = ref.watch(transactionsReferenceDateProvider);
    final periodTransactions = _transactionsForBudgetPeriod(
      displayBudget,
      ref.watch(effectiveTransactionsProvider),
      referenceDate,
    );
    final expenseBreakdown = _expenseBreakdownForBudget(
      periodTransactions,
      categories,
      categoriesById,
    );
    final incomeBreakdown = [
      ...displayBudget.incomeSources,
      ...displayBudget.otherIncomeSources,
    ];
    final extraExpenseCategories = [...displayBudget.otherExpenses]
      ..sort((a, b) {
        final parentCompare = _parentLabelForExpense(
          a,
          categoriesById,
        ).compareTo(_parentLabelForExpense(b, categoriesById));
        if (parentCompare != 0) return parentCompare;
        return a.label.compareTo(b.label);
      });
    final double spent = displayBudget.totalSpent;
    final double left = displayBudget.availableToSpend;
    final bool isShared =
        _members.length > 1 || displayBudget.espacioId != null;
    final currentUserId = int.tryParse(ref.watch(authProvider).userId ?? '');
    final canDeleteBudget = _isCurrentUserOwner(displayBudget, currentUserId);
    final media = MediaQuery.of(context);
    final sheetHeight =
        media.size.height * (media.size.height < 860 ? 0.96 : 0.92);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          MenudoGestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: _onDismissDragUpdate,
            onVerticalDragEnd: _onDismissDragEnd,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 18),
                decoration: BoxDecoration(
                  color: context.menudo.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayBudget.nombre,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: context.menudo.textMain,
                              letterSpacing: -0.8,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SheetMetaPill(
                                label: displayBudget.periodo.toUpperCase(),
                              ),
                              if (isShared)
                                const _SheetMetaPill(label: 'Compartido'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: (12)),
                    _HeaderAction(
                      icon: MenudoCupertinoIcons.moreHorizontal,
                      onTap: _openBudgetActions,
                    ),
                    if (canDeleteBudget) ...[
                      SizedBox(width: 8),
                      _HeaderAction(
                        icon: MenudoCupertinoIcons.trash2,
                        isDestructive: true,
                        onTap: _deleteBudget,
                      ),
                    ],
                    SizedBox(width: 8),
                    _HeaderAction(
                      icon: MenudoCupertinoIcons.plus,
                      isPrimary: true,
                      onTap: () {
                        MenudoHaptics.medium();
                        ref
                            .read(budgetControllerProvider.notifier)
                            .selectBudgetLocally(displayBudget.id);
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const RegisterTransactionSheet(),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: (18)),
                _BudgetOverviewCard(
                      budget: displayBudget,
                      spent: spent,
                      left: left,
                      fmt: _fmt,
                    )
                    .animate()
                    .fadeIn(duration: 320.ms)
                    .slideY(begin: 0.03, end: 0),
                SizedBox(height: (16)),
                _TabSwitcher(activeTab: _tab, onChanged: _onTabChanged),
                SizedBox(height: (18)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey(_tab),
                    children: [
                      if (_tab == "resumen") ...[
                        _buildTransactionsByCategorySection(expenseBreakdown),
                        _buildIncomeByCategorySection(
                          incomeBreakdown,
                          categoriesById,
                        ),
                        _buildSharedBudgetSection(isShared: isShared),
                        _buildCategoriesSection(
                          displayBudget,
                          categoriesById,
                          extraExpenseCategories,
                        ),
                      ],
                      if (_tab == "plan")
                        _buildPlanTab(
                          context,
                          displayBudget,
                          categoriesById,
                          extraExpenseCategories,
                        ),
                      if (_tab == "insights")
                        _buildInsightsTab(displayBudget, categoriesById),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedBudgetSection({required bool isShared}) {
    final previewMembers = _members.take(3).toList();
    final extraMembers = _members.length - previewMembers.length;
    final title = isShared ? 'Presupuesto compartido' : 'Compartir presupuesto';
    final subtitle = _isLoadingMembers
        ? 'Preparando accesos...'
        : isShared
        ? '${_members.length} miembro${_members.length == 1 ? '' : 's'} con acceso'
        : 'Invita hasta 3 personas por correo';
    final actionLabel = isShared ? 'Abrir' : 'Invitar';

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.menudo.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      MenudoCupertinoIcons.users,
                      size: (16),
                      color: AppColors.e6,
                    ),
                  ),
                  SizedBox(width: (12)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.menudo.textMain,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.menudo.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _SmallActionButton(
                label: actionLabel,
                onTap: _openMembersManager,
              ),
            ],
          ),
          SizedBox(height: (18)),
          if (_isLoadingMembers && previewMembers.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: MenudoInlineLoadingCard(
                label: 'Cargando personas',
                compact: true,
              ),
            )
          else if (_membersError != null && previewMembers.isEmpty)
            _InlineInfoCard(
              text: _membersError!,
              tone: _InfoCardTone.error,
              actionLabel: 'Reintentar',
              onTap: _loadMembers,
            )
          else if (previewMembers.isEmpty)
            _InlineInfoCard(
              text: isShared
                  ? 'Todavía no hay colaboradores aceptados en este presupuesto.'
                  : 'Solo tú tienes acceso por ahora. Puedes enviar invitaciones cuando quieras.',
            )
          else ...[
            ...previewMembers.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MemberRow(member: member),
              ),
            ),
            if (extraMembers > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+$extraMembers miembro${extraMembers == 1 ? '' : 's'} más',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.menudo.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildCategoriesSection(
    MenudoBudget budget,
    Map<int, MenudoCategory> categoriesById,
    List<BudgetCategory> extraExpenseCategories,
  ) {
    final plannedCategories = budget.cats.values
        .where((category) => category.limite > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(2, 26, 0, 10),
          child: _BudgetSectionTitle(title: 'Categorías del presupuesto'),
        ),
        ...plannedCategories.asMap().entries.map((entry) {
          return _CategoryDetailCard(
                cat: entry.value,
                parentLabel: _parentLabelForExpense(
                  entry.value,
                  categoriesById,
                ),
                fmt: _fmt,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: (entry.key * 50).ms)
              .slideX(begin: 0.05, end: 0);
        }),
        if (extraExpenseCategories.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(2, 18, 0, 10),
            child: _BudgetSectionTitle(title: 'Otros gastos fuera del plan'),
          ),
          ...extraExpenseCategories.map(
            (category) => _UnplannedExpenseCard(
              cat: category,
              parentLabel: _parentLabelForExpense(category, categoriesById),
              fmt: _fmt,
            ),
          ),
        ],
        SizedBox(height: 8),
        MenudoGestureDetector(
          onTap: _openBudgetEditor,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: context.menudo.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.menudo.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  MenudoCupertinoIcons.plus,
                  size: (20),
                  color: context.menudo.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  "Añadir categoría",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.menudo.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildPlanTab(
    BuildContext context,
    MenudoBudget budget,
    Map<int, MenudoCategory> categoriesById,
    List<BudgetCategory> extraExpenseCategories,
  ) {
    final incomeSources = [...budget.incomeSources]
      ..sort((a, b) {
        final parentCompare = _parentLabelForIncome(
          a,
          categoriesById,
        ).compareTo(_parentLabelForIncome(b, categoriesById));
        if (parentCompare != 0) return parentCompare;
        return a.label.compareTo(b.label);
      });
    final otherIncomeSources = [...budget.otherIncomeSources]
      ..sort((a, b) {
        final parentCompare = _parentLabelForIncome(
          a,
          categoriesById,
        ).compareTo(_parentLabelForIncome(b, categoriesById));
        if (parentCompare != 0) return parentCompare;
        return a.label.compareTo(b.label);
      });
    final expenseCategories =
        [...budget.cats.values.where((category) => category.limite > 0)]
          ..sort((a, b) {
            final parentCompare = _parentLabelForExpense(
              a,
              categoriesById,
            ).compareTo(_parentLabelForExpense(b, categoriesById));
            if (parentCompare != 0) return parentCompare;
            return a.label.compareTo(b.label);
          });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (incomeSources.isNotEmpty) ...[
          const _BudgetSectionTitle(title: 'Ingresos planificados'),
          SizedBox(height: 8),
          _buildPlanGrid(
            context,
            incomeSources
                .map(
                  (source) => _IncomePlanRow(
                    source: source,
                    parentLabel: _parentLabelForIncome(source, categoriesById),
                    fmt: _fmt,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: (16)),
        ] else ...[
          const _BudgetSectionTitle(title: 'Ingresos planificados'),
          SizedBox(height: 8),
          _PlanStateCard(
            icon: MenudoCupertinoIcons.trendingUp,
            title: 'Todavía no has definido ingresos',
            message:
                'Añade ingresos esperados para que este plan se entienda mejor de un vistazo.',
            actionLabel: 'Editar presupuesto',
            onTap: _openBudgetEditor,
          ),
          SizedBox(height: (16)),
        ],
        if (otherIncomeSources.isNotEmpty) ...[
          const _BudgetSectionTitle(title: 'Ingresos fuera del plan'),
          SizedBox(height: 8),
          _buildPlanGrid(
            context,
            otherIncomeSources
                .map(
                  (source) => _IncomePlanRow(
                    source: source,
                    parentLabel: _parentLabelForIncome(source, categoriesById),
                    fmt: _fmt,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: (16)),
        ],
        const _BudgetSectionTitle(title: 'Categorías con límite'),
        SizedBox(height: 8),
        if (expenseCategories.isEmpty)
          _PlanStateCard(
            icon: MenudoCupertinoIcons.layoutGrid,
            title: 'Aún no has organizado este plan',
            message:
                'Agrega categorías con límite para repartir mejor lo que quieres gastar.',
            actionLabel: 'Editar presupuesto',
            onTap: _openBudgetEditor,
          )
        else
          _buildPlanGrid(
            context,
            expenseCategories
                .map(
                  (cat) => _PlanCategoryRow(
                    cat: cat,
                    parentLabel: _parentLabelForExpense(cat, categoriesById),
                    fmt: _fmt,
                  ),
                )
                .toList(),
          ),
        if (extraExpenseCategories.isNotEmpty) ...[
          SizedBox(height: (16)),
          const _BudgetSectionTitle(title: 'Gastos fuera del plan'),
          SizedBox(height: 8),
          _buildPlanGrid(
            context,
            extraExpenseCategories
                .map(
                  (cat) => _UnplannedExpenseCard(
                    cat: cat,
                    parentLabel: _parentLabelForExpense(cat, categoriesById),
                    fmt: _fmt,
                  ),
                )
                .toList(),
          ),
        ] else ...[
          SizedBox(height: (16)),
          const _BudgetSectionTitle(title: 'Gastos fuera del plan'),
          SizedBox(height: 8),
          const _PlanStateCard(
            icon: MenudoCupertinoIcons.shieldCheck,
            title: 'Todo va dentro del plan',
            message:
                'Cuando aparezca un gasto fuera de las categorías configuradas, lo verás aquí.',
            tone: _PlanStateTone.success,
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPlanGrid(BuildContext context, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) SizedBox(height: (12)),
        ],
      ],
    );
  }

  String _parentLabelForExpense(
    BudgetCategory category,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final parentId = category.parentCategoryId;
    if (parentId == null) return '';
    return categoriesById[parentId]?.nombre ?? '';
  }

  String _parentLabelForIncome(
    BudgetIncomeSource source,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final parentId = source.parentCategoryId;
    if (parentId == null) return '';
    return categoriesById[parentId]?.nombre ?? '';
  }

  Widget _buildInsightsTab(
    MenudoBudget budget,
    Map<int, MenudoCategory> categoriesById,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_supportsHistory)
          const _InlineInfoCard(
            text:
                'Este presupuesto es puntual, así que no genera cierres automáticos.',
          )
        else if (_isLoadingHistory && _history.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: MenudoInlineLoadingCard(label: 'Cargando cierres'),
          )
        else if (_historyError != null && _history.isEmpty)
          _InlineInfoCard(
            text: _historyError!,
            tone: _InfoCardTone.error,
            actionLabel: 'Reintentar',
            onTap: _loadHistory,
          )
        else if (_history.isEmpty)
          _InlineInfoCard(text: _historyEmptyMessage(budget.periodo))
        else ...[
          ..._history.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == _history.length - 1 ? 0 : 14,
              ),
              child: _HistorySnapshotCard(
                snapshot: entry.value,
                rangeLabel: _historyRangeLabel(entry.value),
                categoriesById: categoriesById,
                fmt: _fmtAmount,
              ),
            ),
          ),
          if (_historyHasMore) ...[
            SizedBox(height: (16)),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoadingMoreHistory
                    ? null
                    : () => _loadHistory(loadMore: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.menudo.textMain,
                  side: BorderSide(color: context.menudo.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _isLoadingMoreHistory ? 'Cargando...' : 'Cargar más cierres',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ── Supporting Widgets ────────────────────────────────────────

class _BudgetOverviewCard extends StatelessWidget {
  const _BudgetOverviewCard({
    required this.budget,
    required this.spent,
    required this.left,
    required this.fmt,
  });

  final MenudoBudget budget;
  final double spent;
  final double left;
  final String Function(double value) fmt;

  @override
  Widget build(BuildContext context) {
    final planBase = budget.displayIncomeBase;
    final actualIncome = budget.actualIncomeTotal;
    final hasActualIncome = actualIncome > 0;
    final primaryValue = hasActualIncome ? actualIncome - spent : left;
    final usage = planBase > 0 ? (spent / planBase).clamp(0.0, 1.0) : 0.0;
    final accentColor = primaryValue < 0
        ? AppColors.r5
        : context.menudo.textMain;
    final spentSummary = hasActualIncome
        ? '${fmt(spent)} gastados de ${fmt(actualIncome)} recibidos'
        : planBase > 0
        ? '${fmt(spent)} de ${fmt(planBase)} usados'
        : '${fmt(spent)} usados';
    final metrics = [
      _OverviewMetric(label: 'Plan', value: fmt(planBase)),
      _OverviewMetric(label: 'Ingresó', value: fmt(actualIncome)),
      _OverviewMetric(
        label: 'Meta',
        value: budget.ahorroObjetivo > 0
            ? fmt(budget.ahorroObjetivo)
            : 'Sin meta',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.e1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PRESUPUESTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e6,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (14)),
          Text(
            hasActualIncome ? 'Balance actual' : 'Disponible del plan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.menudo.textMuted,
            ),
          ),
          SizedBox(height: 6),
          SizedBox(
            height: 42,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                fmt(primaryValue),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: -1.2,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            spentSummary,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.menudo.textSecondary,
            ),
          ),
          SizedBox(height: (14)),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usage,
              minHeight: 8,
              backgroundColor: context.menudo.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                primaryValue < 0 ? AppColors.r5 : AppColors.e6,
              ),
            ),
          ),
          SizedBox(height: (16)),
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) SizedBox(width: (10)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.menudo.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.menudo.textMuted,
            ),
          ),
          SizedBox(height: 4),
          SizedBox(
            height: (18),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetMetaPill extends StatelessWidget {
  const _SheetMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: context.menudo.textSecondary,
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final background = isDestructive
        ? colors.dangerLight
        : isPrimary
        ? colors.primary
        : colors.surface;
    final foreground = isDestructive
        ? colors.danger
        : isPrimary
        ? colors.textOnDark
        : colors.textMain;
    final borderColor = isDestructive
        ? colors.danger.withValues(alpha: 0.24)
        : isPrimary
        ? colors.primary
        : colors.border;

    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: foreground, size: (18)),
      ),
    );
  }
}

class _BudgetActionOption extends StatelessWidget {
  const _BudgetActionOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final resolvedColor = color ?? colors.textMain;

    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: (18), color: resolvedColor),
            SizedBox(width: (12)),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: resolvedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final String activeTab;
  final Function(String) onChanged;

  const _TabSwitcher({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _TabItem(
            label: "Resumen",
            id: "resumen",
            isActive: activeTab == "resumen",
            onTap: () => onChanged("resumen"),
          ),
          _TabItem(
            label: "Plan",
            id: "plan",
            isActive: activeTab == "plan",
            onTap: () => onChanged("plan"),
          ),
          _TabItem(
            label: "Historial",
            id: "insights",
            isActive: activeTab == "insights",
            onTap: () => onChanged("insights"),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label, id;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.id,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Expanded(
      child: MenudoGestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? colors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isActive ? colors.border : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? colors.textMain : colors.textSecondary,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final BudgetMember member;

  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: (38),
          height: (38),
          decoration: BoxDecoration(
            color: member.c,
            shape: BoxShape.circle,
            border: Border.all(color: context.menudo.textOnDark, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            member.i,
            style: TextStyle(
              color: context.menudo.textOnDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: (14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      member.n,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMain,
                      ),
                    ),
                  ),
                  MenudoChip.custom(
                    label: member.isOwner
                        ? 'DUEÑO'
                        : (member.role ?? 'MIEMBRO').toUpperCase(),
                    color: member.isOwner
                        ? context.menudo.textMain
                        : AppColors.o5,
                    bgColor: member.isOwner ? AppColors.e1 : AppColors.o1,
                    isSmall: true,
                  ),
                ],
              ),
              if ((member.email ?? '').isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  member.email!,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.menudo.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  final String text;
  final _InfoCardTone tone;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _InlineInfoCard({
    required this.text,
    this.tone = _InfoCardTone.neutral,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isError = tone == _InfoCardTone.error;
    final isSuccess = tone == _InfoCardTone.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.r1
            : isSuccess
            ? AppColors.e1
            : context.menudo.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: isError
                    ? AppColors.r5
                    : isSuccess
                    ? AppColors.e6
                    : context.menudo.textSecondary,
              ),
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            SizedBox(width: (12)),
            MenudoGestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isError
                      ? AppColors.r5
                      : isSuccess
                      ? AppColors.e6
                      : context.menudo.textMain,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _InfoCardTone { neutral, success, error }

class _PlanStateCard extends StatelessWidget {
  const _PlanStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onTap,
    this.tone = _PlanStateTone.neutral,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;
  final _PlanStateTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = tone == _PlanStateTone.success
        ? AppColors.e6
        : context.menudo.textMain;
    final background = tone == _PlanStateTone.success
        ? AppColors.e1
        : context.menudo.surface;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.menudo.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: (20), color: accent),
          ),
          SizedBox(width: (14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.menudo.textMain,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: context.menudo.textSecondary,
                  ),
                ),
                if (actionLabel != null && onTap != null) ...[
                  SizedBox(height: (12)),
                  MenudoGestureDetector(
                    onTap: onTap,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlanStateTone { neutral, success }

class _BudgetMembersSheet extends ConsumerStatefulWidget {
  final int budgetId;
  final List<BudgetMember> initialMembers;
  final bool allowInviteWhenEmpty;

  const _BudgetMembersSheet({
    required this.budgetId,
    required this.initialMembers,
    this.allowInviteWhenEmpty = false,
  });

  @override
  ConsumerState<_BudgetMembersSheet> createState() =>
      _BudgetMembersSheetState();
}

class _BudgetMembersSheetState extends ConsumerState<_BudgetMembersSheet> {
  static const _inviteCooldownStorage = FlutterSecureStorage();
  static const _inviteCooldownResetAfter = Duration(hours: 12);
  static const _inviteCooldownSchedule = <Duration>[
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
  ];

  final TextEditingController _inviteController = TextEditingController();
  List<BudgetMember> _members = [];
  Map<String, _InviteCooldownEntry> _inviteCooldowns = const {};
  bool _isLoading = false;
  bool _isInviting = false;
  String? _error;
  String? _inviteFeedback;
  _InfoCardTone _inviteFeedbackTone = _InfoCardTone.neutral;
  int? _removingUserId;
  Timer? _inviteCooldownTicker;

  @override
  void initState() {
    super.initState();
    _members = widget.initialMembers;
    _inviteController.addListener(_handleInviteEmailChanged);
    _restoreInviteCooldowns();
    _startInviteCooldownTicker();
    _loadMembers();
  }

  String get _normalizedInviteEmail {
    return _inviteController.text.trim().toLowerCase();
  }

  String _inviteCooldownKeyFor(String email) {
    return '${widget.budgetId}:$email';
  }

  _InviteCooldownEntry? get _activeInviteCooldown {
    final email = _normalizedInviteEmail;
    if (email.isEmpty) return null;

    final entry = _inviteCooldowns[_inviteCooldownKeyFor(email)];
    if (entry == null) return null;
    if (!entry.nextAllowedAt.isAfter(DateTime.now())) return null;
    return entry;
  }

  Duration? get _activeInviteCooldownRemaining {
    final entry = _activeInviteCooldown;
    if (entry == null) return null;
    final remaining = entry.nextAllowedAt.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Duration get _nextInviteCooldownStep {
    final entry = _activeInviteCooldown;
    final nextAttempt = (entry?.attempts ?? 0) + 1;
    return _inviteCooldownDurationForAttempt(nextAttempt);
  }

  void _handleInviteEmailChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _restoreInviteCooldowns() async {
    final raw = await _inviteCooldownStorage.read(
      key: StorageKeys.budgetInviteCooldowns,
    );
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final now = DateTime.now();
      final restored = <String, _InviteCooldownEntry>{};
      decoded.forEach((key, value) {
        if (value is! Map) return;
        final entry = _InviteCooldownEntry.fromJson(
          Map<String, dynamic>.from(value),
        );
        if (now.difference(entry.lastSentAt) <= _inviteCooldownResetAfter) {
          restored[key] = entry;
        }
      });

      if (!mounted) return;
      setState(() => _inviteCooldowns = restored);
    } catch (_) {
      await _inviteCooldownStorage.delete(
        key: StorageKeys.budgetInviteCooldowns,
      );
    }
  }

  Future<void> _persistInviteCooldowns() {
    final payload = <String, dynamic>{
      for (final entry in _inviteCooldowns.entries)
        entry.key: entry.value.toJson(),
    };
    return _inviteCooldownStorage.write(
      key: StorageKeys.budgetInviteCooldowns,
      value: jsonEncode(payload),
    );
  }

  void _startInviteCooldownTicker() {
    _inviteCooldownTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_inviteCooldowns.isEmpty) return;
      setState(() {});
    });
  }

  Duration _inviteCooldownDurationForAttempt(int attempt) {
    final index = max(0, min(attempt - 1, _inviteCooldownSchedule.length - 1));
    return _inviteCooldownSchedule[index];
  }

  Future<void> _recordInviteCooldown(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;

    final key = _inviteCooldownKeyFor(normalizedEmail);
    final now = DateTime.now();
    final previous = _inviteCooldowns[key];
    final previousAttempts =
        previous != null &&
            now.difference(previous.lastSentAt) <= _inviteCooldownResetAfter
        ? previous.attempts
        : 0;
    final attempts = previousAttempts + 1;
    final duration = _inviteCooldownDurationForAttempt(attempts);
    final nextEntry = _InviteCooldownEntry(
      attempts: attempts,
      lastSentAt: now,
      nextAllowedAt: now.add(duration),
    );

    setState(() {
      _inviteCooldowns = {..._inviteCooldowns, key: nextEntry};
    });

    await _persistInviteCooldowns();
  }

  String _formatInviteCountdown(Duration value) {
    final totalSeconds = max(0, value.inSeconds);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatInviteCooldownLabel(Duration value) {
    if (value.inMinutes >= 1) {
      return '${value.inMinutes} min';
    }
    return '${value.inSeconds}s';
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await ref
          .read(budgetControllerProvider.notifier)
          .fetchBudgetMembers(widget.budgetId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = presentError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMember(BudgetMember member) async {
    final targetUserId = member.userId;
    if (targetUserId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Quitar miembro'),
        content: Text('${member.n} perderá acceso a este presupuesto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Sí, quitar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _removingUserId = targetUserId);
    try {
      await ref
          .read(budgetControllerProvider.notifier)
          .removeBudgetMember(widget.budgetId, targetUserId);
      if (!mounted) return;
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.n} ya no tiene acceso a este presupuesto.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(presentError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _removingUserId = null);
      }
    }
  }

  void _closeSheet() {
    Navigator.pop(context, _members);
  }

  bool get _canManageMembers {
    final currentUserId = int.tryParse(ref.read(authProvider).userId ?? '');
    if (currentUserId == null) return false;

    for (final member in _members) {
      if (member.userId == currentUserId) {
        return member.isOwner || member.role == 'admin';
      }
    }
    return widget.allowInviteWhenEmpty && _members.isEmpty;
  }

  @override
  void dispose() {
    _inviteCooldownTicker?.cancel();
    _inviteController.removeListener(_handleInviteEmailChanged);
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    final email = _inviteController.text.trim();
    final activeCooldown = _activeInviteCooldownRemaining;
    if (email.isEmpty) {
      setState(() {
        _inviteFeedback = 'Escribe un correo para poder invitar a alguien.';
        _inviteFeedbackTone = _InfoCardTone.error;
      });
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      setState(() {
        _inviteFeedback =
            'Ese correo no parece válido. Revísalo e inténtalo otra vez.';
        _inviteFeedbackTone = _InfoCardTone.error;
      });
      return;
    }

    if (activeCooldown != null) {
      setState(() {
        _inviteFeedback =
            'Todavía no puedes reenviar a ese correo. Espera ${_formatInviteCountdown(activeCooldown)}.';
        _inviteFeedbackTone = _InfoCardTone.error;
      });
      return;
    }

    setState(() {
      _isInviting = true;
      _inviteFeedback = null;
    });
    try {
      await ref
          .read(budgetControllerProvider.notifier)
          .inviteBudgetMember(widget.budgetId, email);
      if (!mounted) return;
      await _recordInviteCooldown(email);
      _inviteController.clear();
      await _loadMembers();
      if (!mounted) return;
      final appliedCooldown = _inviteCooldownDurationForAttempt(
        _inviteCooldowns[_inviteCooldownKeyFor(email.trim().toLowerCase())]
                ?.attempts ??
            1,
      );
      setState(() {
        _inviteFeedback =
            'Listo. Enviamos la invitación a $email. Podrás reenviarla en ${_formatInviteCooldownLabel(appliedCooldown)}.';
        _inviteFeedbackTone = _InfoCardTone.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _inviteFeedback = presentError(error);
        _inviteFeedbackTone = _InfoCardTone.error;
      });
    } finally {
      if (mounted) {
        setState(() => _isInviting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeInviteCooldown = _activeInviteCooldownRemaining;
    final canTapInvite = !_isInviting && activeInviteCooldown == null;
    final cooldownHelperText = activeInviteCooldown == null
        ? null
        : 'Puedes reenviar a este correo en ${_formatInviteCountdown(activeInviteCooldown)}. '
              'Si vuelves a mandarla, el siguiente bloqueo sube a ${_formatInviteCooldownLabel(_nextInviteCooldownStep)}.';

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: (12)),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.menudo.textMuted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Miembros',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: context.menudo.textMain,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Personas con acceso a este presupuesto',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.menudo.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MenudoIconButton(
                    onPressed: _closeSheet,
                    icon: Icon(MenudoCupertinoIcons.x, size: (20)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMembers,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (_canManageMembers) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: context.menudo.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invitar por correo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: context.menudo.textMain,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Comparte acceso sin salir de aquí.',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.menudo.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: (14)),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _inviteController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: canTapInvite
                                        ? (_) => _inviteMember()
                                        : null,
                                    decoration: InputDecoration(
                                      hintText: 'correo@ejemplo.com',
                                      filled: true,
                                      fillColor: context.menudo.surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: AppColors.e6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: (10)),
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: canTapInvite
                                        ? _inviteMember
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.e6,
                                      foregroundColor:
                                          context.menudo.textOnDark,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isInviting
                                        ? SizedBox(
                                            width: (16),
                                            height: (16),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: context.menudo.textOnDark,
                                            ),
                                          )
                                        : activeInviteCooldown != null
                                        ? Text(
                                            _formatInviteCountdown(
                                              activeInviteCooldown,
                                            ),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          )
                                        : Icon(
                                            MenudoCupertinoIcons.send,
                                            size: (18),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            if (cooldownHelperText != null) ...[
                              SizedBox(height: (12)),
                              _InlineInfoCard(text: cooldownHelperText),
                            ],
                            if (_inviteFeedback != null) ...[
                              SizedBox(height: (12)),
                              _InlineInfoCard(
                                text: _inviteFeedback!,
                                tone: _inviteFeedbackTone,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: (16)),
                    ],
                    if (_isLoading && _members.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: MenudoInlineLoadingCard(
                          label: 'Cargando equipo',
                        ),
                      )
                    else if (_error != null && _members.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _InlineInfoCard(
                          text: _error!,
                          tone: _InfoCardTone.error,
                          actionLabel: 'Reintentar',
                          onTap: _loadMembers,
                        ),
                      )
                    else if (_members.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: _InlineInfoCard(
                          text: _canManageMembers
                              ? 'Todavía nadie se ha unido. Cuando acepten su invitación, aparecerán aquí.'
                              : 'Por ahora solo tú tienes acceso a este presupuesto.',
                        ),
                      )
                    else
                      ..._members.map((member) {
                        final isRemoving = _removingUserId == member.userId;
                        final canRemove =
                            _canManageMembers &&
                            !member.isOwner &&
                            member.userId != null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.menudo.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.menudo.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: member.c,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  member.i,
                                  style: TextStyle(
                                    color: context.menudo.textOnDark,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              SizedBox(width: (12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            member.n,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: context.menudo.textMain,
                                            ),
                                          ),
                                        ),
                                        MenudoChip.custom(
                                          label: member.isOwner
                                              ? 'DUEÑO'
                                              : (member.role ?? 'MIEMBRO')
                                                    .toUpperCase(),
                                          color: member.isOwner
                                              ? context.menudo.textMain
                                              : AppColors.o5,
                                          bgColor: member.isOwner
                                              ? AppColors.e1
                                              : AppColors.o1,
                                          isSmall: true,
                                        ),
                                      ],
                                    ),
                                    if ((member.email ?? '').isNotEmpty) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        member.email!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.menudo.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (canRemove) ...[
                                SizedBox(width: (10)),
                                TextButton(
                                  onPressed: isRemoving
                                      ? null
                                      : () => _removeMember(member),
                                  child: isRemoving
                                      ? SizedBox(
                                          width: (16),
                                          height: (16),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text('Quitar'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    SizedBox(height: 8),
                    _InlineInfoCard(
                      text: _canManageMembers
                          ? 'Puedes invitar nuevos colaboradores o quitar acceso a los miembros actuales.'
                          : 'Aquí puedes revisar quién tiene acceso a este presupuesto.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCooldownEntry {
  const _InviteCooldownEntry({
    required this.attempts,
    required this.lastSentAt,
    required this.nextAllowedAt,
  });

  final int attempts;
  final DateTime lastSentAt;
  final DateTime nextAllowedAt;

  factory _InviteCooldownEntry.fromJson(Map<String, dynamic> json) {
    return _InviteCooldownEntry(
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastSentAt:
          DateTime.tryParse(json['last_sent_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      nextAllowedAt:
          DateTime.tryParse(json['next_allowed_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attempts': attempts,
      'last_sent_at': lastSentAt.toIso8601String(),
      'next_allowed_at': nextAllowedAt.toIso8601String(),
    };
  }
}

class _CategoryDetailCard extends StatelessWidget {
  final BudgetCategory cat;
  final String parentLabel;
  final String Function(double) fmt;

  const _CategoryDetailCard({
    required this.cat,
    required this.parentLabel,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final visibleParentLabel = _distinctSecondaryLabel(
      parentLabel,
      against: cat.label,
    );
    final double left = cat.limite - cat.gastado;
    final double pct = min(
      cat.gastado / (cat.limite > 0 ? cat.limite : 1),
      1.0,
    );
    final bool over = cat.gastado > cat.limite;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: over
              ? AppColors.o5.withValues(alpha: 0.3)
              : context.menudo.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icono, size: (20), color: cat.color),
              ),
              SizedBox(width: (14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (visibleParentLabel.isNotEmpty)
                      Text(
                        visibleParentLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.menudo.textMuted,
                        ),
                      ),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMain,
                      ),
                    ),
                    Text(
                      "Límite: ${fmt(cat.limite)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: context.menudo.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (over)
                MenudoChip.custom(
                  label: "Excedido",
                  color: AppColors.o5,
                  bgColor: AppColors.o1,
                  isSmall: true,
                ),
            ],
          ),
          SizedBox(height: (16)),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: context.menudo.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                over ? AppColors.o5 : cat.color,
              ),
            ),
          ),
          SizedBox(height: (10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Gastado: ${fmt(cat.gastado)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textSecondary,
                ),
              ),
              Text(
                over
                    ? "Faltan ${fmt(cat.gastado - cat.limite)}"
                    : "Quedan ${fmt(left)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: over ? AppColors.o5 : AppColors.e6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnplannedExpenseCard extends StatelessWidget {
  final BudgetCategory cat;
  final String parentLabel;
  final String Function(double) fmt;

  const _UnplannedExpenseCard({
    required this.cat,
    required this.parentLabel,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final visibleParentLabel = _distinctSecondaryLabel(
      parentLabel,
      against: cat.label,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.menudo.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BudgetPlanIcon(color: AppColors.o5, icon: cat.icono),
          SizedBox(width: (14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: context.menudo.textMain,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  visibleParentLabel.isEmpty
                      ? 'Sin tope definido'
                      : '$visibleParentLabel · Sin tope definido',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.menudo.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: (12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt(cat.gastado),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.o5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sin tope',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCategoryRow extends StatelessWidget {
  final BudgetCategory cat;
  final String parentLabel;
  final String Function(double) fmt;

  const _PlanCategoryRow({
    required this.cat,
    required this.parentLabel,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final visibleParentLabel = _distinctSecondaryLabel(
      parentLabel,
      against: cat.label,
    );
    final usage = cat.limite > 0 ? (cat.gastado / cat.limite) : 0.0;
    final over = usage > 1;
    final statusColor = over ? AppColors.o5 : AppColors.e6;
    final balance = cat.limite - cat.gastado;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: over
              ? AppColors.o5.withValues(alpha: 0.24)
              : context.menudo.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BudgetPlanIcon(color: cat.color, icon: cat.icono),
              SizedBox(width: (14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMain,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      visibleParentLabel.isEmpty
                          ? 'Límite ${fmt(cat.limite)}'
                          : '$visibleParentLabel · Límite ${fmt(cat.limite)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.menudo.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: (12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(cat.gastado),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    over
                        ? 'Se pasó ${fmt(cat.gastado - cat.limite)}'
                        : 'Quedan ${fmt(balance)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: (14)),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usage.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: context.menudo.surface,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          SizedBox(height: (10)),
          Row(
            children: [
              Text(
                'Gastado ${fmt(cat.gastado)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Plan ${fmt(cat.limite)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomePlanRow extends StatelessWidget {
  const _IncomePlanRow({
    required this.source,
    required this.parentLabel,
    required this.fmt,
  });

  final BudgetIncomeSource source;
  final String parentLabel;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    final visibleParentLabel = _distinctSecondaryLabel(
      parentLabel,
      against: source.label,
    );
    final isPositive = source.difference >= 0;
    final accent = isPositive ? AppColors.e6 : AppColors.o5;
    final plannedBase = source.planned > 0 ? source.planned : source.actual;
    final progress = plannedBase > 0 ? (source.actual / plannedBase) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: source.color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BudgetPlanIcon(color: source.color, icon: source.icono),
              SizedBox(width: (14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: context.menudo.textMain,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      visibleParentLabel.isEmpty
                          ? (source.planned > 0
                                ? 'Plan ${fmt(source.planned)}'
                                : 'Sin plan configurado')
                          : source.planned > 0
                          ? '$visibleParentLabel · Plan ${fmt(source.planned)}'
                          : '$visibleParentLabel · Sin plan configurado',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.menudo.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: (12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(source.actual),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    source.difference == 0
                        ? 'En línea'
                        : isPositive
                        ? '+${fmt(source.difference)}'
                        : '-${fmt(source.difference.abs())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (source.planned > 0) ...[
            SizedBox(height: (14)),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: context.menudo.surface,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            SizedBox(height: (10)),
          ] else
            SizedBox(height: (10)),
          Text(
            source.planned <= 0
                ? 'Este ingreso no tenía monto previsto en tu presupuesto.'
                : source.difference == 0
                ? 'Va exactamente como lo planeado.'
                : isPositive
                ? 'Recibiste ${fmt(source.difference)} por encima del plan.'
                : 'Faltan ${fmt(source.difference.abs())} para llegar al objetivo.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPlanIcon extends StatelessWidget {
  const _BudgetPlanIcon({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: (20), color: color),
    );
  }
}

class _BudgetSectionTitle extends StatelessWidget {
  const _BudgetSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.menudo.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySnapshotCard extends StatelessWidget {
  const _HistorySnapshotCard({
    required this.snapshot,
    required this.rangeLabel,
    required this.categoriesById,
    required this.fmt,
  });

  final BudgetHistorySnapshot snapshot;
  final String rangeLabel;
  final Map<int, MenudoCategory> categoriesById;
  final String Function(double value, {String currency, bool signed}) fmt;

  @override
  Widget build(BuildContext context) {
    final topCategory = snapshot.categoriaMasAlta;
    final usesPlannedIncome = snapshot.ingresosPresupuestados > 0;
    final headlineValue = usesPlannedIncome
        ? snapshot.sobroPresupuesto
        : snapshot.balance;
    final headlineColor = headlineValue >= 0 ? AppColors.e6 : AppColors.r5;
    final headlineLabel = usesPlannedIncome ? 'Disponible' : 'Balance';
    final subtitle =
        '${_periodLabel(snapshot.periodo)} · ${snapshot.totalTransacciones} mov.';
    final expenseItems = [...snapshot.categoriasGastos, ...snapshot.otrosGastos]
      ..sort((a, b) => b.gastado.compareTo(a.gastado));
    final incomeItems = [...snapshot.ingresosDetalle, ...snapshot.otrosIngresos]
      ..sort((a, b) => b.actual.compareTo(a.actual));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.e1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _periodLabel(snapshot.periodo).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.e6,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                rangeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: (14)),
          Text(
            headlineLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: context.menudo.textMuted,
            ),
          ),
          SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              fmt(headlineValue),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: headlineColor,
                letterSpacing: -1.0,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.menudo.textSecondary,
            ),
          ),
          SizedBox(height: (16)),
          Divider(height: 1, thickness: 0.5, color: context.menudo.border),
          SizedBox(height: (14)),
          _HistoryValue(
            label: 'Ingresó',
            value: fmt(snapshot.ingresosReales),
            color: AppColors.e6,
          ),
          SizedBox(height: (12)),
          _HistoryValue(
            label: 'Gastó',
            value: fmt(snapshot.totalGastos),
            color: AppColors.o5,
          ),
          if (!usesPlannedIncome) ...[
            SizedBox(height: (12)),
            _HistoryValue(
              label: 'Balance',
              value: fmt(snapshot.balance),
              color: snapshot.balance >= 0
                  ? context.menudo.textMain
                  : AppColors.r5,
            ),
          ],
          if (topCategory != null && topCategory.label.trim().isNotEmpty) ...[
            SizedBox(height: (14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.e1,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(topCategory.icono, size: (15), color: AppColors.e6),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      topCategory.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (expenseItems.isNotEmpty) ...[
            SizedBox(height: (16)),
            Divider(height: 1, thickness: 0.5, color: context.menudo.border),
            SizedBox(height: (14)),
            Text(
              'Gastos por categoría',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.menudo.textSecondary,
              ),
            ),
            SizedBox(height: (10)),
            ...expenseItems.take(3).toList().asMap().entries.map((entry) {
              final visibleCount = min(expenseItems.length, 3);
              final item = entry.value;
              final totalExpenses = snapshot.totalGastos <= 0
                  ? 0.0
                  : item.gastado / snapshot.totalGastos;
              final parentLabel = item.parentCategoryId == null
                  ? ''
                  : distinctUiLabel(
                      categoriesById[item.parentCategoryId]?.nombre,
                      against: item.label,
                    );
              final subtitle = joinDistinctUiLabels([
                parentLabel,
                if (item.limite > 0) 'Plan ${fmt(item.limite)}',
              ]);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == visibleCount - 1 ? 0 : 10,
                ),
                child: _BudgetExpenseBreakdownRow(
                  item: _BudgetExpenseBreakdownItem(
                    label: item.label,
                    parentLabel: parentLabel,
                    icon: item.icono,
                    color: item.color,
                    total: item.gastado,
                    count: 0,
                  ),
                  share: totalExpenses,
                  subtitle: subtitle,
                  amountLabel: fmt(item.gastado),
                ),
              );
            }),
          ],
          if (incomeItems.isNotEmpty) ...[
            SizedBox(height: (16)),
            Divider(height: 1, thickness: 0.5, color: context.menudo.border),
            SizedBox(height: (14)),
            Text(
              'Ingresos por categoría',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.menudo.textSecondary,
              ),
            ),
            SizedBox(height: (10)),
            ...incomeItems.take(3).toList().asMap().entries.map((entry) {
              final visibleCount = min(incomeItems.length, 3);
              final item = entry.value;
              final totalIncome = snapshot.ingresosReales <= 0
                  ? 0.0
                  : item.actual / snapshot.ingresosReales;
              final parentLabel = item.parentCategoryId == null
                  ? ''
                  : distinctUiLabel(
                      categoriesById[item.parentCategoryId]?.nombre,
                      against: item.label,
                    );
              final subtitle = joinDistinctUiLabels([
                parentLabel,
                item.planned > 0 ? 'Plan ${fmt(item.planned)}' : 'Sin plan',
              ]);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == visibleCount - 1 ? 0 : 10,
                ),
                child: _BudgetExpenseBreakdownRow(
                  item: _BudgetExpenseBreakdownItem(
                    label: item.label,
                    parentLabel: parentLabel,
                    icon: item.icono,
                    color: item.color,
                    total: item.actual,
                    count: 0,
                  ),
                  share: totalIncome,
                  subtitle: subtitle,
                  amountLabel: fmt(item.actual),
                  amountColor: AppColors.e6,
                ),
              );
            }),
          ],
          if (snapshot.transacciones.isNotEmpty) ...[
            SizedBox(height: (16)),
            Divider(height: 1, thickness: 0.5, color: context.menudo.border),
            SizedBox(height: (14)),
            Text(
              'Últimos movimientos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.menudo.textSecondary,
              ),
            ),
            SizedBox(height: (10)),
            ...snapshot.transacciones
                .take(3)
                .toList()
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: entry.key == 2 ? 0 : 10),
                    child: _HistoryTransactionRow(
                      transaction: entry.value,
                      fmt: fmt,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  static String _periodLabel(String periodo) {
    switch (periodo) {
      case 'semanal':
        return 'Cierre semanal';
      case 'quincenal':
        return 'Cierre quincenal';
      case 'mensual':
        return 'Cierre mensual';
      default:
        return 'Cierre';
    }
  }
}

class _HistoryValue extends StatelessWidget {
  const _HistoryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.menudo.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _distinctSecondaryLabel(String? value, {String? against}) {
  return distinctUiLabel(value, against: against);
}

String _joinDistinctSecondaryLabels(Iterable<String?> values) {
  return joinDistinctUiLabels(values);
}

String _historyCompactDate(DateTime? value) {
  if (value == null) return '';
  const months = {
    1: 'ene',
    2: 'feb',
    3: 'mar',
    4: 'abr',
    5: 'may',
    6: 'jun',
    7: 'jul',
    8: 'ago',
    9: 'sep',
    10: 'oct',
    11: 'nov',
    12: 'dic',
  };
  return '${value.day} ${months[value.month] ?? value.month}';
}

class _HistoryTransactionRow extends StatelessWidget {
  const _HistoryTransactionRow({required this.transaction, required this.fmt});

  final BudgetHistoryTransaction transaction;
  final String Function(double value, {String currency, bool signed}) fmt;

  @override
  Widget build(BuildContext context) {
    final amount = transaction.signedAmount;
    final amountColor = amount >= 0 ? AppColors.e6 : AppColors.o5;
    final secondaryLabel = _joinDistinctSecondaryLabels([
      _historyCompactDate(transaction.fecha),
      transaction.usuarioNombre,
    ]);

    return Row(
      children: [
        Container(
          width: (34),
          height: (34),
          decoration: BoxDecoration(
            color: amountColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            transaction.categoriaIcono,
            size: (16),
            color: amountColor,
          ),
        ),
        SizedBox(width: (10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.descripcion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
              if (secondaryLabel.isNotEmpty) ...[
                SizedBox(height: 2),
                Text(
                  secondaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.menudo.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: (10)),
        Text(
          fmt(amount, signed: true),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

class _BudgetExpenseBreakdownRow extends StatelessWidget {
  const _BudgetExpenseBreakdownRow({
    required this.item,
    required this.share,
    required this.subtitle,
    required this.amountLabel,
    this.amountColor = AppColors.o5,
  });

  final _BudgetExpenseBreakdownItem item;
  final double share;
  final String subtitle;
  final String amountLabel;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: (34),
              height: (34),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, size: (16), color: item.color),
            ),
            SizedBox(width: (10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textMain,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.menudo.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: (10)),
            Text(
              amountLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: amountColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: share.clamp(0, 1),
            minHeight: 8,
            backgroundColor: context.menudo.surface,
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
          ),
        ),
      ],
    );
  }
}

class _BudgetExpenseBreakdownSeed {
  _BudgetExpenseBreakdownSeed({
    required this.label,
    required this.parentLabel,
    required this.icon,
    required this.color,
  });

  final String label;
  final String parentLabel;
  final IconData icon;
  final Color color;
  double total = 0;
  int count = 0;
}

class _BudgetExpenseBreakdownItem {
  const _BudgetExpenseBreakdownItem({
    required this.label,
    required this.parentLabel,
    required this.icon,
    required this.color,
    required this.total,
    required this.count,
  });

  final String label;
  final String parentLabel;
  final IconData icon;
  final Color color;
  final double total;
  final int count;
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SmallActionButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.menudo.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.menudo.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
