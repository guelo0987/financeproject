import 'dart:math';

import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../core/utils/formatters.dart';
import '../../../model/models.dart';
import '../../auth/auth_state.dart';
import '../../budgets/budget_providers.dart';
import '../providers/space_providers.dart';

class SpacesManagerScreen extends ConsumerStatefulWidget {
  const SpacesManagerScreen({super.key});

  @override
  ConsumerState<SpacesManagerScreen> createState() =>
      _SpacesManagerScreenState();
}

class _SpacesManagerScreenState extends ConsumerState<SpacesManagerScreen> {
  String _fmt(double val, {String? currency}) {
    return formatMoney(
      val,
      currency: currency ?? AppFormattingPreferences.currencyCode,
    );
  }

  void _openBudgets() {
    MenudoHaptics.selection();
    context.go('/budgets');
  }

  Future<void> _openSpaceDetail(SpaceSummary space) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpaceDetailSheet(space: space),
    );

    if (changed == true) {
      await ref.read(spaceControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacesAsync = ref.watch(spaceNotifierProvider);
    final spaces = ref.watch(effectiveSpacesProvider);
    final budgets = ref.watch(effectiveBudgetsProvider);
    final authState = ref.watch(authProvider);
    final userId = int.tryParse(authState.userId ?? '');
    final currency =
        authState.profile?.baseCurrency ??
        AppFormattingPreferences.currencyCode;

    return Scaffold(
      backgroundColor: context.menudo.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: context.menudo.surface,
            elevation: 0,
            leading: MenudoIconButton(
              icon: Icon(
                MenudoCupertinoIcons.chevronLeft,
                color: context.menudo.textMain,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                bottom: 16,
              ),
              centerTitle: false,
              title: Text(
                'Colaboraciones',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.menudo.textMain,
                  letterSpacing: -0.8,
                ),
              ),
              background: Container(color: context.menudo.surface),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SpacesHeroCard()
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),
                  SizedBox(height: (32)),
                  Text(
                    'ESPACIOS EXISTENTES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: context.menudo.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: (16)),
                  if (spacesAsync.hasError)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.r1,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.r5.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        presentError(spacesAsync.error!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.r5,
                        ),
                      ),
                    ),
                  if (spacesAsync.isLoading && spaces.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (spaces.isEmpty)
                    _buildEmptyState()
                  else
                    ...spaces.asMap().entries.map((entry) {
                      final budgetsForSpace = budgets
                          .where((budget) => budget.espacioId == entry.value.id)
                          .toList();
                      return _SpaceCard(
                            space: entry.value,
                            budgets: budgetsForSpace,
                            currentUserId: userId,
                            currency: currency,
                            fmt: _fmt,
                            onOpenDetail: () => _openSpaceDetail(entry.value),
                          )
                          .animate()
                          .fadeIn(
                            duration: 500.ms,
                            delay: (100 + entry.key * 80).ms,
                          )
                          .slideY(begin: 0.05, end: 0);
                    }),
                  SizedBox(height: (24)),
                  _SharedBudgetHintCard(
                    onTap: _openBudgets,
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                  SizedBox(height: (120)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(
              MenudoCupertinoIcons.users,
              size: 48,
              color: context.menudo.textMuted,
            ),
            SizedBox(height: (16)),
            Text(
              'No tienes colaboraciones aún',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.menudo.textMain,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Los espacios se crean solos cuando compartes un presupuesto.',
              style: TextStyle(
                fontSize: 14,
                color: context.menudo.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: (20)),
            FilledButton(
              onPressed: _openBudgets,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.o5,
                foregroundColor: context.menudo.textOnDark,
              ),
              child: Text('Ir a presupuestos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpacesHeroCard extends StatelessWidget {
  const _SpacesHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.menudo.textMain,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: context.menudo.textMain.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeroIcon(),
              SizedBox(width: (16)),
              Expanded(child: _HeroText()),
            ],
          ),
          SizedBox(height: (24)),
          _HeroFeature(
            icon: MenudoCupertinoIcons.walletCards,
            text: 'Nacen desde presupuestos compartidos',
          ),
          SizedBox(height: (12)),
          _HeroFeature(
            icon: MenudoCupertinoIcons.users,
            text: 'Revisa miembros y accesos',
          ),
          SizedBox(height: (12)),
          _HeroFeature(
            icon: MenudoCupertinoIcons.bell,
            text: 'Consulta invitaciones pendientes',
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.menudo.textOnDark.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        MenudoCupertinoIcons.users,
        size: (24),
        color: context.menudo.textOnDark,
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colaboración',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: context.menudo.textOnDark,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Presupuestos compartidos',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6EE7B7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: (16),
          color: context.menudo.textOnDark.withValues(alpha: 0.6),
        ),
        SizedBox(width: (12)),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.menudo.textOnDark,
          ),
        ),
      ],
    );
  }
}

class _SpaceCard extends ConsumerStatefulWidget {
  final SpaceSummary space;
  final List<MenudoBudget> budgets;
  final int? currentUserId;
  final String currency;
  final String Function(double, {String currency}) fmt;
  final VoidCallback onOpenDetail;

  const _SpaceCard({
    required this.space,
    required this.budgets,
    required this.currentUserId,
    required this.currency,
    required this.fmt,
    required this.onOpenDetail,
  });

  @override
  ConsumerState<_SpaceCard> createState() => _SpaceCardState();
}

class _SpaceCardState extends ConsumerState<_SpaceCard> {
  late Future<SpaceDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ref
        .read(spaceControllerProvider.notifier)
        .loadDetail(widget.space.id);
  }

  @override
  void didUpdateWidget(covariant _SpaceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.space.id != widget.space.id) {
      _detailFuture = ref
          .read(spaceControllerProvider.notifier)
          .loadDetail(widget.space.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presupuesto = widget.budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.ingresos,
    );
    final gastado = widget.budgets.fold<double>(
      0,
      (sum, budget) =>
          sum +
          budget.cats.values.fold<double>(
            0,
            (subsum, category) => subsum + category.gastado,
          ),
    );
    final isActivo = widget.budgets.any((budget) => budget.activo);
    final progress = min(gastado / (presupuesto > 0 ? presupuesto : 1), 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.menudo.textOnDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActivo
              ? context.menudo.primary.withValues(alpha: 0.3)
              : context.menudo.border,
          width: isActivo ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _SpaceBadge(nombre: widget.space.nombre),
                SizedBox(width: (16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.space.nombre,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: context.menudo.textMain,
                                letterSpacing: -0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActivo) ...[
                            SizedBox(width: 8),
                            _StateChip(label: 'ACTIVO', color: AppColors.e6),
                          ],
                        ],
                      ),
                      Text(
                        widget.space.descripcion?.trim().isNotEmpty == true
                            ? widget.space.descripcion!
                            : 'Espacio compartido',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.menudo.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _IconAction(
                  icon: MenudoCupertinoIcons.settings,
                  onTap: widget.onOpenDetail,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.fmt(gastado, currency: widget.currency)} gastado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.r5,
                      ),
                    ),
                    Text(
                      'de ${widget.fmt(presupuesto, currency: widget.currency)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.menudo.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (10)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: context.menudo.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.9 ? AppColors.r5 : AppColors.o5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.menudo.background,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: FutureBuilder<SpaceDetail>(
              future: _detailFuture,
              builder: (context, snapshot) {
                final detail = snapshot.data;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MemberAvatars(
                      miembros: detail?.miembros ?? [],
                      currentUserId: widget.currentUserId,
                    ),
                    _SmallDetailButton(onTap: widget.onOpenDetail),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceBadge extends StatelessWidget {
  final String nombre;

  const _SpaceBadge({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final initials = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    final palette = [
      AppColors.e6,
      AppColors.o5,
      AppColors.b5,
      AppColors.p5,
      AppColors.pk,
      AppColors.a5,
    ];
    final color = palette[nombre.hashCode.abs() % palette.length];

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'S' : initials,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StateChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  final List<SpaceMember> miembros;
  final int? currentUserId;

  const _MemberAvatars({required this.miembros, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (miembros.isEmpty) {
      return Text(
        'Sin miembros todavía',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.menudo.textMuted,
        ),
      );
    }

    final visible = miembros.take(4).toList();
    return Row(
      children: [
        ...List.generate(visible.length, (index) {
          final member = visible[index];
          final baseColor = [
            AppColors.e6,
            AppColors.o5,
            AppColors.b5,
            AppColors.p5,
            AppColors.pk,
            AppColors.a5,
          ][member.usuarioId % 6];
          final label = member.nombre?.trim().isNotEmpty == true
              ? member.nombre!.trim().characters.first.toUpperCase()
              : member.email?.characters.first.toUpperCase() ?? 'M';
          return Align(
            widthFactor: 0.7,
            child: Container(
              width: (32),
              height: (32),
              decoration: BoxDecoration(
                color: member.usuarioId == currentUserId
                    ? context.menudo.primary
                    : baseColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.menudo.textOnDark, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: context.menudo.textOnDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }),
        if (miembros.length > 4)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '+${miembros.length - 4}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.menudo.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _SharedBudgetHintCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SharedBudgetHintCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.menudo.textOnDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.o5.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.o1,
                shape: BoxShape.circle,
              ),
              child: Icon(
                MenudoCupertinoIcons.plus,
                size: (24),
                color: AppColors.o5,
              ),
            ),
            SizedBox(height: (12)),
            Text(
              'NUEVO PRESUPUESTO COMPARTIDO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: context.menudo.textMain,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Invita personas al crear el presupuesto.',
              style: TextStyle(
                fontSize: 12,
                color: context.menudo.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: (18), color: context.menudo.textSecondary),
      ),
    );
  }
}

class _SmallDetailButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SmallDetailButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            MenudoCupertinoIcons.chevronRight,
            size: (14),
            color: AppColors.o5,
          ),
          SizedBox(width: 6),
          Text(
            'Ver',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.o5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceDetailSheet extends ConsumerStatefulWidget {
  final SpaceSummary space;

  const _SpaceDetailSheet({required this.space});

  @override
  ConsumerState<_SpaceDetailSheet> createState() => _SpaceDetailSheetState();
}

class _SpaceDetailSheetState extends ConsumerState<_SpaceDetailSheet> {
  late Future<SpaceDetail> _detailFuture;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<SpaceDetail> _loadDetail() {
    return ref
        .read(spaceControllerProvider.notifier)
        .loadDetail(widget.space.id);
  }

  Future<void> _refresh() async {
    setState(() {
      _detailFuture = _loadDetail();
    });
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

  Future<void> _toggleRole(SpaceMember member) async {
    final nextRole = member.isAdmin ? 'miembro' : 'admin';
    setState(() => _isMutating = true);
    try {
      await ref
          .read(spaceControllerProvider.notifier)
          .updateMemberRole(widget.space.id, member.usuarioId, nextRole);
      await _refresh();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _removeMember(SpaceMember member) async {
    setState(() => _isMutating = true);
    try {
      await ref
          .read(spaceControllerProvider.notifier)
          .removeMember(widget.space.id, member.usuarioId);
      await _refresh();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _cancelInvitation(SpaceInvitation invitation) async {
    setState(() => _isMutating = true);
    try {
      await ref
          .read(spaceControllerProvider.notifier)
          .cancelInvitation(widget.space.id, invitation.id);
      await _refresh();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _deleteSpace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Eliminar espacio'),
        content: Text(
          'Eliminarás "${widget.space.nombre}" y sus accesos compartidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.r5,
              foregroundColor: context.menudo.textOnDark,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isMutating = true);
    try {
      await ref
          .read(spaceControllerProvider.notifier)
          .deleteSpace(widget.space.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      _showError(error);
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = int.tryParse(ref.watch(authProvider).userId ?? '');
    final isAdmin = widget.space.rol == 'admin';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: context.menudo.textOnDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: context.menudo.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.space.nombre,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: context.menudo.textMain,
                        ),
                      ),
                      if (widget.space.descripcion?.trim().isNotEmpty == true)
                        Text(
                          widget.space.descripcion!,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.menudo.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isAdmin)
                  MenudoIconButton(
                    onPressed: _isMutating ? null : _deleteSpace,
                    icon: Icon(
                      MenudoCupertinoIcons.trash2,
                      color: AppColors.r5,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<SpaceDetail>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        presentError(snapshot.error!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.r5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final detail = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.e0,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Los miembros nuevos se agregan al crear un presupuesto compartido. Aquí puedes revisar accesos e invitaciones pendientes.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: context.menudo.textMain,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _SectionTitle(title: 'Miembros'),
                    ...detail.miembros.map((member) {
                      final isCurrentUser = member.usuarioId == currentUserId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.menudo.background,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            _AvatarCircle(
                              label:
                                  member.nombre?.characters.first
                                      .toUpperCase() ??
                                  member.email?.characters.first
                                      .toUpperCase() ??
                                  'M',
                              color: member.isAdmin
                                  ? context.menudo.primary
                                  : AppColors.o5,
                            ),
                            SizedBox(width: (12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCurrentUser
                                        ? '${member.nombre ?? member.email ?? 'Tú'} (Tú)'
                                        : member.nombre ??
                                              member.email ??
                                              'Miembro',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: context.menudo.textMain,
                                    ),
                                  ),
                                  Text(
                                    member.email ?? member.rol,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.menudo.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StateChip(
                              label: member.isAdmin ? 'ADMIN' : 'MIEMBRO',
                              color: member.isAdmin
                                  ? context.menudo.primary
                                  : AppColors.o5,
                            ),
                            if (isAdmin && !isCurrentUser)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'toggle') {
                                    _toggleRole(member);
                                  } else if (value == 'remove') {
                                    _removeMember(member);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem<String>(
                                    value: 'toggle',
                                    child: Text(
                                      member.isAdmin
                                          ? 'Hacer miembro'
                                          : 'Hacer admin',
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'remove',
                                    child: Text('Remover'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: (12)),
                    _SectionTitle(title: 'Invitaciones pendientes'),
                    if (detail.invitaciones.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No hay invitaciones pendientes.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.menudo.textMuted,
                          ),
                        ),
                      )
                    else
                      ...detail.invitaciones.map((invitation) {
                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.menudo.background,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const _AvatarCircle(
                                label: '@',
                                color: AppColors.p5,
                              ),
                              SizedBox(width: (12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invitation.emailInvitado,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: context.menudo.textMain,
                                      ),
                                    ),
                                    Text(
                                      invitation.expiraEn == null
                                          ? 'Pendiente'
                                          : 'Expira ${invitation.expiraEn!.day}/${invitation.expiraEn!.month}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.menudo.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAdmin)
                                TextButton(
                                  onPressed: _isMutating
                                      ? null
                                      : () => _cancelInvitation(invitation),
                                  child: Text('Cancelar'),
                                ),
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: context.menudo.textMain,
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String label;
  final Color color;

  const _AvatarCircle({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (36),
      height: (36),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: context.menudo.textOnDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
