import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/menudo_loading_view.dart';
import '../../budgets/budget_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/transaction_presentation_utils.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';

enum _HistoryTypeFilter { all, expense, income, transfer }

enum _HistoryDateFilter { all, thisMonth, last30Days, custom }

String _formatHistoryMoney(double value, String currencyCode) {
  return formatMoney(value, currency: currencyCode);
}

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  _HistoryTypeFilter _typeFilter = _HistoryTypeFilter.all;
  _HistoryDateFilter _dateFilter = _HistoryDateFilter.thisMonth;
  DateTimeRange? _customRange;
  int? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  MenudoCategory? _findCategory(
    MenudoTransaction transaction,
    List<MenudoCategory> categories,
    Map<int, MenudoCategory> categoriesById,
  ) {
    if (transaction.categoryId != null) {
      return categoriesById[transaction.categoryId!];
    }

    final slug = transaction.catKey.trim();
    if (slug.isEmpty) return null;

    for (final category in categories) {
      if (category.slug == slug) return category;
    }

    return null;
  }

  DateTimeRange? _activeDateRange(DateTime now) {
    switch (_dateFilter) {
      case _HistoryDateFilter.all:
        return null;
      case _HistoryDateFilter.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case _HistoryDateFilter.last30Days:
        return DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 29)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case _HistoryDateFilter.custom:
        return _customRange;
    }
  }

  bool _matchesType(MenudoTransaction transaction) {
    return switch (_typeFilter) {
      _HistoryTypeFilter.expense => transaction.tipo == 'gasto',
      _HistoryTypeFilter.income => transaction.tipo == 'ingreso',
      _HistoryTypeFilter.transfer => transaction.tipo == 'transferencia',
      _HistoryTypeFilter.all => true,
    };
  }

  bool _matchesCategory(
    MenudoTransaction transaction,
    MenudoCategory? category,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null) return true;
    if (category == null) return false;
    if (category.id == selectedCategoryId) return true;
    return category.categoriaParadreId == selectedCategoryId ||
        categoriesById[category.categoriaParadreId]?.id == selectedCategoryId;
  }

  bool _matchesDateRange(MenudoTransaction transaction, DateTimeRange? range) {
    if (range == null) return true;
    final date = parseDateOnly(transaction.dateString);
    if (date == null) return false;
    final normalizedRange = normalizeDateRange(range);
    return !date.isBefore(normalizedRange.start) &&
        !date.isAfter(normalizedRange.end);
  }

  String _categoryPath(
    MenudoTransaction transaction,
    MenudoCategory? category,
    Map<int, MenudoCategory> categoriesById,
  ) {
    if (category == null) {
      final fallback = normalizedUiLabel(transaction.catKey);
      return fallback.isEmpty ? 'Sin categoría' : fallback;
    }

    final parent = category.categoriaParadreId == null
        ? null
        : categoriesById[category.categoriaParadreId];

    return joinDistinctUiLabels([
      distinctUiLabel(parent?.nombre, against: category.nombre),
      category.nombre,
    ]);
  }

  bool _matchesSearch(
    MenudoTransaction transaction,
    MenudoCategory? category,
    MenudoBudget? budget,
    Map<int, MenudoCategory> categoriesById,
  ) {
    final query = normalizedUiLabel(_searchQuery).toLowerCase();
    if (query.isEmpty) return true;

    final searchable = [
      transaction.desc,
      transaction.userName,
      budget?.nombre,
      _categoryPath(transaction, category, categoriesById),
      category?.nombre,
    ].map((value) => normalizedUiLabel(value).toLowerCase()).join(' ');

    return searchable.contains(query);
  }

  List<MenudoTransaction> _filteredTransactions(
    List<MenudoTransaction> transactions,
    List<MenudoCategory> categories,
    Map<int, MenudoCategory> categoriesById,
    Map<int, MenudoBudget> budgetsById,
    DateTime referenceDate,
  ) {
    final range = _activeDateRange(referenceDate);

    final filtered =
        transactions.where((transaction) {
          final category = _findCategory(
            transaction,
            categories,
            categoriesById,
          );
          final budget = transaction.budgetId == null
              ? null
              : budgetsById[transaction.budgetId!];

          return _matchesType(transaction) &&
              _matchesDateRange(transaction, range) &&
              _matchesCategory(transaction, category, categoriesById) &&
              _matchesSearch(transaction, category, budget, categoriesById);
        }).toList()..sort((a, b) {
          final left = parseDateOnly(a.dateString);
          final right = parseDateOnly(b.dateString);
          if (left == null && right == null) return 0;
          if (left == null) return 1;
          if (right == null) return -1;
          return right.compareTo(left);
        });

    return filtered;
  }

  Map<String, List<MenudoTransaction>> _groupTransactionsByDay(
    List<MenudoTransaction> transactions,
  ) {
    final grouped = <String, List<MenudoTransaction>>{};

    for (final transaction in transactions) {
      final date = parseDateOnly(transaction.dateString);
      if (date == null) continue;
      final key = _longDateLabel(date);
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    return grouped;
  }

  List<_HistoryBreakdownItem> _buildBreakdown(
    List<MenudoTransaction> transactions,
    List<MenudoCategory> categories,
    Map<int, MenudoCategory> categoriesById, {
    required String type,
  }) {
    final grouped = <String, _HistoryBreakdownSeed>{};

    for (final transaction in transactions) {
      if (transaction.tipo != type) continue;

      final category = _findCategory(transaction, categories, categoriesById);
      final key = category?.id.toString() ?? '$type:${transaction.catKey}';
      final label = category?.nombre ?? normalizedUiLabel(transaction.catKey);
      final parentLabel = category?.categoriaParadreId == null
          ? ''
          : distinctUiLabel(
              categoriesById[category!.categoriaParadreId!]?.nombre,
              against: category.nombre,
            );
      final seed =
          grouped[key] ??
          _HistoryBreakdownSeed(
            label: label.isEmpty ? 'Sin categoría' : label,
            parentLabel: parentLabel,
            icon: category?.icono ?? transaction.icono,
            color: category?.color ?? AppColors.g4,
          );

      seed.total += transaction.monto.abs();
      seed.count += 1;
      grouped[key] = seed;
    }

    final items =
        grouped.values
            .map(
              (seed) => _HistoryBreakdownItem(
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

  Future<void> _pickDateFilter() async {
    final nextFilter = await showModalBottomSheet<_HistoryDateFilter>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SelectionSheet<_HistoryDateFilter>(
          title: 'Filtrar por fecha',
          options: const [
            _SelectionOption(
              value: _HistoryDateFilter.thisMonth,
              title: 'Este mes',
            ),
            _SelectionOption(
              value: _HistoryDateFilter.last30Days,
              title: 'Últimos 30 días',
            ),
            _SelectionOption(value: _HistoryDateFilter.all, title: 'Todo'),
            _SelectionOption(
              value: _HistoryDateFilter.custom,
              title: 'Personalizado',
            ),
          ],
          selectedValue: _dateFilter,
        );
      },
    );

    if (!mounted || nextFilter == null) return;

    if (nextFilter == _HistoryDateFilter.custom) {
      final now = ref.read(transactionsReferenceDateProvider);
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1),
        initialDateRange:
            _customRange ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
        locale: Locale(
          AppFormattingPreferences.locale.languageCode,
          AppFormattingPreferences.locale.countryCode,
        ),
      );
      if (picked == null || !mounted) return;
      setState(() {
        _customRange = picked;
        _dateFilter = _HistoryDateFilter.custom;
      });
      return;
    }

    setState(() {
      _dateFilter = nextFilter;
      if (nextFilter != _HistoryDateFilter.custom) {
        _customRange = null;
      }
    });
  }

  Future<void> _pickCategoryFilter(List<MenudoCategory> categories) async {
    final sortedCategories = [...categories]
      ..sort((a, b) {
        final typeCompare = a.tipo.compareTo(b.tipo);
        if (typeCompare != 0) return typeCompare;
        final parentCompare = (a.categoriaParadreId ?? 0).compareTo(
          b.categoriaParadreId ?? 0,
        );
        if (parentCompare != 0) return parentCompare;
        return a.nombre.compareTo(b.nombre);
      });

    final picked = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _CategoryFilterSheet(
          categories: sortedCategories,
          selectedCategoryId: _selectedCategoryId,
        );
      },
    );

    if (!mounted) return;
    setState(() => _selectedCategoryId = picked);
  }

  String _dateFilterLabel() {
    return switch (_dateFilter) {
      _HistoryDateFilter.all => 'Todo',
      _HistoryDateFilter.thisMonth => 'Este mes',
      _HistoryDateFilter.last30Days => '30 días',
      _HistoryDateFilter.custom =>
        _customRange == null
            ? 'Personalizado'
            : '${_compactDate(_customRange!.start)} - ${_compactDate(_customRange!.end)}',
    };
  }

  String _longDateLabel(DateTime date) {
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
    return '${date.day} ${months[date.month] ?? date.month} ${date.year}';
  }

  String _compactDate(DateTime date) {
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
    return '${date.day} ${months[date.month] ?? date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(appPreferencesProvider).valueOrNull;
    final activeCurrency =
        preferences?.currencyCode ?? AppFormattingPreferences.currencyCode;
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final transactions = ref.watch(effectiveTransactionsProvider);
    final categories = ref.watch(effectiveCategoriesProvider);
    final wallets = ref.watch(effectiveWalletsProvider);
    final budgets = ref.watch(effectiveBudgetsProvider);
    final referenceDate = ref.watch(transactionsReferenceDateProvider);
    final categoriesById = {
      for (final category in categories) category.id: category,
    };
    final budgetsById = {for (final budget in budgets) budget.id: budget};

    final filteredTransactions = _filteredTransactions(
      transactions,
      categories,
      categoriesById,
      budgetsById,
      referenceDate,
    );
    final groupedTransactions = _groupTransactionsByDay(filteredTransactions);
    final totalIncome = filteredTransactions
        .where((transaction) => transaction.tipo == 'ingreso')
        .fold(0.0, (sum, transaction) => sum + transaction.monto.abs());
    final totalExpense = filteredTransactions
        .where((transaction) => transaction.tipo == 'gasto')
        .fold(0.0, (sum, transaction) => sum + transaction.monto.abs());
    final balance = totalIncome - totalExpense;
    final expenseBreakdown = _buildBreakdown(
      filteredTransactions,
      categories,
      categoriesById,
      type: 'gasto',
    );
    final incomeBreakdown = _buildBreakdown(
      filteredTransactions,
      categories,
      categoriesById,
      type: 'ingreso',
    );
    final selectedCategory = _selectedCategoryId == null
        ? null
        : categoriesById[_selectedCategoryId!];

    if (transactionsAsync.isLoading && transactions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.g0,
        body: MenudoLoadingView(
          title: 'Cargando historial',
          message: 'Estamos organizando tus movimientos recientes.',
          logoSize: 88,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.g0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 118,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppColors.e8),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                bottom: 16,
              ),
              centerTitle: false,
              title: const Text(
                'Historial',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e8,
                  letterSpacing: -0.8,
                ),
              ),
              background: Container(color: Colors.white),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HistorySearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ).animate().fadeIn(duration: 260.ms),
                  const SizedBox(height: 14),
                  _HistoryTypeFilters(
                    selectedFilter: _typeFilter,
                    onChanged: (filter) {
                      HapticFeedback.selectionClick();
                      setState(() => _typeFilter = filter);
                    },
                  ).animate().fadeIn(duration: 260.ms, delay: 40.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _HistoryActionChip(
                          icon: LucideIcons.calendarRange,
                          label: _dateFilterLabel(),
                          onTap: _pickDateFilter,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HistoryActionChip(
                          icon: LucideIcons.tags,
                          label: selectedCategory?.nombre ?? 'Categorías',
                          onTap: () => _pickCategoryFilter(categories),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 260.ms, delay: 80.ms),
                  if (filteredTransactions.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _HistoryOverviewCard(
                      balance: balance,
                      income: totalIncome,
                      expense: totalExpense,
                      currencyCode: activeCurrency,
                    ).animate().fadeIn(duration: 320.ms, delay: 120.ms),
                    if (expenseBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _HistoryBreakdownCard(
                        title: 'Gastos por categoría',
                        icon: LucideIcons.trendingDown,
                        accentColor: AppColors.o5,
                        totalLabel: _formatHistoryMoney(
                          totalExpense,
                          activeCurrency,
                        ),
                        items: expenseBreakdown,
                        currencyCode: activeCurrency,
                      ).animate().fadeIn(duration: 320.ms, delay: 180.ms),
                    ],
                    if (incomeBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _HistoryBreakdownCard(
                        title: 'Ingresos por categoría',
                        icon: LucideIcons.trendingUp,
                        accentColor: AppColors.e6,
                        totalLabel: _formatHistoryMoney(
                          totalIncome,
                          activeCurrency,
                        ),
                        items: incomeBreakdown,
                        currencyCode: activeCurrency,
                      ).animate().fadeIn(duration: 320.ms, delay: 220.ms),
                    ],
                    const SizedBox(height: 22),
                  ],
                ],
              ),
            ),
          ),
          if (groupedTransactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                child: _HistoryEmptyState(
                  hasTransactions: transactions.isNotEmpty,
                  hasFilters:
                      _typeFilter != _HistoryTypeFilter.all ||
                      _dateFilter != _HistoryDateFilter.thisMonth ||
                      _selectedCategoryId != null ||
                      normalizedUiLabel(_searchQuery).isNotEmpty,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final dateKey = groupedTransactions.keys.elementAt(index);
                  final dayTransactions = groupedTransactions[dateKey]!;
                  final dayIncome = dayTransactions
                      .where((transaction) => transaction.tipo == 'ingreso')
                      .fold(
                        0.0,
                        (sum, transaction) => sum + transaction.monto.abs(),
                      );
                  final dayExpense = dayTransactions
                      .where((transaction) => transaction.tipo == 'gasto')
                      .fold(
                        0.0,
                        (sum, transaction) => sum + transaction.monto.abs(),
                      );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _HistoryDaySection(
                      dateKey: dateKey,
                      income: dayIncome,
                      expense: dayExpense,
                      transactions: dayTransactions,
                      categories: categories,
                      categoriesById: categoriesById,
                      budgetsById: budgetsById,
                      wallets: wallets,
                      currencyCode: activeCurrency,
                    ),
                  ).animate().fadeIn(duration: 260.ms, delay: (index * 40).ms);
                }, childCount: groupedTransactions.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistorySearchField extends StatelessWidget {
  const _HistorySearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.g2),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar movimientos',
          prefixIcon: const Icon(LucideIcons.search, size: 18),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(LucideIcons.x, size: 16),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _HistoryTypeFilters extends StatelessWidget {
  const _HistoryTypeFilters({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _HistoryTypeFilter selectedFilter;
  final ValueChanged<_HistoryTypeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _HistoryTypeChip(
            label: 'Todo',
            selected: selectedFilter == _HistoryTypeFilter.all,
            onTap: () => onChanged(_HistoryTypeFilter.all),
          ),
          const SizedBox(width: 8),
          _HistoryTypeChip(
            label: 'Gastos',
            color: AppColors.o5,
            selected: selectedFilter == _HistoryTypeFilter.expense,
            onTap: () => onChanged(_HistoryTypeFilter.expense),
          ),
          const SizedBox(width: 8),
          _HistoryTypeChip(
            label: 'Ingresos',
            color: AppColors.e6,
            selected: selectedFilter == _HistoryTypeFilter.income,
            onTap: () => onChanged(_HistoryTypeFilter.income),
          ),
          const SizedBox(width: 8),
          _HistoryTypeChip(
            label: 'Transferencias',
            color: AppColors.b5,
            selected: selectedFilter == _HistoryTypeFilter.transfer,
            onTap: () => onChanged(_HistoryTypeFilter.transfer),
          ),
        ],
      ),
    );
  }
}

class _HistoryTypeChip extends StatelessWidget {
  const _HistoryTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.e8,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : AppColors.g2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? color : AppColors.g5,
          ),
        ),
      ),
    );
  }
}

class _HistoryActionChip extends StatelessWidget {
  const _HistoryActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.g2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.e8),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.e8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.g4),
          ],
        ),
      ),
    );
  }
}

class _HistoryOverviewCard extends StatelessWidget {
  const _HistoryOverviewCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.currencyCode,
  });

  final double balance;
  final double income;
  final double expense;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final balanceColor = balance >= 0 ? AppColors.e6 : AppColors.r5;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.g4,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatHistoryMoney(balance, currencyCode),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: balanceColor,
                letterSpacing: -1.1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.g2),
          const SizedBox(height: 14),
          _HistoryInlineMetric(
            label: 'Ingresos',
            value: _formatHistoryMoney(income, currencyCode),
            color: AppColors.e6,
          ),
          const SizedBox(height: 12),
          _HistoryInlineMetric(
            label: 'Gastos',
            value: _formatHistoryMoney(expense, currencyCode),
            color: AppColors.o5,
          ),
        ],
      ),
    );
  }
}

class _HistoryInlineMetric extends StatelessWidget {
  const _HistoryInlineMetric({
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.g5,
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
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryMicroStat extends StatelessWidget {
  const _HistoryMicroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.g4,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBreakdownCard extends StatelessWidget {
  const _HistoryBreakdownCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.totalLabel,
    required this.items,
    required this.currencyCode,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final String totalLabel;
  final List<_HistoryBreakdownItem> items;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                totalLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _BreakdownEmptyState()
          else
            ...items.take(4).toList().asMap().entries.map((entry) {
              final item = entry.value;
              final visibleCount = items.length < 4 ? items.length : 4;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == visibleCount - 1 ? 0 : 12,
                ),
                child: _BreakdownRow(
                  item: item,
                  accentColor: accentColor,
                  currencyCode: currencyCode,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _BreakdownEmptyState extends StatelessWidget {
  const _BreakdownEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Sin datos suficientes en esta vista.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.g4,
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.item,
    required this.accentColor,
    required this.currencyCode,
  });

  final _HistoryBreakdownItem item;
  final Color accentColor;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.e8,
                  ),
                ),
                Text(
                  joinDistinctUiLabels([
                    item.parentLabel,
                    '${item.count} mov.',
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.g4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatHistoryMoney(item.total, currencyCode),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    required this.hasTransactions,
    required this.hasFilters,
  });

  final bool hasTransactions;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final title = hasTransactions
        ? (hasFilters
              ? 'No hay movimientos con estos filtros'
              : 'Todavía no hay movimientos')
        : 'Todavía no hay movimientos';
    final body = hasTransactions
        ? 'Prueba otra fecha, categoría o tipo.'
        : 'Aquí verás tus ingresos, gastos y transferencias.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.g1,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.inbox, size: 30, color: AppColors.g4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.g5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDaySection extends StatelessWidget {
  const _HistoryDaySection({
    required this.dateKey,
    required this.income,
    required this.expense,
    required this.transactions,
    required this.categories,
    required this.categoriesById,
    required this.budgetsById,
    required this.wallets,
    required this.currencyCode,
  });

  final String dateKey;
  final double income;
  final double expense;
  final List<MenudoTransaction> transactions;
  final List<MenudoCategory> categories;
  final Map<int, MenudoCategory> categoriesById;
  final Map<int, MenudoBudget> budgetsById;
  final List<WalletAccount> wallets;
  final String currencyCode;

  MenudoCategory? _findCategory(MenudoTransaction transaction) {
    if (transaction.categoryId != null) {
      return categoriesById[transaction.categoryId!];
    }
    final slug = transaction.catKey.trim();
    if (slug.isEmpty) return null;

    for (final category in categories) {
      if (category.slug == slug) return category;
    }
    return null;
  }

  String _categoryPath(
    MenudoTransaction transaction,
    MenudoCategory? category,
  ) {
    if (category == null) {
      final fallback = normalizedUiLabel(transaction.catKey);
      return fallback.isEmpty ? 'Sin categoría' : fallback;
    }

    final parent = category.categoriaParadreId == null
        ? null
        : categoriesById[category.categoriaParadreId];

    return joinDistinctUiLabels([
      distinctUiLabel(parent?.nombre, against: category.nombre),
      category.nombre,
    ]);
  }

  String _parentLabel(MenudoCategory? category) {
    if (category == null || category.categoriaParadreId == null) return '';
    return normalizedUiLabel(
      categoriesById[category.categoriaParadreId]?.nombre,
    );
  }

  String _compactDate(MenudoTransaction transaction) {
    final date = parseDateOnly(transaction.dateString);
    if (date == null) return '';
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
    return '${date.day} ${months[date.month] ?? date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final net = income - expense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateKey,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.e8,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Text(
                    _formatHistoryMoney(net, currencyCode),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: net >= 0 ? AppColors.e6 : AppColors.r5,
                    ),
                  ),
                ],
              ),
              if (income > 0 || expense > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (income > 0)
                      _HistoryMicroStat(
                        label: 'Entró',
                        value: _formatHistoryMoney(income, currencyCode),
                        color: AppColors.e6,
                      ),
                    if (expense > 0)
                      _HistoryMicroStat(
                        label: 'Salió',
                        value: _formatHistoryMoney(expense, currencyCode),
                        color: AppColors.o5,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.g2),
          ),
          child: Column(
            children: List.generate(transactions.length, (index) {
              final transaction = transactions[index];
              final category = _findCategory(transaction);
              final budget = transaction.budgetId == null
                  ? null
                  : budgetsById[transaction.budgetId!];
              final presentation = buildTransactionPresentation(
                transaction,
                wallets,
              );
              final categoryPath = _categoryPath(transaction, category);
              final title = distinctUiLabel(
                transaction.desc,
                against: transaction.tipo == 'transferencia'
                    ? presentation.routeLabel
                    : categoryPath,
              );
              final parentLabel = _parentLabel(category);
              final subtitle = transaction.tipo == 'transferencia'
                  ? joinDistinctUiLabels([
                      presentation.routeLabel,
                      _compactDate(transaction),
                      budget?.nombre,
                      transaction.userName,
                    ])
                  : joinDistinctUiLabels([
                      distinctUiLabel(parentLabel, against: title),
                      _compactDate(transaction),
                      budget?.nombre,
                      transaction.userName,
                    ]);

              return _HistoryTransactionTile(
                transaction: transaction,
                title: title.isEmpty
                    ? (transaction.tipo == 'transferencia'
                          ? presentation.routeLabel
                          : categoryPath)
                    : title,
                subtitle: subtitle,
                icon: category?.icono ?? transaction.icono,
                color: transaction.tipo == 'ingreso'
                    ? AppColors.e6
                    : transaction.tipo == 'transferencia'
                    ? AppColors.b5
                    : (category?.color ?? AppColors.o5),
                amountColor: transaction.tipo == 'ingreso'
                    ? AppColors.e6
                    : transaction.tipo == 'transferencia'
                    ? AppColors.b5
                    : AppColors.e8,
                amount: _formatHistoryMoney(
                  transaction.monto.abs(),
                  currencyCode,
                ),
                prefix: presentation.prefix,
                isLast: index == transactions.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _HistoryTransactionTile extends StatelessWidget {
  const _HistoryTransactionTile({
    required this.transaction,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.amountColor,
    required this.amount,
    required this.prefix,
    required this.isLast,
  });

  final MenudoTransaction transaction;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color amountColor;
  final String amount;
  final String prefix;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => TransactionDetailSheet(transaction: transaction),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.e8,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.g4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      prefix.isEmpty ? amount : '$prefix$amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: amountColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              color: AppColors.g1,
              indent: 68,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
}

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<_SelectionOption<T>> options;
  final T selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.g2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 14),
              ...options.map((option) {
                final selected = option.value == selectedValue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(option.value),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.e8.withValues(alpha: 0.08)
                            : AppColors.g0,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? AppColors.e8 : AppColors.g2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: selected ? AppColors.e8 : AppColors.g5,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              LucideIcons.check,
                              size: 16,
                              color: AppColors.e8,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({
    required this.categories,
    required this.selectedCategoryId,
  });

  final List<MenudoCategory> categories;
  final int? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.g2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filtrar por categoría',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.62,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _CategoryFilterRow(
                      title: 'Todas las categorías',
                      subtitle: 'Quita este filtro',
                      selected: selectedCategoryId == null,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                    const SizedBox(height: 10),
                    ...categories.map((category) {
                      final parent = category.categoriaParadreId == null
                          ? null
                          : categoriesById[category.categoriaParadreId];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CategoryFilterRow(
                          title: category.nombre,
                          subtitle: joinDistinctUiLabels([
                            distinctUiLabel(
                              parent?.nombre,
                              against: category.nombre,
                            ),
                            category.tipo,
                          ]),
                          selected: selectedCategoryId == category.id,
                          icon: category.icono,
                          color: category.color,
                          onTap: () => Navigator.of(context).pop(category.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.icon = LucideIcons.tags,
    this.color = AppColors.e8,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.g0,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : AppColors.g2),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: selected ? color : AppColors.e8,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.g4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected) Icon(LucideIcons.check, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

class _SelectionOption<T> {
  const _SelectionOption({required this.value, required this.title});

  final T value;
  final String title;
}

class _HistoryBreakdownSeed {
  _HistoryBreakdownSeed({
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

class _HistoryBreakdownItem {
  const _HistoryBreakdownItem({
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
