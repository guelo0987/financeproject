import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

class MenudoBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTap;
  final VoidCallback onFabTap;

  const MenudoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabTap,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MenudoColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70, // Adjust as needed to match 80px total with SafeArea
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_filled,
                label: 'Inicio',
                isActive: currentIndex == 0,
                onTap: () => onTabTap(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Activos',
                isActive: currentIndex == 1,
                onTap: () => onTabTap(1),
              ),
              _FabItem(onTap: onFabTap),
              _NavItem(
                icon: Icons.pie_chart_rounded,
                label: 'Análisis',
                isActive: currentIndex == 2, // mapped for go_router which treats it as index 2 skipping fab
                onTap: () => onTabTap(2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Perfil',
                isActive: currentIndex == 3,
                onTap: () => onTabTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? MenudoColors.tabActive : MenudoColors.tabInactive;
    final weight = isActive ? FontWeight.w600 : FontWeight.w500;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: MenudoColors.tabActive.withValues(alpha: 0.1),
        highlightColor: MenudoColors.tabActive.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: weight,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FabItem extends StatefulWidget {
  final VoidCallback onTap;

  const _FabItem({required this.onTap});

  @override
  State<_FabItem> createState() => _FabItemState();
}

class _FabItemState extends State<_FabItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: MenudoColors.primary,
                shape: BoxShape.circle,
                boxShadow: [MenudoShadows.primaryShadow],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
