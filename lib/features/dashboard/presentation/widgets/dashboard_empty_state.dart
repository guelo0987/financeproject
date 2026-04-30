import 'package:financeproject/core/theme/app_colors.dart';
import 'package:financeproject/core/theme/app_spacing.dart';
import 'package:financeproject/shared/widgets/menudo_button.dart';
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
            padding: const EdgeInsets.all(AppSpacing.p24),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.p24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ClayWalletIllustration(),
                  SizedBox(height: AppSpacing.p20),
                  Text(
                    'Tu tablero está listo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.textMain,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.p8),
                  Text(
                    demoMode
                        ? 'Cuando agregues movimientos reales, Menudo empezará a ordenar tu historia financiera aquí.'
                        : 'Crea tu primera cuenta y el resumen empezará a tomar forma con cada movimiento.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textMuted,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.p20),
                  MenudoButton(
                    label: 'Crear primera cuenta',
                    isFullWidth: true,
                    icon: CupertinoIcons.plus_circle_fill,
                    onTap: () => context.push('/wallet'),
                  ),
                  SizedBox(height: AppSpacing.p8),
                  TextButton.icon(
                    onPressed: () => context.push('/settings'),
                    icon: Icon(
                      CupertinoIcons.slider_horizontal_3,
                      size: (16),
                      color: colors.textSecondary,
                    ),
                    label: Text(
                      'Ajustar preferencias',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _ClayWalletIllustration extends StatelessWidget {
  const _ClayWalletIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return SizedBox(
      width: (168),
      height: (128),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 10,
            child: Container(
              width: (138),
              height: (24),
              decoration: BoxDecoration(
                color: colors.textMain.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 28,
            child: _ClayCoin(
              size: 44,
              color: AppColors.o5,
              icon: CupertinoIcons.arrow_up_right,
            ),
          ),
          Positioned(
            right: 18,
            top: 12,
            child: _ClayCoin(
              size: (38),
              color: AppColors.e6,
              icon: CupertinoIcons.arrow_down_left,
            ),
          ),
          Positioned(
            bottom: 24,
            child: Container(
              width: (118),
              height: 72,
              decoration: BoxDecoration(
                color: colors.hero,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colors.hero.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 18,
                    top: 18,
                    child: Container(
                      width: 54,
                      height: (10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Container(
                      width: (34),
                      height: (28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.creditcard_fill,
                        color: Colors.white,
                        size: (16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClayCoin extends StatelessWidget {
  const _ClayCoin({
    required this.size,
    required this.color,
    required this.icon,
  });

  final double size;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: (size * 0.42)),
    );
  }
}
