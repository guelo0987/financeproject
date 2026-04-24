import 'dart:math';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../../core/utils/formatters.dart';
import '../../categories/providers/category_providers.dart';

class SpendingBreakdownSheet extends ConsumerStatefulWidget {
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
  ConsumerState<SpendingBreakdownSheet> createState() =>
      _SpendingBreakdownSheetState();
}

class _SpendingBreakdownSheetState
    extends ConsumerState<SpendingBreakdownSheet> {
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

  String _fmt(double val) => formatMoney(val);

  String _fmtDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length < 3) return dateStr;
    final day = int.tryParse(parts[2]) ?? 0;
    final monthIdx = int.tryParse(parts[1]) ?? 0;
    return "$day ${_months[monthIdx.clamp(0, 12)]}";
  }

  MenudoCategory? _findCategory(String catKey) {
    final categories = ref.read(effectiveCategoriesProvider);
    try {
      return categories.firstWhere((c) => c.slug == catKey);
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
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // ── Dark header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: context.menudo.textMain,
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
                      color: context.menudo.textOnDark.withValues(alpha: 0.2),
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
                              color: context.menudo.textOnDark.withValues(
                                alpha: 0.45,
                              ),
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _fmt(total),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: context.menudo.textOnDark,
                              letterSpacing: -1.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.periodoLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.menudo.textOnDark.withValues(
                                alpha: 0.45,
                              ),
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
                            ? MenudoCupertinoIcons.trendingDown
                            : MenudoCupertinoIcons.trendingUp,
                        size: (24),
                        color: widget.isGastos
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF6EE7B7),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (20)),

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
                          final color = cat?.color ?? context.menudo.textMuted;
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
                  SizedBox(height: (12)),
                  // Legend
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: sortedKeys.take(4).map((key) {
                      final cat = _findCategory(key);
                      final color = cat?.color ?? context.menudo.textMuted;
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
                          SizedBox(width: 4),
                          Text(
                            "$label $pct%",
                            style: TextStyle(
                              fontSize: 11,
                              color: context.menudo.textOnDark.withValues(
                                alpha: 0.55,
                              ),
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
                                ? MenudoCupertinoIcons.trendingDown
                                : MenudoCupertinoIcons.trendingUp,
                            size: (26),
                            color: accentColor,
                          ),
                        ),
                        SizedBox(height: (12)),
                        Text(
                          "Sin ${widget.isGastos ? 'gastos' : 'ingresos'} ${widget.periodoLabel}",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.menudo.textMain,
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
                      final color = cat?.color ?? context.menudo.textMuted;
                      final icon = cat?.icono ?? MenudoCupertinoIcons.tag;
                      final label =
                          cat?.nombre ??
                          (key[0].toUpperCase() + key.substring(1));
                      final isExpanded = _expandedKey == key;

                      return MenudoGestureDetector(
                            onTap: () {
                              MenudoHaptics.light();
                              setState(
                                () => _expandedKey = isExpanded ? null : key,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: context.menudo.textOnDark,
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
                                                size: (22),
                                                color: color,
                                              ),
                                            ),
                                            SizedBox(width: (12)),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: context
                                                          .menudo
                                                          .textMain,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${keyTxns.length} transacción${keyTxns.length != 1 ? 'es' : ''}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: context
                                                          .menudo
                                                          .textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 8),
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
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: context
                                                        .menudo
                                                        .textMuted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 6),
                                            AnimatedRotation(
                                              turns: isExpanded ? 0.5 : 0,
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              child: Icon(
                                                MenudoCupertinoIcons
                                                    .chevronDown,
                                                size: (16),
                                                color: isExpanded
                                                    ? color
                                                    : context.menudo.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: (12)),
                                        // Progress bar
                                        Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: context.menudo.surface,
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
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: context
                                                          .menudo
                                                          .textMain,
                                                    ),
                                                  ),
                                                  Text(
                                                    _fmtDate(t.dateString),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: context
                                                          .menudo
                                                          .textMuted,
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
                                    SizedBox(height: 4),
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
