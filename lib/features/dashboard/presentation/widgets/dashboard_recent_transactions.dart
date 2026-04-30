import 'package:financeproject/core/data/models.dart';
import 'package:financeproject/core/theme/app_colors.dart';
import 'package:financeproject/core/theme/app_spacing.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:financeproject/features/transactions/presentation/transaction_detail_sheet.dart';
import 'package:financeproject/features/transactions/presentation/transaction_presentation_utils.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter/material.dart';

class DashboardRecentTransactions extends StatelessWidget {
  const DashboardRecentTransactions({
    super.key,
    required this.recent,
    required this.currencyCode,
  });

  final List<MenudoTransaction> recent;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.p20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Text(
          'Todavía no hay movimientos recientes.',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        children: List.generate(recent.length, (i) {
          final t = recent[i];
          final color = _transactionColor(t);
          return _TransactionTile(
            transaction: t,
            subtitle: _buildRecentSubtitle(t, _transactionCategoryLabel(t)),
            color: color,
            currencyCode: currencyCode,
            isLast: i == recent.length - 1,
            onTap: () {
              MenudoHaptics.light();
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TransactionDetailSheet(transaction: t),
              );
            },
          );
        }),
      ),
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: colors.textMain,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (trailing != null) ...[SizedBox(width: AppSpacing.p12), trailing!],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.subtitle,
    required this.color,
    required this.currencyCode,
    required this.isLast,
    required this.onTap,
  });

  final MenudoTransaction transaction;
  final String subtitle;
  final Color color;
  final String currencyCode;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final amountLabel = formatTransactionAmountLabel(
      transaction,
      currencyCode: currencyCode,
    );
    final amountColor = switch (transaction.tipo) {
      'ingreso' => AppColors.e6,
      'gasto' => AppColors.o5,
      _ => colors.textMain,
    };

    return Semantics(
      button: true,
      label: '${transaction.desc}, $amountLabel',
      child: MenudoGestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.p16,
                vertical: AppSpacing.p14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(transaction.icono, size: (20), color: color),
                  ),
                  SizedBox(width: AppSpacing.p14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.desc,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.p2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.p12),
                  Text(
                    amountLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                thickness: 0.5,
                color: colors.divider,
                indent: 74,
                endIndent: 16,
              ),
          ],
        ),
      ),
    );
  }
}

Color _transactionColor(MenudoTransaction transaction) {
  return switch (transaction.tipo) {
    'ingreso' => AppColors.e6,
    'transferencia' => AppColors.b5,
    _ => AppColors.o5,
  };
}

String _transactionCategoryLabel(MenudoTransaction transaction) {
  if (transaction.tipo == 'transferencia') return 'Transferencia';
  if (transaction.catKey.trim().isEmpty) return 'Movimiento';

  return transaction.catKey
      .split(RegExp(r'[_-]+'))
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            '${segment.substring(0, 1).toUpperCase()}${segment.substring(1)}',
      )
      .join(' ');
}

String _buildRecentSubtitle(
  MenudoTransaction transaction,
  String categoryName,
) {
  final normalizedCategory = categoryName.trim();
  final normalizedDesc = transaction.desc.trim();
  final date = _compactDate(transaction.dateString);
  if (normalizedCategory.isEmpty) return date;
  if (normalizedCategory.toLowerCase() == normalizedDesc.toLowerCase()) {
    return date;
  }
  return '$normalizedCategory · $date';
}

String _compactDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  const months = {
    '01': 'ene',
    '02': 'feb',
    '03': 'mar',
    '04': 'abr',
    '05': 'may',
    '06': 'jun',
    '07': 'jul',
    '08': 'ago',
    '09': 'sep',
    '10': 'oct',
    '11': 'nov',
    '12': 'dic',
  };
  return '${int.tryParse(parts[2]) ?? parts[2]} ${months[parts[1]] ?? parts[1]}';
}
