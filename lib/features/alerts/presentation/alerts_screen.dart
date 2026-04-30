import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/menudo_haptics.dart';
import '../../../../model/models.dart';
import '../../../../shared/widgets/menudo_loading_view.dart';
import '../../auth/auth_state.dart';
import '../../budgets/budget_providers.dart' as budget_providers;
import '../../budgets/presentation/budget_detail_sheet.dart';
import '../providers/alert_providers.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final Set<int> _busyAlerts = <int>{};
  bool _markingAll = false;

  Future<void> _refresh() async {
    ref.invalidate(unreadAlertsCountProvider);
    await ref.read(alertControllerProvider.notifier).refresh();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(presentError(error)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markAsRead(AppAlert alert) async {
    setState(() => _busyAlerts.add(alert.id));
    try {
      await ref.read(alertControllerProvider.notifier).markAsRead(alert.id);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busyAlerts.remove(alert.id));
      }
    }
  }

  Future<void> _acceptInvitation(AppAlert alert) async {
    final email = ref.read(authProvider).profile?.email.trim() ?? '';
    if (email.isEmpty) {
      _showError(
        'No pudimos identificar tu cuenta. Vuelve a entrar e inténtalo otra vez.',
      );
      return;
    }

    setState(() => _busyAlerts.add(alert.id));
    try {
      await ref
          .read(alertControllerProvider.notifier)
          .acceptInvitation(alert, email);
      if (!mounted) return;
      final budgetId = alert.extra.budgetId;
      if (budgetId != null) {
        await _showBudgetDetails(budgetId);
      } else {
        MenudoHaptics.success();
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busyAlerts.remove(alert.id));
      }
    }
  }

  Future<void> _markAllAsRead(List<AppAlert> alerts) async {
    if (alerts.every((alert) => alert.isRead)) return;

    setState(() => _markingAll = true);
    try {
      await ref.read(alertControllerProvider.notifier).markAllAsRead();
      MenudoHaptics.success();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _markingAll = false);
      }
    }
  }

  Future<void> _showBudgetDetails(int budgetId) async {
    final cachedBudgets = ref.read(budget_providers.effectiveBudgetsProvider);
    MenudoBudget? budget;
    for (final item in cachedBudgets) {
      if (item.id == budgetId) {
        budget = item;
        break;
      }
    }

    budget ??= await ref
        .read(budget_providers.budgetControllerProvider.notifier)
        .fetchBudgetById(budgetId);

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetDetailSheet(budget: budget!),
    );
  }

  Future<void> _openBudget(AppAlert alert) async {
    final budgetId = alert.extra.budgetId;
    if (budgetId == null) {
      _showError('Esta alerta todavía no se puede abrir.');
      return;
    }

    setState(() => _busyAlerts.add(alert.id));
    try {
      if (!alert.isRead) {
        await ref.read(alertControllerProvider.notifier).markAsRead(alert.id);
      }
      await _showBudgetDetails(budgetId);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busyAlerts.remove(alert.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertNotifierProvider);

    return Scaffold(
      backgroundColor: context.menudo.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      _HeaderCircleButton(
                        icon: MenudoCupertinoIcons.chevronLeft,
                        onTap: () => context.pop(),
                      ),
                      SizedBox(width: (14)),
                      Expanded(
                        child: Text(
                          'Alertas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: context.menudo.textMain,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...alertsAsync.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MenudoLoadingView(
                      title: 'Cargando alertas',
                      message: 'Estamos revisando tus novedades.',
                      logoSize: 88,
                    ),
                  ),
                ],
                error: (error, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _StateCard(
                        icon: MenudoCupertinoIcons.alertCircle,
                        title: 'No se pudieron cargar las alertas',
                        body: presentError(error),
                        actionLabel: 'Reintentar',
                        onTap: _refresh,
                      ),
                    ),
                  ),
                ],
                data: (alerts) {
                  final unreadCount = alerts
                      .where((alert) => !alert.isRead)
                      .length;

                  if (alerts.isEmpty) {
                    return [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: _StateCard(
                            icon: MenudoCupertinoIcons.bell,
                            title: 'Por ahora no tienes alertas',
                            body:
                                'Cuando tengas invitaciones o novedades importantes, aparecerán aquí.',
                          ),
                        ),
                      ),
                    ];
                  }

                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Row(
                          children: [
                            Text(
                              unreadCount == 0
                                  ? 'Todo al día'
                                  : '$unreadCount sin leer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: context.menudo.textMain,
                              ),
                            ),
                            const Spacer(),
                            if (unreadCount > 0)
                              TextButton(
                                onPressed: _markingAll
                                    ? null
                                    : () => _markAllAsRead(alerts),
                                child: _markingAll
                                    ? SizedBox(
                                        width: (16),
                                        height: (16),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text('Marcar todo'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        final busy = _busyAlerts.contains(alert.id);
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            index == 0 ? 0 : 0,
                            20,
                            index == alerts.length - 1 ? 120 : 12,
                          ),
                          child: _AlertCard(
                            alert: alert,
                            isBusy: busy,
                            onMarkAsRead: alert.isRead
                                ? null
                                : () => _markAsRead(alert),
                            onAccept: alert.canAcceptInApp
                                ? () => _acceptInvitation(alert)
                                : null,
                            onOpenBudget:
                                alert.isAcceptedInvitation &&
                                    alert.extra.budgetId != null
                                ? () => _openBudget(alert)
                                : null,
                          ),
                        );
                      },
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.menudo.surface,
          shape: BoxShape.circle,
          border: Border.all(color: context.menudo.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: context.menudo.textMain, size: (18)),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: (28), color: context.menudo.textMain),
          SizedBox(height: (14)),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: context.menudo.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.menudo.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onTap != null) ...[
            SizedBox(height: (16)),
            FilledButton(onPressed: onTap, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.isBusy,
    this.onMarkAsRead,
    this.onAccept,
    this.onOpenBudget,
  });

  final AppAlert alert;
  final bool isBusy;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onAccept;
  final VoidCallback? onOpenBudget;

  @override
  Widget build(BuildContext context) {
    final accent = switch (alert.type) {
      'invitacion_presupuesto' => AppColors.o5,
      'invitacion_aceptada' => AppColors.e6,
      _ => AppColors.b5,
    };
    final dateLabel = alert.createdAt == null
        ? null
        : formatDateByPattern(
            alert.createdAt!.toLocal(),
            pattern: 'd MMM, h:mm a',
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: alert.isRead
              ? context.menudo.border
              : accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  alert.isBudgetInvitation
                      ? MenudoCupertinoIcons.mailOpen
                      : alert.isAcceptedInvitation
                      ? MenudoCupertinoIcons.checkCircle2
                      : MenudoCupertinoIcons.bell,
                  size: (18),
                  color: accent,
                ),
              ),
              SizedBox(width: (14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: context.menudo.textMain,
                            ),
                          ),
                        ),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      alert.body,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: context.menudo.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dateLabel != null) ...[
                      SizedBox(height: 8),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.menudo.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (alert.extra.budgetName != null ||
              alert.extra.invitedBy != null ||
              alert.extra.budgetId != null) ...[
            SizedBox(height: (14)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (alert.extra.budgetName?.isNotEmpty == true)
                  _InfoPill(label: alert.extra.budgetName!),
                if (alert.extra.invitedBy?.isNotEmpty == true)
                  _InfoPill(label: 'Invita ${alert.extra.invitedBy!}'),
              ],
            ),
          ],
          if (onAccept != null ||
              onOpenBudget != null ||
              onMarkAsRead != null) ...[
            SizedBox(height: (16)),
            Row(
              children: [
                if (onAccept != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: isBusy ? null : onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.o5,
                        foregroundColor: context.menudo.surface,
                      ),
                      child: isBusy
                          ? SizedBox(
                              width: (16),
                              height: (16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.menudo.surface,
                              ),
                            )
                          : Text('Aceptar'),
                    ),
                  ),
                if ((onAccept != null || onOpenBudget != null) &&
                    onMarkAsRead != null)
                  SizedBox(width: (10)),
                if (onOpenBudget != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: isBusy ? null : onOpenBudget,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.menudo.textMain,
                        foregroundColor: context.menudo.surface,
                      ),
                      child: isBusy
                          ? SizedBox(
                              width: (16),
                              height: (16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.menudo.surface,
                              ),
                            )
                          : Text('Ver presupuesto'),
                    ),
                  ),
                if (onOpenBudget != null && onMarkAsRead != null)
                  SizedBox(width: (10)),
                if (onMarkAsRead != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isBusy ? null : onMarkAsRead,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.menudo.textMain,
                        side: BorderSide(color: context.menudo.border),
                      ),
                      child: Text('Marcar leída'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.menudo.textSecondary,
        ),
      ),
    );
  }
}
