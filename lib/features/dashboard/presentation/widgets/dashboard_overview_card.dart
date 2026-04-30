import 'package:financeproject/core/theme/app_colors.dart';
import 'package:financeproject/core/theme/app_spacing.dart';
import 'package:financeproject/core/utils/formatters.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';

class DashboardOverviewCard extends StatelessWidget {
  const DashboardOverviewCard({
    super.key,
    required this.accountLabel,
    required this.availableNow,
    required this.monthBalance,
    required this.incomeThisMonth,
    required this.spentThisMonth,
    required this.currencyCode,
    required this.onWalletTap,
  });

  final String accountLabel;
  final double availableNow;
  final double monthBalance;
  final double incomeThisMonth;
  final double spentThisMonth;
  final String currencyCode;
  final VoidCallback onWalletTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final monthPositive = monthBalance >= 0;
    final monthLabel = monthPositive
        ? 'Balance del mes +${formatMoney(monthBalance.abs(), currency: currencyCode)}'
        : 'Balance del mes -${formatMoney(monthBalance.abs(), currency: currencyCode)}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        color: colors.hero,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.hero.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.p10,
                    vertical: AppSpacing.p6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.creditcard_fill,
                        size: (12),
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                      SizedBox(width: AppSpacing.p6),
                      Flexible(
                        child: Text(
                          accountLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Ver cuentas',
                child: MenudoGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onWalletTap,
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    color: Colors.white.withValues(alpha: 0.86),
                    size: (18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p18),
          Text(
            'Disponible ahora',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: AppSpacing.p6),
          SizedBox(
            height: 52,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(availableNow, currency: currencyCode),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.p6),
          Text(
            monthLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: monthPositive
                  ? Colors.white.withValues(alpha: 0.84)
                  : const Color(0xFFFFD8AE),
            ),
          ),
          const SizedBox(height: AppSpacing.p14),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: AppSpacing.p14),
          Row(
            children: [
              Expanded(
                child: _BudgetMetaPill(
                  label: 'Ingresos del mes',
                  value: formatMoney(incomeThisMonth, currency: currencyCode),
                ),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: _BudgetMetaPill(
                  label: 'Gastos del mes',
                  value: formatMoney(spentThisMonth, currency: currencyCode),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetMetaPill extends StatelessWidget {
  const _BudgetMetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.p14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.52),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.p6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
