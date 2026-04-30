import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class MenudoGauge extends StatefulWidget {
  final MenudoBudget budget;
  final bool isDark;

  const MenudoGauge({super.key, required this.budget, this.isDark = false});

  @override
  State<MenudoGauge> createState() => _MenudoGaugeState();
}

class _MenudoGaugeState extends State<MenudoGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sweepAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _sweepAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final budget = widget.budget;
    final double ingresos = budget.displayIncomeBase > 0
        ? budget.displayIncomeBase
        : 1;
    final List<BudgetCategory> cats = budget.spendingCategories;

    return RepaintBoundary(
      child: SizedBox(
        height: (160),
        child: AnimatedBuilder(
          animation: _sweepAnimation,
          builder: (context, child) {
            final double progress = _sweepAnimation.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                CustomPaint(
                  size: const Size(260, 160),
                  painter: _GaugePainter(
                    color: colors.border,
                    strokeWidth: 18,
                    startAngle: 180,
                    sweepAngle: 180,
                  ),
                ),

                // Spend Segments
                ..._buildSegments(cats, ingresos, progress),

                // Center Text
                Positioned(bottom: 10, child: child!),
              ],
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Disponible",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                formatMoney(budget.availableToSpend),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: colors.textMain,
                  letterSpacing: -1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSegments(
    List<BudgetCategory> cats,
    double ingresos,
    double progress,
  ) {
    List<Widget> segments = [];
    double currentAngle = 180.0;

    final double totalSpent = widget.budget.totalSpent;
    // Normalize if spent > income to fit in 180 degrees visually, but usually we want to show overflow?
    // Let's normalize to totalSpent if totalSpent > ingresos to keep it within the semi-circle
    final double divisor = max(ingresos, totalSpent);

    for (var cat in cats) {
      if (cat.gastado == 0) continue;

      double proportion = cat.gastado / divisor;
      double sweep = 180 * proportion * progress;

      segments.add(
        CustomPaint(
          size: const Size(260, 160),
          painter: _GaugePainter(
            color: cat.color,
            strokeWidth: 18,
            startAngle: currentAngle,
            sweepAngle: sweep,
          ),
        ),
      );

      currentAngle += sweep;
    }

    return segments;
  }
}

class _GaugePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double startAngle;
  final double sweepAngle;

  _GaugePainter({
    required this.color,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height - (strokeWidth / 2));
    final radius = (min(size.width, size.height * 2) / 2) - (strokeWidth / 2);

    final startRad = startAngle * (pi / 180);
    final sweepRad = sweepAngle * (pi / 180);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startRad,
      sweepRad,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle;
  }
}
