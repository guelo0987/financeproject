import 'package:flutter/material.dart';
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(MenudoRadius.card),
        border: border ?? Border.all(color: MenudoColors.border),
        boxShadow: const [MenudoShadows.cardShadow],
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MenudoColors.cardBg, // Emerald 800
        borderRadius: BorderRadius.circular(MenudoRadius.hero),
        boxShadow: const [MenudoShadows.heroShadow],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background icon
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.pie_chart_sharp,
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}
