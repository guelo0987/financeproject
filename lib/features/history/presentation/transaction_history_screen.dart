import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/data/models.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'Todos';
  
  static const _filters = ['Todos', 'Entradas', 'Salidas'];

  List<Transaction> get _filteredTransactions {
    final all = MockData.recentTransactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort newest first
      
    if (_selectedFilter == 'Todos') return all;
    final type = _selectedFilter == 'Entradas' 
        ? TransactionType.income 
        : TransactionType.expense;
        
    return all.where((t) => t.type == type).toList();
  }

  // Grupos por fecha
  Map<String, List<Transaction>> get _groupedTransactions {
    final Map<String, List<Transaction>> groups = {};
    final formatter = DateFormat('EEEE d MMM', 'es');

    for (final t in _filteredTransactions) {
      String dateStr = formatter.format(t.date);
      // Simplify logic for demo, capitalizing first letter
      dateStr = dateStr[0].toUpperCase() + dateStr.substring(1);
      
      if (!groups.containsKey(dateStr)) {
        groups[dateStr] = [];
      }
      groups[dateStr]!.add(t);
    }
    return groups;
  }

  double get _totalIncome => MockData.recentTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (s, t) => s + t.amount);
      
  double get _totalExpense => MockData.recentTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupedTransactions;
    final formatter = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historial', style: AppTextStyles.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    'Revisa tus movimientos financieros',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
            
            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentSurface
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected ? AppColors.accent : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ),
            
            const SizedBox(height: 16),
            
            // Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                   Expanded(
                    child: _SummaryBox(
                      title: 'Entradas',
                      amount: formatter.format(_totalIncome),
                      color: AppColors.positive,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryBox(
                      title: 'Salidas',
                      amount: formatter.format(_totalExpense),
                      color: AppColors.negative,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: groupedTransactions.length,
                itemBuilder: (context, index) {
                  final date = groupedTransactions.keys.elementAt(index);
                  final transactions = groupedTransactions[date]!;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            children: transactions.map((t) => _TransactionItem(transaction: t)).toList(),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: (250 + 50 * index).ms).slideY(begin: 0.05);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$ $amount',
            style: AppTextStyles.cardValue.copyWith(fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.positive : AppColors.textPrimary;
    final prefix = isIncome ? '+' : '-';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        collapsedIconColor: AppColors.textTertiary,
        iconColor: AppColors.accentBright,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(transaction.icon, size: 20, color: AppColors.textSecondary),
        ),
        title: Text(
          transaction.description,
          style: AppTextStyles.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          transaction.category,
          style: AppTextStyles.bodySmall,
        ),
        trailing: Text(
          '$prefix RD\$ ${formatter.format(transaction.amount)}',
          style: AppTextStyles.labelLarge.copyWith(color: color),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cuenta', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        transaction.assetName ?? 'Desconocida',
                        style: AppTextStyles.labelMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM/yyyy', 'es').format(transaction.date),
                        style: AppTextStyles.labelMedium,
                      ),
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
}
