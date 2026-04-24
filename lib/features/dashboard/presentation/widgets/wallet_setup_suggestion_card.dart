import 'package:financeproject/core/theme/app_colors.dart';
import 'package:financeproject/shared/widgets/menudo_button.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter/cupertino.dart';

class WalletSetupSuggestionCard extends StatelessWidget {
  const WalletSetupSuggestionCard({
    super.key,
    required this.onConfigure,
    required this.onDismiss,
  });

  final VoidCallback onConfigure;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.successLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.creditcard_fill,
                  size: (22),
                  color: colors.success,
                ),
              ),
              SizedBox(width: (12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conecta tu primera cuenta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colors.textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Menudo puede registrar movimientos mejor si sabe de dónde entra o sale el dinero.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Descartar sugerencia',
                child: MenudoGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: (18),
                      color: context.menudo.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (14)),
          MenudoButton(
            label: 'Agregar cuenta',
            onTap: onConfigure,
            isFullWidth: true,
            icon: CupertinoIcons.plus_circle_fill,
          ),
        ],
      ),
    );
  }
}
