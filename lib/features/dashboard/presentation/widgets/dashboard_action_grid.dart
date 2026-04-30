import 'package:financeproject/core/theme/app_colors.dart';
import 'package:financeproject/core/theme/app_spacing.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';

class DashboardActionGrid extends StatelessWidget {
  const DashboardActionGrid({
    super.key,
    required this.onIncomeTap,
    required this.onExpenseTap,
    required this.onTransferTap,
    required this.onMoreTap,
  });

  final VoidCallback onIncomeTap;
  final VoidCallback onExpenseTap;
  final VoidCallback onTransferTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final actions = [
      (
        icon: CupertinoIcons.arrow_down_left,
        label: 'Ingreso',
        color: colors.success,
        bgColor: colors.successLight,
        onTap: onIncomeTap,
      ),
      (
        icon: CupertinoIcons.arrow_up_right,
        label: 'Gasto',
        color: colors.primary,
        bgColor: colors.primaryLight,
        onTap: onExpenseTap,
      ),
      (
        icon: CupertinoIcons.arrow_2_squarepath,
        label: 'Transferir',
        color: AppColors.b5,
        bgColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF13233D)
            : const Color(0xFFDBEAFE),
        onTap: onTransferTap,
      ),
      (
        icon: CupertinoIcons.square_grid_2x2_fill,
        label: 'Más',
        color: colors.textSecondary,
        bgColor: colors.surfaceElevated,
        onTap: onMoreTap,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(
            child: _QuickAction(
              icon: actions[i].icon,
              label: actions[i].label,
              color: actions[i].color,
              bgColor: actions[i].bgColor,
              onTap: actions[i].onTap,
            ),
          ),
          if (i != actions.length - 1) SizedBox(width: AppSpacing.p10),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Semantics(
      button: true,
      label: label,
      child: MenudoGestureDetector(
        onTap: () {
          MenudoHaptics.light();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.p2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: (18), color: color),
              ),
              SizedBox(height: AppSpacing.p8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
