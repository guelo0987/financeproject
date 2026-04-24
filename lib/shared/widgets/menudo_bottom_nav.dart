import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter/physics.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
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
    final colors = context.menudo;

    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: colors.navBar.withValues(alpha: 0.75),
        border: Border(top: BorderSide(color: colors.navBarBorder, width: 0.5)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: CupertinoIcons.house_fill,
                    label: 'Inicio',
                    isActive: currentIndex == 0,
                    onTap: () => onTabTap(0),
                  ),
                  _NavItem(
                    icon: CupertinoIcons.calendar,
                    label: 'Agenda',
                    isActive: currentIndex == 1,
                    onTap: () => onTabTap(1),
                  ),
                  _FabItem(onTap: onFabTap),
                  _NavItem(
                    icon: CupertinoIcons.chart_pie_fill,
                    label: 'Presupuestos',
                    isActive: currentIndex == 2,
                    onTap: () => onTabTap(2),
                  ),
                  _NavItem(
                    icon: CupertinoIcons.creditcard_fill,
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
    final colors = context.menudo;
    final color = isActive ? colors.tabActive : colors.tabInactive;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: MenudoInkWell(
          onTap: () {
            MenudoHaptics.selection();
            onTap();
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 49),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(icon, size: (22), color: color),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                    color: color,
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: isActive ? 4 : 0,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.tabActive,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
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

class _FabItemState extends State<_FabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _springTo(double target) {
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 760, damping: 32),
        _controller.value,
        target,
        0,
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _springTo(0.88);
  }

  void _handleTapUp(TapUpDetails details) {
    _springTo(1);
    MenudoHaptics.medium();
    widget.onTap();
  }

  void _handleTapCancel() {
    _springTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Expanded(
      child: Semantics(
        button: true,
        label: 'Registrar movimiento',
        child: MenudoGestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: ScaleTransition(
              scale: _controller,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryGlow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.plus,
                  color: colors.textOnDark,
                  size: (28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
