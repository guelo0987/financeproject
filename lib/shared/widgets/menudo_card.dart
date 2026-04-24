import 'package:flutter/cupertino.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class MenudoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BoxBorder? border;

  const MenudoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(MenudoRadius.card),
        border: border ?? Border.all(color: colors.border, width: 0.5),
        boxShadow: [MenudoShadows.cardShadow],
      ),
      child: child,
    );
  }
}

class MenudoHeroCard extends StatelessWidget {
  final Widget child;

  const MenudoHeroCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.hero,
        borderRadius: BorderRadius.circular(MenudoRadius.hero),
        boxShadow: [MenudoShadows.heroShadow],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background icon
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              CupertinoIcons.chart_pie_fill,
              size: (120),
              color: colors.textOnDark.withValues(alpha: 0.08),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}
