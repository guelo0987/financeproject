import 'package:financeproject/core/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key, required this.demoMode});

  final bool demoMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.e1,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.square_grid_2x2_fill,
                      color: context.menudo.textMain,
                      size: (28),
                    ),
                  ),
                  SizedBox(height: (16)),
                  Text(
                    'Todavía no hay actividad.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colors.textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    demoMode
                        ? 'Esta cuenta todavía no tiene movimientos reales.'
                        : 'Agrega una cuenta y registra tu primer movimiento para ver el resumen aquí.',
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: (18)),
                  FilledButton(
                    onPressed: () => context.push('/wallet'),
                    child: Text('Ir a cuentas'),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/settings'),
                    child: Text('Ir a ajustes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
