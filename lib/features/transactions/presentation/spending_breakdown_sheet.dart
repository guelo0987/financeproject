import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';

class SpendingBreakdownSheet extends StatefulWidget {
  final List<MenudoTransaction> transactions;
  final bool isGastos;
  final String periodoLabel;

  const SpendingBreakdownSheet({
    super.key,
    required this.transactions,
    required this.isGastos,
    required this.periodoLabel,
  });

  @override
  State<SpendingBreakdownSheet> createState() => _SpendingBreakdownSheetState();
}

class _SpendingBreakdownSheetState extends State<SpendingBreakdownSheet> {
  String? _expandedKey;

  static const _months = [
    '',
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String _fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  String _fmtDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length < 3) return dateStr;
    final day = int.tryParse(parts[2]) ?? 0;
    final monthIdx = int.tryParse(parts[1]) ?? 0;
    return "$day ${_months[monthIdx.clamp(0, 12)]}";
  }

  MenudoCategory? _findCategory(String catKey) {
    try {
      return mockCategories.firstWhere((c) => c.esParent && c.slug == catKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.transactions
        .where((t) => widget.isGastos ? t.tipo == 'gasto' : t.tipo == 'ingreso')
        .toList();
    final total = filtered.fold(0.0, (s, t) => s + t.monto.abs());

    // Group by catKey
    final Map<String, List<MenudoTransaction>> groups = {};
    for (final t in filtered) {
      groups.putIfAbsent(t.catKey, () => []).add(t);
    }

    // Sort by amount desc
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        final aSum = groups[a]!.fold(0.0, (s, t) => s + t.monto.abs());
        final bSum = groups[b]!.fold(0.0, (s, t) => s + t.monto.abs());
        return bSum.compareTo(aSum);
      });

    final accentColor = widget.isGastos ? AppColors.r5 : AppColors.e6;
    final accentLight = widget.isGastos ? AppColors.r1 : AppColors.e1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // ── Dark header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isGastos ? "GASTÉ" : "INGRESÉ",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.45),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fmt(total),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.periodoLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.isGastos
                            ? LucideIcons.trendingDown
                            : LucideIcons.trendingUp,
                        size: 24,
                        color: widget.isGastos
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Segmented color bar
                if (sortedKeys.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: sortedKeys.map((key) {
                          final keyTotal = groups[key]!.fold(
                            0.0,
                            (s, t) => s + t.monto.abs(),
                          );
                          final cat = _findCategory(key);
                          final color = cat?.color ?? AppColors.g4;
                          final flex = max(
                            1,
                            (keyTotal / (total > 0 ? total : 1) * 100).round(),
                          );
                          return Expanded(
                            flex: flex,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              color: color,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Legend
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: sortedKeys.take(4).map((key) {
                      final cat = _findCategory(key);
                      final color = cat?.color ?? AppColors.g4;
                      final label =
                          cat?.nombre ??
                          (key[0].toUpperCase() + key.substring(1));
                      final keyTotal = groups[key]!.fold(
                        0.0,
                        (s, t) => s + t.monto.abs(),
                      );
                      final pct = total > 0
                          ? (keyTotal / total * 100).round()
                          : 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$label $pct%",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // ── Category cards ──────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: accentLight,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            widget.isGastos
                                ? LucideIcons.trendingDown
                                : LucideIcons.trendingUp,
                            size: 26,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Sin ${widget.isGastos ? 'gastos' : 'ingresos'} ${widget.periodoLabel}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.e8,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: sortedKeys.length,
                    itemBuilder: (ctx, i) {
                      final key = sortedKeys[i];
                      final keyTxns = groups[key]!;
                      final keyTotal = keyTxns.fold(
                        0.0,
                        (s, t) => s + t.monto.abs(),
                      );
                      final pct = total > 0 ? keyTotal / total : 0.0;
                      final cat = _findCategory(key);
                      final color = cat?.color ?? AppColors.g4;
                      final icon = cat?.icono ?? LucideIcons.tag;
                      final label =
                          cat?.nombre ??
                          (key[0].toUpperCase() + key.substring(1));
                      final isExpanded = _expandedKey == key;

                      return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(
                                () => _expandedKey = isExpanded ? null : key,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isExpanded
                                      ? color.withValues(alpha: 0.35)
                                      : const Color(0xFFF3F4F6),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                icon,
                                                size: 22,
                                                color: color,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    label,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.e8,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${keyTxns.length} transacción${keyTxns.length != 1 ? 'es' : ''}",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.g4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "${widget.isGastos ? '-' : '+'}${_fmt(keyTotal)}",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: widget.isGastos
                                                        ? AppColors.r5
                                                        : AppColors.e6,
                                                  ),
                                                ),
                                                Text(
                                                  "${(pct * 100).round()}%",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.g4,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 6),
                                            AnimatedRotation(
                                              turns: isExpanded ? 0.5 : 0,
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              child: Icon(
                                                LucideIcons.chevronDown,
                                                size: 16,
                                                color: isExpanded
                                                    ? color
                                                    : AppColors.g3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Progress bar
                                        Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: AppColors.g1,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: LayoutBuilder(
                                            builder: (_, cons) => Container(
                                              height: 6,
                                              width: cons.maxWidth * pct,
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Expanded transactions
                                  if (isExpanded) ...[
                                    Container(
                                      height: 1,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      color: const Color(0xFFF3F4F6),
                                    ),
                                    ...keyTxns.asMap().entries.map((entry) {
                                      final t = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 11,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                right: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    t.desc,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.e8,
                                                    ),
                                                  ),
                                                  Text(
                                                    _fmtDate(t.dateString),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.g4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "${widget.isGastos ? '-' : '+'}${_fmt(t.monto.abs())}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: widget.isGastos
                                                    ? AppColors.r5
                                                    : AppColors.e6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 4),
                                  ],
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 280.ms, delay: (i * 45).ms)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: 280.ms,
                            delay: (i * 45).ms,
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
