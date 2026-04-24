import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter/physics.dart';
import '../../core/theme/app_colors.dart';

class MenudoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isFullWidth;
  final bool isDisabled;
  final IconData? icon;

  const MenudoButton({
    super.key,
    required this.label,
    this.onTap,
    this.isFullWidth = false,
    this.isDisabled = false,
    this.icon,
  });

  @override
  State<MenudoButton> createState() => _MenudoButtonState();
}

class _MenudoButtonState extends State<MenudoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _springTo(double target) {
    _scaleController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 740, damping: 34),
        _scaleController.value,
        target,
        0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final bgColor = widget.isDisabled ? colors.surfaceMuted : colors.primary;
    final textColor = widget.isDisabled ? colors.textMuted : colors.textOnDark;
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: textColor,
    );

    return Semantics(
      button: true,
      enabled: !widget.isDisabled,
      label: widget.label,
      child: ScaleTransition(
        scale: _scaleController,
        child: MenudoGestureDetector(
          onTapDown: widget.isDisabled ? null : (_) => _springTo(0.96),
          onTapUp: widget.isDisabled ? null : (_) => _springTo(1),
          onTapCancel: () => _springTo(1),
          onTap: widget.isDisabled ? null : widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.isFullWidth ? double.infinity : null,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: colors.primaryGlow,
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: widget.isFullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: textColor, size: (20)),
                  SizedBox(width: 8),
                ],
                if (widget.isFullWidth)
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  )
                else
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Legacy alias to prevent compilation errors in older views
class MenudoPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isDisabled;

  const MenudoPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) => MenudoButton(
    label: label,
    onTap: onTap,
    isFullWidth: true,
    icon: icon,
    isDisabled: isDisabled,
  );
}

// Legacy alias to prevent compilation errors
class MenudoSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDisabled;

  const MenudoSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) => MenudoButton(
    label: label,
    onTap: onTap,
    isFullWidth: true,
    isDisabled: isDisabled,
  );
}
