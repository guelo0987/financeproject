import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'menudo_logo.dart';

class MenudoLoadingView extends StatelessWidget {
  const MenudoLoadingView({
    super.key,
    this.title = 'Cargando',
    this.message,
    this.logoSize = 96,
  });

  final String title;
  final String? message;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenudoLogo(size: logoSize),
            SizedBox(height: (18)),
            SizedBox(
              width: (24),
              height: (24),
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.primary,
              ),
            ),
            SizedBox(height: (18)),
            Text(
              title,
              style: MenudoTextStyles.h3.copyWith(color: colors.textMain),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: 8),
              Text(
                message!,
                style: MenudoTextStyles.bodyMedium.copyWith(
                  color: colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MenudoInlineLoadingCard extends StatelessWidget {
  const MenudoInlineLoadingCard({
    super.key,
    this.label = 'Cargando',
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 18,
        vertical: compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: (18),
            height: (18),
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: colors.primary,
            ),
          ),
          SizedBox(width: (12)),
          Text(
            label,
            style: MenudoTextStyles.bodyMedium.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
