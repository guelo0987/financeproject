import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';

class MenudoGauge extends StatefulWidget {
  final MenudoBudget budget;
  final bool isDark;

  const MenudoGauge({super.key, required this.budget, this.isDark = false});

  @override
  State<MenudoGauge> createState() => _MenudoGaugeState();
}

class _MenudoGaugeState extends State<MenudoGauge> with SingleTickerProviderStateMixin {
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
    final budget = widget.budget;
    final isDark = widget.isDark;
    final double ingresos = budget.ingresos > 0 ? budget.ingresos : 1;
    final List<BudgetCategory> cats = budget.cats.values.toList();
    final double totalSpent = cats.fold(0.0, (s, c) => s + c.gastado);
    final double totalLimitLimit = cats.fold(0.0, (s, c) => s + c.limite);

    return RepaintBoundary(
      child: SizedBox(
        height: 180,
        child: AnimatedBuilder(
          animation: _sweepAnimation,
          builder: (context, child) {
            final double progress = _sweepAnimation.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                CustomPaint(
                  size: const Size(200, 180),
                  painter: _GaugePainter(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.g2,
                    strokeWidth: 16,
                    startAngle: 180,
                    sweepAngle: 180,
                  ),
                ),

                // Limits Arc
                if (!isDark)
                  CustomPaint(
                    size: const Size(200, 180),
                    painter: _GaugePainter(
                      color: AppColors.g2.withValues(alpha: 0.5),
                      strokeWidth: 16,
                      startAngle: 180,
                      sweepAngle: 180 * min(totalLimitLimit / ingresos, 1.0) * progress,
                    ),
                  ),

                // Spend Segments — animated sweep
                ..._buildSegments(cats, ingresos, progress),

                // Center Text
                child!,
              ],
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              Text(
                "Restante",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.g4,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "RD\$${(budget.ingresos - totalSpent).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.e8,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSegments(List<BudgetCategory> cats, double ingresos, double progress) {
    List<Widget> segments = [];
    double currentAngle = 180.0;

    for (var cat in cats) {
      if (cat.gastado == 0) continue;

      double proportion = min(cat.gastado / ingresos, 1.0);
      double sweep = 180 * proportion * progress;

      segments.add(
        CustomPaint(
          size: const Size(200, 180),
          painter: _GaugePainter(
            color: cat.color,
            strokeWidth: 16,
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
