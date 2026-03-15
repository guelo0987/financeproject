import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../budgets/budget_providers.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/transaction_presentation_utils.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../providers/category_providers.dart';

class SpendingCategoriesScreen extends ConsumerStatefulWidget {
  const SpendingCategoriesScreen({super.key});

  @override
  ConsumerState<SpendingCategoriesScreen> createState() =>
      _SpendingCategoriesScreenState();
}

class _SpendingCategoriesScreenState
    extends ConsumerState<SpendingCategoriesScreen> {
  String _selectedType = 'gasto';
  String? _expandedParentKey;
  final Set<String> _expandedSubKeys = <String>{};

  static const _months = [
    '',
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

  String _fmtMoney(double value, {String currency = 'DOP'}) {
    final prefix = currency == 'USD' ? 'US\$' : 'RD\$';
    return '$prefix${_fmtNumber(value.round())}';
  }

  String _fmtNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _compactDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return value;
    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    return '$day ${_months[month.clamp(0, 12)]}';
  }

  String _humanizeKey(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Sin categoría';
    final separated = normalized
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-záéíóúñ])([A-ZÁÉÍÓÚÑ])'),
          (match) => '${match[1]} ${match[2]}',
        );
    return separated[0].toUpperCase() + separated.substring(1);
  }

  int _compareTransactions(MenudoTransaction a, MenudoTransaction b) {
    final aDate = DateTime.tryParse(a.dateString);
    final bDate = DateTime.tryParse(b.dateString);
    if (aDate == null && bDate == null) {
      return b.id.compareTo(a.id);
    }
    if (aDate == null) return 1;
    if (bDate == null) return -1;

    final dateCompare = bDate.compareTo(aDate);
    if (dateCompare != 0) return dateCompare;
    return b.id.compareTo(a.id);
  }

  Color _accentColorFor(String type) {
    return type == 'ingreso' ? AppColors.e6 : AppColors.o5;
  }

  String _sectionTitleFor(String type) {
    return type == 'ingreso' ? 'Ingresos' : 'Gastos';
  }

  String _sectionVerbFor(String type) {
    return type == 'ingreso' ? 'ingresado' : 'gastado';
  }

  String _movementLabelFor(String type) {
    return type == 'ingreso' ? 'ingresos' : 'gastos';
  }

  String _periodLabel(MenudoBudget? budget) {
    final period = budget?.periodo.toLowerCase();
    return switch (period) {
      'mensual' => 'este mes',
      'quincenal' => 'esta quincena',
      'semanal' => 'esta semana',
      'unico' => 'este periodo',
      _ => 'este periodo',
    };
  }

  List<_ParentCategoryGroup> _buildGroups(
    List<MenudoTransaction> transactions,
    List<MenudoCategory> categories,
    String selectedType,
  ) {
    final categoriesBySlug = {
      for (final category in categories) category.slug: category,
    };
    final categoriesById = {
      for (final category in categories) category.id: category,
    };
    final buckets = <String, _ParentCategoryAccumulator>{};

    for (final transaction in transactions.where(
      (item) => item.tipo == selectedType,
    )) {
      final resolvedCategory =
          categoriesBySlug[transaction.catKey] ??
          (transaction.categoryId != null
              ? categoriesById[transaction.categoryId!]
              : null);
      final parentCategory = switch (resolvedCategory) {
        null => null,
        MenudoCategory category when category.categoriaParadreId == null =>
          category,
        MenudoCategory category => categoriesById[category.categoriaParadreId!],
      };

      final parentKey = parentCategory?.slug.isNotEmpty == true
          ? parentCategory!.slug
          : resolvedCategory?.slug.isNotEmpty == true
          ? resolvedCategory!.slug
          : transaction.catKey.isNotEmpty
          ? transaction.catKey
          : 'sin-categoria';

      final parentLabel =
          parentCategory?.nombre ??
          resolvedCategory?.nombre ??
          _humanizeKey(transaction.catKey);
      final parentIcon =
          parentCategory?.icono ??
          resolvedCategory?.icono ??
          LucideIcons.layoutGrid;
      final parentColor =
          parentCategory?.color ?? resolvedCategory?.color ?? AppColors.g4;

      final isSubcategory = resolvedCategory?.categoriaParadreId != null;
      final subKey = isSubcategory
          ? resolvedCategory!.slug
          : '${parentKey}_directo';
      final subLabel = isSubcategory
          ? resolvedCategory!.nombre
          : 'Sin subcategoría';
      final subIcon = isSubcategory
          ? resolvedCategory!.icono
          : LucideIcons.chevronRight;
      final subColor = isSubcategory
          ? resolvedCategory!.color
          : parentColor.withValues(alpha: 0.85);

      final bucket = buckets.putIfAbsent(
        parentKey,
        () => _ParentCategoryAccumulator(
          key: parentKey,
          category: parentCategory ?? resolvedCategory,
          label: parentLabel,
          icon: parentIcon,
          color: parentColor,
        ),
      );

      bucket.transactions.add(transaction);
      final child = bucket.children.putIfAbsent(
        subKey,
        () => _SubcategoryAccumulator(
          key: subKey,
          category: isSubcategory ? resolvedCategory : null,
          parentCategory: parentCategory ?? resolvedCategory,
          label: subLabel,
          icon: subIcon,
          color: subColor,
          isDirectParentEntry: !isSubcategory,
        ),
      );
      child.transactions.add(transaction);
    }

    final groups = buckets.values.map((bucket) => bucket.build()).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    for (final group in groups) {
      group.transactions.sort(_compareTransactions);
      for (final child in group.subcategories) {
        child.transactions.sort(_compareTransactions);
      }
    }

    return groups;
  }

  void _toggleParent(String key) {
    setState(() {
      if (_expandedParentKey == key) {
        _expandedParentKey = null;
        _expandedSubKeys.removeWhere((entry) => entry.startsWith('$key::'));
      } else {
        _expandedParentKey = key;
      }
    });
  }

  void _toggleSub(String key) {
    setState(() {
      if (_expandedSubKeys.contains(key)) {
        _expandedSubKeys.remove(key);
      } else {
        _expandedSubKeys.add(key);
      }
    });
  }

  void _changeType(String type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      _expandedParentKey = null;
      _expandedSubKeys.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(selectedBudgetProvider);
    final categories = ref.watch(effectiveCategoriesProvider);
    final wallets = ref.watch(effectiveWalletsProvider);
    final periodTransactions = ref.watch(
      selectedBudgetPeriodTransactionsProvider,
    );
    final filtered = periodTransactions
        .where((transaction) => transaction.tipo == _selectedType)
        .toList();
    final groups = _buildGroups(filtered, categories, _selectedType);
    final total = filtered.fold<double>(
      0,
      (sum, transaction) => sum + transaction.monto.abs(),
    );
    final activeSubcategories = groups.fold<int>(
      0,
      (sum, group) => sum + group.subcategories.length,
    );
    final topGroup = groups.isEmpty ? null : groups.first;
    final periodLabel = _periodLabel(budget);
    final accentColor = _accentColorFor(_selectedType);
    final sectionTitle = _sectionTitleFor(_selectedType);
    final sectionVerb = _sectionVerbFor(_selectedType);
    final movementLabel = _movementLabelFor(_selectedType);

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.e8),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Categorías',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.e8,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          _TypeSwitcher(
            selectedType: _selectedType,
            onChanged: _changeType,
          ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.03, end: 0),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _EmptyBreakdownState(
              title: sectionTitle,
              periodLabel: periodLabel,
              movementLabel: movementLabel,
            ).animate().fadeIn(duration: 220.ms)
          else ...[
            _BreakdownOverviewCard(
              title: sectionTitle,
              periodLabel: periodLabel,
              totalLabel: _fmtMoney(total),
              accentColor: accentColor,
              summary: topGroup == null
                  ? 'Todavía no hay una categoría principal.'
                  : 'Mayor peso en ${topGroup.label.toLowerCase()}.',
              stats: [
                _OverviewStat(
                  label: 'Grupos',
                  value: _fmtNumber(groups.length),
                ),
                _OverviewStat(
                  label: 'Subcategorías',
                  value: _fmtNumber(activeSubcategories),
                ),
                _OverviewStat(
                  label:
                      movementLabel[0].toUpperCase() +
                      movementLabel.substring(1),
                  value: _fmtNumber(filtered.length),
                ),
              ],
              legend: groups.take(3).map((group) {
                final share = total == 0
                    ? 0
                    : (group.total / total * 100).round();
                return _LegendItem(
                  label: group.label,
                  value: '$share%',
                  color: group.color,
                );
              }).toList(),
              footer:
                  '${sectionVerb[0].toUpperCase()}${sectionVerb.substring(1)} $periodLabel',
            ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.03, end: 0),
            const SizedBox(height: 24),
            Text(
              '$sectionTitle por categoría',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.e8,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Padre, subcategoría y movimientos en una sola vista.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.g5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < groups.length; index++) ...[
              _ParentCategoryCard(
                    group: groups[index],
                    total: total,
                    selectedType: _selectedType,
                    countFormatter: _fmtNumber,
                    moneyFormatter: _fmtMoney,
                    dateFormatter: _compactDate,
                    expanded: _expandedParentKey == groups[index].key,
                    expandedSubKeys: _expandedSubKeys,
                    wallets: wallets,
                    onTap: () => _toggleParent(groups[index].key),
                    onSubTap: _toggleSub,
                  )
                  .animate()
                  .fadeIn(delay: (index * 45).ms, duration: 260.ms)
                  .slideY(begin: 0.03, end: 0),
              if (index != groups.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _TypeSwitcher extends StatelessWidget {
  const _TypeSwitcher({required this.selectedType, required this.onChanged});

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.g2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeOption(
              label: 'Gastos',
              selected: selectedType == 'gasto',
              selectedColor: AppColors.o5,
              selectedBackground: AppColors.o1,
              onTap: () => onChanged('gasto'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TypeOption(
              label: 'Ingresos',
              selected: selectedType == 'ingreso',
              selectedColor: AppColors.e6,
              selectedBackground: AppColors.e1,
              onTap: () => onChanged('ingreso'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedBackground,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedBackground : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: selected ? selectedColor : AppColors.g5,
          ),
        ),
      ),
    );
  }
}

class _BreakdownOverviewCard extends StatelessWidget {
  const _BreakdownOverviewCard({
    required this.title,
    required this.periodLabel,
    required this.totalLabel,
    required this.accentColor,
    required this.summary,
    required this.stats,
    required this.legend,
    required this.footer,
  });

  final String title;
  final String periodLabel;
  final String totalLabel;
  final Color accentColor;
  final String summary;
  final List<_OverviewStat> stats;
  final List<_LegendItem> legend;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$title $periodLabel',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.g5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalLabel,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.g5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: stats
                .map(
                  (stat) => Expanded(
                    child: _StatBlock(label: stat.label, value: stat.value),
                  ),
                )
                .toList(),
          ),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: legend
                  .map(
                    (item) => _LegendBadge(
                      label: item.label,
                      value: item.value,
                      color: item.color,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            footer,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentCategoryCard extends StatelessWidget {
  const _ParentCategoryCard({
    required this.group,
    required this.total,
    required this.selectedType,
    required this.countFormatter,
    required this.moneyFormatter,
    required this.dateFormatter,
    required this.expanded,
    required this.expandedSubKeys,
    required this.wallets,
    required this.onTap,
    required this.onSubTap,
  });

  final _ParentCategoryGroup group;
  final double total;
  final String selectedType;
  final String Function(int value) countFormatter;
  final String Function(double value, {String currency}) moneyFormatter;
  final String Function(String value) dateFormatter;
  final bool expanded;
  final Set<String> expandedSubKeys;
  final List<WalletAccount> wallets;
  final VoidCallback onTap;
  final ValueChanged<String> onSubTap;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0 : (group.total / total * 100).round();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: expanded ? group.color.withValues(alpha: 0.32) : AppColors.g2,
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: group.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: Icon(group.icon, size: 21, color: group.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.e8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${countFormatter(group.subcategories.length)} subcategorías · ${countFormatter(group.transactions.length)} movimientos',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.g5,
                                fontWeight: FontWeight.w600,
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
                            moneyFormatter(group.total),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.e8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$share%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: group.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        expanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.g4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: AppColors.g1,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: total == 0 ? 0 : group.total / total,
                        child: Container(color: group.color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: group.subcategories.map((subcategory) {
                        final subKey = '${group.key}::${subcategory.key}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _SubcategoryCard(
                            subcategory: subcategory,
                            parentTotal: group.total,
                            selectedType: selectedType,
                            countFormatter: countFormatter,
                            moneyFormatter: moneyFormatter,
                            dateFormatter: dateFormatter,
                            wallets: wallets,
                            expanded: expandedSubKeys.contains(subKey),
                            onTap: () => onSubTap(subKey),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  const _SubcategoryCard({
    required this.subcategory,
    required this.parentTotal,
    required this.selectedType,
    required this.countFormatter,
    required this.moneyFormatter,
    required this.dateFormatter,
    required this.wallets,
    required this.expanded,
    required this.onTap,
  });

  final _SubcategoryGroup subcategory;
  final double parentTotal;
  final String selectedType;
  final String Function(int value) countFormatter;
  final String Function(double value, {String currency}) moneyFormatter;
  final String Function(String value) dateFormatter;
  final List<WalletAccount> wallets;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final share = parentTotal == 0
        ? 0
        : (subcategory.total / parentTotal * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expanded
              ? subcategory.color.withValues(alpha: 0.28)
              : AppColors.g2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: subcategory.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      subcategory.icon,
                      size: 18,
                      color: subcategory.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subcategory.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.e8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subcategory.isDirectParentEntry
                              ? 'Registrado directo en la categoría padre'
                              : '${countFormatter(subcategory.transactions.length)} movimientos · $share% del grupo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.g5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    moneyFormatter(subcategory.total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.e8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: AppColors.g4,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      children: subcategory.transactions.map((transaction) {
                        final wallet = selectedType == 'ingreso'
                            ? resolveTransactionWallet(
                                wallets,
                                transaction.toAccountId ??
                                    transaction.fromAccountId,
                                transaction.toWallet ?? transaction.fromWallet,
                              )
                            : resolveTransactionWallet(
                                wallets,
                                transaction.fromAccountId,
                                transaction.fromWallet,
                              );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _MovementTile(
                            transaction: transaction,
                            selectedType: selectedType,
                            dateLabel: dateFormatter(transaction.dateString),
                            walletLabel: wallet?.nombre,
                            color: subcategory.color,
                            moneyFormatter: moneyFormatter,
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.transaction,
    required this.selectedType,
    required this.dateLabel,
    required this.walletLabel,
    required this.color,
    required this.moneyFormatter,
  });

  final MenudoTransaction transaction;
  final String selectedType;
  final String dateLabel;
  final String? walletLabel;
  final Color color;
  final String Function(double value, {String currency}) moneyFormatter;

  @override
  Widget build(BuildContext context) {
    final amountPrefix = selectedType == 'ingreso' ? '+' : '-';
    final amountColor = selectedType == 'ingreso' ? AppColors.e6 : AppColors.e8;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => TransactionDetailSheet(transaction: transaction),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(transaction.icono, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.e8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.g5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (walletLabel != null && walletLabel!.trim().isNotEmpty)
                        Flexible(
                          child: Text(
                            ' · $walletLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.g5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$amountPrefix ${moneyFormatter(transaction.monto.abs(), currency: transaction.moneda)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBreakdownState extends StatelessWidget {
  const _EmptyBreakdownState({
    required this.title,
    required this.periodLabel,
    required this.movementLabel,
  });

  final String title;
  final String periodLabel;
  final String movementLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.e0,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.layoutGrid,
              size: 24,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sin $title para mostrar',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando registres $movementLabel $periodLabel, verás su categoría padre, subcategoría y movimientos aquí.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.g5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.e8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.g5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendBadge extends StatelessWidget {
  const _LegendBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.e8,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _LegendItem {
  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class _ParentCategoryAccumulator {
  _ParentCategoryAccumulator({
    required this.key,
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String key;
  final MenudoCategory? category;
  final String label;
  final IconData icon;
  final Color color;
  final List<MenudoTransaction> transactions = <MenudoTransaction>[];
  final Map<String, _SubcategoryAccumulator> children =
      <String, _SubcategoryAccumulator>{};

  _ParentCategoryGroup build() {
    final subcategories = children.values.map((child) => child.build()).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return _ParentCategoryGroup(
      key: key,
      category: category,
      label: label,
      icon: icon,
      color: color,
      transactions: List<MenudoTransaction>.from(transactions),
      subcategories: subcategories,
    );
  }
}

class _SubcategoryAccumulator {
  _SubcategoryAccumulator({
    required this.key,
    required this.category,
    required this.parentCategory,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDirectParentEntry,
  });

  final String key;
  final MenudoCategory? category;
  final MenudoCategory? parentCategory;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDirectParentEntry;
  final List<MenudoTransaction> transactions = <MenudoTransaction>[];

  _SubcategoryGroup build() {
    final items = List<MenudoTransaction>.from(transactions);
    return _SubcategoryGroup(
      key: key,
      category: category,
      parentCategory: parentCategory,
      label: label,
      icon: icon,
      color: color,
      isDirectParentEntry: isDirectParentEntry,
      transactions: items,
    );
  }
}

class _ParentCategoryGroup {
  _ParentCategoryGroup({
    required this.key,
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
    required this.transactions,
    required this.subcategories,
  });

  final String key;
  final MenudoCategory? category;
  final String label;
  final IconData icon;
  final Color color;
  final List<MenudoTransaction> transactions;
  final List<_SubcategoryGroup> subcategories;

  double get total => transactions.fold<double>(
    0,
    (sum, transaction) => sum + transaction.monto.abs(),
  );
}

class _SubcategoryGroup {
  _SubcategoryGroup({
    required this.key,
    required this.category,
    required this.parentCategory,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDirectParentEntry,
    required this.transactions,
  });

  final String key;
  final MenudoCategory? category;
  final MenudoCategory? parentCategory;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDirectParentEntry;
  final List<MenudoTransaction> transactions;

  double get total => transactions.fold<double>(
    0,
    (sum, transaction) => sum + transaction.monto.abs(),
  );
}
