import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/menudo_sliver_refresh_control.dart';
import '../../../../shared/widgets/menudo_toast.dart';
import '../../../../utils/storage_keys.dart';
import '../../auth/auth_state.dart';
import '../budget_providers.dart';
import 'budget_detail_sheet.dart';
import 'wizard/create_budget_wizard.dart';

String _budgetPeriodLabel(String periodo) {
  return switch (periodo.toLowerCase()) {
    'mensual' => 'MENSUAL',
    'quincenal' => 'QUINCENAL',
    'semanal' => 'SEMANAL',
    'unico' => 'PUNTUAL',
    _ => periodo.toUpperCase(),
  };
}

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  static const _storage = FlutterSecureStorage();

  String _filtro = "Todos";
  final List<String> _filtros = ["Todos", "Mensual", "Quincenal", "Semanal"];
  bool _onboardingScheduled = false;

  String _fmt(double val) => formatMoney(val);

  void _showDetail(MenudoBudget b) {
    MenudoHaptics.light();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetDetailSheet(budget: b),
    );
  }

  void _showCreate() {
    MenudoHaptics.medium();
    Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreateBudgetWizard(fullScreen: true),
      ),
    );
  }

  void _scheduleBudgetOnboarding() {
    if (_onboardingScheduled) return;
    _onboardingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _onboardingScheduled = false;
      await _maybeShowBudgetOnboarding();
    });
  }

  Future<void> _maybeShowBudgetOnboarding() async {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    final userId = auth.userId?.trim();
    if (!auth.isAuthenticated || userId == null || userId.isEmpty) return;

    final key = '${StorageKeys.budgetOnboardingSeen}_$userId';
    final seen = await _storage.read(key: key);
    if (seen == 'true' || !mounted) return;

    await _storage.write(key: key, value: 'true');
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BudgetOnboardingSheet(
        onCreateBudget: () {
          MenudoHaptics.medium();
          Navigator.of(sheetContext).pop();
          _showCreate();
        },
      ),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    MenudoToast.error(
      context,
      title: 'No se pudo actualizar',
      message: presentError(error),
    );
  }

  Future<void> _selectBudget(MenudoBudget budget) async {
    MenudoHaptics.medium();
    try {
      await ref
          .read(budgetNotifierProvider.notifier)
          .selectBudget(budget.id, persist: true);
      if (!mounted) return;
      MenudoToast.success(
        context,
        title: 'Presupuesto activo',
        message: budget.nombre,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _refreshBudgets() async {
    try {
      await ref.read(budgetNotifierProvider.notifier).refresh();
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBudgetOnboarding();
    final budgets = ref.watch(effectiveBudgetsProvider);
    final selectedIdx = ref
        .watch(selectedBudgetIdxProvider)
        .clamp(0, budgets.isEmpty ? 0 : budgets.length - 1);
    final activeBudget = budgets.isEmpty ? null : budgets[selectedIdx];

    final filteredBudgets = _filtro == "Todos"
        ? budgets
        : budgets
              .where((b) => b.periodo.toLowerCase() == _filtro.toLowerCase())
              .toList();

    return Scaffold(
      backgroundColor: context.menudo.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          MenudoSliverRefreshControl(onRefresh: _refreshBudgets),
          SliverAppBar(
            pinned: true,
            backgroundColor: context.menudo.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 82,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Presupuestos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: context.menudo.textMain,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  activeBudget == null
                      ? '${budgets.length} presupuesto${budgets.length == 1 ? '' : 's'}'
                      : 'Activo: ${activeBudget.nombre}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.menudo.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: MenudoIconButton(
                  onPressed: _showCreate,
                  style: IconButton.styleFrom(
                    backgroundColor: context.menudo.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: context.menudo.border),
                  ),
                  icon: Icon(
                    MenudoCupertinoIcons.plus,
                    color: context.menudo.textMain,
                    size: (18),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters().animate().fadeIn(
                    duration: 400.ms,
                    delay: 100.ms,
                  ),
                  SizedBox(height: (18)),

                  if (filteredBudgets.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredBudgets.asMap().entries.map((entry) {
                      final b = entry.value;
                      final globalIdx = budgets.indexOf(b);
                      return _BudgetCard(
                            budget: b,
                            isDashboardActive: globalIdx == selectedIdx,
                            onTap: () => _showDetail(b),
                            onSetActive: () async => _selectBudget(b),
                            fmt: _fmt,
                          )
                          .animate()
                          .fadeIn(
                            duration: 500.ms,
                            delay: (120 + entry.key * 90).ms,
                          )
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            curve: MenudoMotion.spring,
                          );
                    }),

                  SizedBox(height: (120)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: (34),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filtros.length,
        separatorBuilder: (_, _) => SizedBox(width: (10)),
        itemBuilder: (_, i) {
          final p = _filtros[i];
          final selected = p == _filtro;
          return MenudoGestureDetector(
            onTap: () {
              MenudoHaptics.selection();
              setState(() => _filtro = p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: MenudoMotion.spring,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? context.menudo.primary
                    : context.menudo.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected ? context.menudo.primary : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                p,
                style: TextStyle(
                  color: selected
                      ? context.menudo.surface
                      : context.menudo.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.menudo.border),
      ),
      child: Column(
        children: [
          Icon(
            MenudoCupertinoIcons.clipboardList,
            size: (36),
            color: context.menudo.textMuted,
          ),
          SizedBox(height: (14)),
          Text(
            "Todavía no tienes presupuestos aquí",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.menudo.textMain,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _filtro == "Todos"
                ? "Cuando crees uno, aparecerá aquí."
                : "No encontramos presupuestos en la vista '$_filtro'.",
            style: TextStyle(fontSize: 14, color: context.menudo.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BudgetOnboardingSheet extends StatelessWidget {
  final VoidCallback onCreateBudget;

  const _BudgetOnboardingSheet({required this.onCreateBudget});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
        decoration: BoxDecoration(
          color: context.menudo.background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: context.menudo.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: context.menudo.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _BudgetOnboardingHero(),
            const SizedBox(height: 18),
            Text(
              'Tu plan de dinero vive aquí',
              style: TextStyle(
                fontSize: 24,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: context.menudo.textMain,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Organiza categorías, define cuánto puedes gastar y comparte el plan solo con personas que acepten la invitación.',
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: context.menudo.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(
                  child: _BudgetOnboardingFeature(
                    icon: MenudoCupertinoIcons.layoutGrid,
                    label: 'Categorías',
                    color: AppColors.o5,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _BudgetOnboardingFeature(
                    icon: MenudoCupertinoIcons.pie_chart_rounded,
                    label: 'Plan',
                    color: AppColors.e6,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _BudgetOnboardingFeature(
                    icon: MenudoCupertinoIcons.users,
                    label: 'Amigos',
                    color: AppColors.b5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreateBudget,
                icon: const Icon(MenudoCupertinoIcons.plus),
                label: const Text('Crear mi primer presupuesto'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.menudo.primary,
                  foregroundColor: context.menudo.textOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  MenudoHaptics.light();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Explorar primero',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: context.menudo.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.06, end: 0),
    );
  }
}

class _BudgetOnboardingHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.menudo.border),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.o5.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  MenudoCupertinoIcons.pie_chart_rounded,
                  color: AppColors.o5,
                  size: 34,
                ),
                Positioned(
                  right: 10,
                  top: 12,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.e6,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.menudo.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BudgetHeroLine(widthFactor: 0.86, color: AppColors.e6),
                const SizedBox(height: 8),
                _BudgetHeroLine(widthFactor: 0.64, color: AppColors.o5),
                const SizedBox(height: 8),
                _BudgetHeroLine(
                  widthFactor: 0.74,
                  color: context.menudo.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetHeroLine extends StatelessWidget {
  final double widthFactor;
  final Color color;

  const _BudgetHeroLine({required this.widthFactor, required this.color});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _BudgetOnboardingFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BudgetOnboardingFeature({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.menudo.textMain,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final MenudoBudget budget;
  final bool isDashboardActive;
  final VoidCallback onTap;
  final VoidCallback onSetActive;
  final String Function(double) fmt;

  const _BudgetCard({
    required this.budget,
    required this.isDashboardActive,
    required this.onTap,
    required this.onSetActive,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final double spent = budget.totalSpent;
    final double remaining = budget.availableToSpend;
    final collaborators = budget.miembros
        .where(
          (member) => !member.isOwner && member.userId != budget.ownerUserId,
        )
        .toList();
    final isShared = collaborators.isNotEmpty;

    return MenudoGestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.menudo.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _BudgetMetaTag(
                              label: _budgetPeriodLabel(budget.periodo),
                            ),
                            if (isShared)
                              _BudgetMetaTag(
                                label:
                                    '${collaborators.length} colaborador${collaborators.length == 1 ? '' : 'es'}',
                              ),
                            if (isDashboardActive) const _BudgetActivePill(),
                          ],
                        ),
                        SizedBox(height: (10)),
                        Text(
                          budget.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.menudo.textMain,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isShared) ...[
                    SizedBox(width: (12)),
                    _buildAvatars(context, collaborators, isShared: isShared),
                  ],
                ],
              ),
              SizedBox(height: (18)),
              Text(
                'Disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.textMuted,
                ),
              ),
              SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmt(remaining),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: remaining < 0
                          ? AppColors.r5
                          : context.menudo.textMain,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Plan ${fmt(budget.ingresos)} · Gastado ${fmt(spent)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.menudo.textSecondary,
                ),
              ),
              SizedBox(height: (18)),
              Row(
                children: [
                  Expanded(
                    child: _BudgetFact(
                      label: 'Plan',
                      value: fmt(budget.ingresos),
                    ),
                  ),
                  SizedBox(width: (10)),
                  Expanded(
                    child: _BudgetFact(label: 'Gastado', value: fmt(spent)),
                  ),
                ],
              ),
              SizedBox(height: (18)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.menudo.textMain,
                        side: BorderSide(color: context.menudo.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Ver detalle',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SizedBox(width: (10)),
                  _DashboardToggleButton(
                    isActive: isDashboardActive,
                    onToggle: onSetActive,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatars(
    BuildContext context,
    List<BudgetMember> miembros, {
    required bool isShared,
  }) {
    if (miembros.isEmpty) {
      if (!isShared) return const SizedBox.shrink();
      return Container(
        width: (32),
        height: (32),
        decoration: BoxDecoration(
          color: context.menudo.successLight,
          shape: BoxShape.circle,
          border: Border.all(color: context.menudo.surface, width: 2),
        ),
        alignment: Alignment.center,
        child: Icon(
          MenudoCupertinoIcons.users,
          size: (14),
          color: context.menudo.textMain,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(miembros.length, (i) {
        final m = miembros[i];
        return Align(
          widthFactor: 0.7,
          child: Container(
            width: (32),
            height: (32),
            decoration: BoxDecoration(
              color: m.c,
              shape: BoxShape.circle,
              border: Border.all(color: context.menudo.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: context.menudo.background.withValues(alpha: 0.18),
                  blurRadius: 4,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              m.i,
              style: TextStyle(
                color: context.menudo.surface,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BudgetFact extends StatelessWidget {
  final String label;
  final String value;

  const _BudgetFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.menudo.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.menudo.textMuted,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.menudo.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _DashboardToggleButton({
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? context.menudo.primary : context.menudo.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? context.menudo.primary : context.menudo.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive
                  ? MenudoCupertinoIcons.checkCircle
                  : MenudoCupertinoIcons.layoutDashboard,
              size: (14),
              color: isActive
                  ? context.menudo.surface
                  : context.menudo.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              isActive ? "Activo" : "Usar",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive
                    ? context.menudo.surface
                    : context.menudo.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetMetaTag extends StatelessWidget {
  final String label;

  const _BudgetMetaTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: context.menudo.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _BudgetActivePill extends StatelessWidget {
  const _BudgetActivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.menudo.successLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Activo',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.e6,
        ),
      ),
    );
  }
}
