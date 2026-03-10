import 'package:flutter/material.dart';
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

class _MenudoButtonState extends State<MenudoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled ? AppColors.g1 : AppColors.o5;
    final textColor = widget.isDisabled ? AppColors.g4 : AppColors.white;

    return GestureDetector(
      onTapDown: widget.isDisabled
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isDisabled
          ? null
          : (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isDisabled ? null : widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _isPressed ? 0.96 : 1.0,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isDisabled
                ? null
                : [
                    const BoxShadow(
                      color: Color(0x44F97316),
                      blurRadius: 32,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
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
