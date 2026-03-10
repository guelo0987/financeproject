import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../providers/wallet_providers.dart';

class _DefaultWalletToggle extends ConsumerStatefulWidget {
  final int walletId;
  const _DefaultWalletToggle({required this.walletId});

  @override
  ConsumerState<_DefaultWalletToggle> createState() =>
      _DefaultWalletToggleState();
}

class _DefaultWalletToggleState extends ConsumerState<_DefaultWalletToggle> {
  @override
  Widget build(BuildContext context) {
    final defaultId = ref.watch(defaultWalletIdProvider);
    final isDefault = defaultId == widget.walletId;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDefault ? AppColors.e8.withValues(alpha: 0.3) : AppColors.g2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.g1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.star,
                  size: 18,
                  color: isDefault ? AppColors.o5 : AppColors.g3,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cuenta principal",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                    Text(
                      "Usar por defecto en transacciones",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.g4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDefault,
                activeThumbColor: AppColors.e8,
                activeTrackColor: AppColors.e8.withValues(alpha: 0.35),
                onChanged: (val) {
                  HapticFeedback.mediumImpact();
                  ref.read(defaultWalletIdProvider.notifier).state = val
                      ? widget.walletId
                      : null;
                },
              ),
            ],
          ),
          if (isDefault)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 14, color: AppColors.e6),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Esta cuenta aparecerá seleccionada automáticamente al registrar gastos o ingresos.",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.e6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }
}

class WalletDetailSheet extends StatelessWidget {
  final WalletAccount wallet;

  const WalletDetailSheet({super.key, required this.wallet});

  String fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    final w = wallet;
    final bool isNegative = w.saldo < 0;

    // Type labels
    final Map<String, String> tipoLabels = {
      'ahorro': 'Cuenta de ahorro',
      'gasto': 'Cuenta de gastos',
      'deuda': 'Deuda / Credito',
    };

    // Use all mockTxns as placeholder
    final txns = mockTxns.take(5).toList();
    final activeBudget = mockBudgets.firstWhere(
      (b) => b.activo,
      orElse: () => mockBudgets.first,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.g0,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Dark header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.e8,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        height: 5,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Close + title row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.arrowLeft,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "Detalle de cuenta",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 32),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Account icon + name
                    Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: w.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Icon(w.icono, size: 28, color: Colors.white),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),

                    const SizedBox(height: 12),

                    Text(
                      w.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tipoLabels[w.tipo] ?? w.tipo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                    const SizedBox(height: 16),

                    // Balance
                    Text(
                      "SALDO ACTUAL",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                    const SizedBox(height: 4),
                    Text(
                          "${isNegative ? '-' : ''}${fmt(w.saldo.abs())}",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: isNegative
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF6EE7B7),
                            letterSpacing: -1.5,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 400.ms,
                          delay: 200.ms,
                        ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    // Action buttons
                    Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => HapticFeedback.lightImpact(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.o5,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      const BoxShadow(
                                        color: Color(0x44F97316),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        LucideIcons.arrowLeftRight,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Transferir",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => HapticFeedback.lightImpact(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFF3F4F6),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        LucideIcons.pencil,
                                        size: 16,
                                        color: AppColors.e8,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Editar",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.e8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 250.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 350.ms,
                          delay: 250.ms,
                        ),

                    const SizedBox(height: 20),

                    // Default Wallet Toggle
                    _DefaultWalletToggle(walletId: w.id),

                    const SizedBox(height: 20),

                    // Recent transactions header
                    const Text(
                      "Ultimas transacciones",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Movimientos recientes de esta cuenta",
                      style: TextStyle(fontSize: 12, color: AppColors.g4),
                    ),
                    const SizedBox(height: 12),

                    // Transaction list
                    Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFF3F4F6),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: List.generate(txns.length, (i) {
                              final t = txns[i];
                              final ci = activeBudget.cats[t.catKey];
                              final dayStr = t.dateString.split('-');
                              final months = [
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
                              final monthLabel =
                                  months[int.tryParse(dayStr[1]) ?? 0];

                              return Column(
                                children: [
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFF3F4F6),
                                      indent: 68,
                                      endIndent: 16,
                                    ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => TransactionDetailSheet(
                                          transaction: t,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: (ci?.color ?? AppColors.g4)
                                                  .withValues(alpha: 0.13),
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              t.icono,
                                              size: 19,
                                              color: ci?.color ?? AppColors.g4,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t.desc,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.e8,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "${ci?.label ?? t.catKey} \u00B7 ${dayStr[2]} $monthLabel",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.g4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            t.tipo == "ingreso"
                                                ? "+ ${fmt(t.monto.abs())}"
                                                : "- ${fmt(t.monto.abs())}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: t.tipo == "ingreso"
                                                  ? AppColors.e6
                                                  : AppColors.e8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 350.ms)
                        .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 400.ms,
                          delay: 350.ms,
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
