import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

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
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border(top: BorderSide(color: AppColors.g2.withValues(alpha: 0.5), width: 0.5)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: LucideIcons.layoutDashboard,
                    label: 'Inicio',
                    isActive: currentIndex == 0,
                    onTap: () => onTabTap(0),
                  ),
                  _NavItem(
                    icon: LucideIcons.calendar,
                    label: 'Agenda',
                    isActive: currentIndex == 1,
                    onTap: () => onTabTap(1),
                  ),
                  _FabItem(onTap: onFabTap),
                  _NavItem(
                    icon: LucideIcons.pieChart,
                    label: 'Presupuestos',
                    isActive: currentIndex == 2, 
                    onTap: () => onTabTap(2),
                  ),
                  _NavItem(
                    icon: LucideIcons.wallet,
                    label: 'Cartera',
                    isActive: currentIndex == 3,
                    onTap: () => onTabTap(3),
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
    final color = isActive ? AppColors.e8 : AppColors.g4;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut, // Changed from easeOutBack to prevent negative width
              width: isActive ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.e8,
                shape: BoxShape.circle,
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
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
    HapticFeedback.mediumImpact();
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.o5,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.o5.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

