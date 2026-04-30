import 'dart:math';

import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';

import '../../../../core/data/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_presenter.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../../../auth/auth_state.dart';
import '../../../categories/providers/category_providers.dart';
import '../../../categories/presentation/categories_screen.dart';
import '../../budget_providers.dart';

class CreateBudgetWizard extends ConsumerStatefulWidget {
  const CreateBudgetWizard({super.key, this.initialBudget, this.initialStep});

  final MenudoBudget? initialBudget;
  final int? initialStep;

  @override
  ConsumerState<CreateBudgetWizard> createState() => _CreateBudgetWizardState();
}

class _CreateBudgetWizardState extends ConsumerState<CreateBudgetWizard> {
  final ScrollController _scrollController = ScrollController();
  int _step = 0;

  // Form Data
  String _nombre = "";
  String _periodo = "mensual";
  int _diaInicio = 1;
  final Map<int, String> _incomePlan = {};
  final Map<int, String> _expensePlan = {};
  String _savingsTarget = "";
  final List<String> _miembros = [];
  String _emailInput = "";
  bool _isSaving = false;

  bool get _isEditing => widget.initialBudget != null;
  bool get _canInviteMembers => !_isEditing;
  List<String> get _steps => _isEditing
      ? ["Básico", "Ingresos", "Gastos", "Ahorro"]
      : ["Básico", "Ingresos", "Gastos", "Ahorro", "Miembros", "Resumen"];
  int get _lastStepIndex => _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _seedInitialBudget();
    if (widget.initialStep != null) {
      _step = min(widget.initialStep!, _lastStepIndex);
    }
  }

  double _parseAmount(String? rawValue) {
    final normalized = rawValue?.replaceAll(',', '').trim() ?? '';
    return double.tryParse(normalized) ?? 0;
  }

  Map<int, BudgetCategory> _initialExpenseFallbacks() {
    final budget = widget.initialBudget;
    if (budget == null) return const {};
    return {
      for (final category in budget.cats.values)
        if (category.categoryId != null) category.categoryId!: category,
    };
  }

  Map<int, BudgetIncomeSource> _initialIncomeFallbacks() {
    final budget = widget.initialBudget;
    if (budget == null) return const {};
    return {
      for (final source in budget.incomeSources)
        if (source.categoryId != null) source.categoryId!: source,
    };
  }

  String _formatEditableAmount(double value) {
    if (value == 0) return '';
    return value.round().toString();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _seedInitialBudget() {
    final budget = widget.initialBudget;
    if (budget == null) return;

    _nombre = budget.nombre;
    _periodo = budget.periodo;
    _diaInicio = budget.diaInicio;
    _savingsTarget = _formatEditableAmount(budget.ahorroObjetivo);

    for (final entry in budget.incomePlan.entries) {
      _incomePlan[entry.key] = _formatEditableAmount(entry.value);
    }

    for (final category in budget.cats.values) {
      if (category.categoryId == null) continue;
      _expensePlan[category.categoryId!] = _formatEditableAmount(
        category.limite,
      );
    }
  }

  double _totalFrom(Map<int, String> values) {
    return values.values.fold(0.0, (sum, value) => sum + _parseAmount(value));
  }

  Map<MenudoCategory, List<MenudoCategory>> _resolvedGroups(
    List<MenudoCategory> categories,
  ) {
    final grouped = ref.read(groupedCategoriesProvider);
    if (grouped.isNotEmpty) {
      return grouped;
    }

    return {
      for (final category in categories.where((category) => !category.esParent))
        category: <MenudoCategory>[category],
    };
  }

  List<MapEntry<MenudoCategory, List<MenudoCategory>>> _sortedGroups(
    Iterable<MapEntry<MenudoCategory, List<MenudoCategory>>> entries,
  ) {
    final groups = entries.toList();
    groups.sort((a, b) => a.key.nombre.compareTo(b.key.nombre));
    return groups;
  }

  List<MapEntry<MenudoCategory, List<MenudoCategory>>> _incomeGroups(
    List<MenudoCategory> categories,
  ) {
    return _sortedGroups(
      _resolvedGroups(categories).entries.where((entry) {
        return entry.key.tipo == 'ingreso';
      }),
    );
  }

  List<MapEntry<MenudoCategory, List<MenudoCategory>>> _expenseGroups(
    List<MenudoCategory> categories,
  ) {
    return _sortedGroups(
      _resolvedGroups(categories).entries.where((entry) {
        return entry.key.tipo == 'gasto';
      }),
    );
  }

  Future<void> _showAddSubcategory(MenudoCategory parent) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(parent: parent),
    );
    if (mounted) {
      setState(() {});
    }
  }

  double get ing => _totalFrom(_incomePlan);
  double get gastos => _totalFrom(_expensePlan);
  double get aho => _parseAmount(_savingsTarget);
  double get sobrante => ing - gastos - aho;

  bool _isValidEmail(String value) {
    final normalized = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
  }

  void _addMemberEmail() {
    final normalized = _emailInput.trim().toLowerCase();
    if (normalized.isEmpty) return;
    if (!_isValidEmail(normalized)) {
      _showError('Ese correo no parece válido. Revísalo e inténtalo otra vez.');
      return;
    }
    if (_miembros.contains(normalized)) {
      _showError('Ese correo ya está agregado.');
      return;
    }
    if (_miembros.length >= 3) {
      _showError('Puedes invitar hasta 3 personas en total.');
      return;
    }

    setState(() {
      _miembros.add(normalized);
      _emailInput = '';
    });
  }

  bool _canNext() {
    switch (_step) {
      case 0:
        return _nombre.trim().isNotEmpty;
      case 1:
        return ing > 0;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return true;
      case 5:
        return true;
      default:
        return false;
    }
  }

  Future<void> _onNextOrSave() async {
    if (_step < _lastStepIndex) {
      setState(() => _step++);
    } else {
      await _saveBudget();
    }
  }

  Future<void> _saveBudget() async {
    if (_isSaving) return;

    final categories = ref.read(effectiveCategoriesProvider);
    final categoriesById = {
      for (final category in categories) category.id: category,
    };
    final initialExpenseFallbacks = _initialExpenseFallbacks();
    final initialIncomeFallbacks = _initialIncomeFallbacks();

    final configuredIncome = {
      for (final entry in _incomePlan.entries)
        if (_parseAmount(entry.value) > 0) entry.key: _parseAmount(entry.value),
    };
    final configuredLimits = {
      for (final entry in _expensePlan.entries)
        if (_parseAmount(entry.value) > 0) entry.key: _parseAmount(entry.value),
    };

    final missingIncomeCategories = configuredIncome.entries
        .where(
          (entry) =>
              entry.value > 0 &&
              !categoriesById.containsKey(entry.key) &&
              !initialIncomeFallbacks.containsKey(entry.key),
        )
        .map((entry) => '#${entry.key}')
        .toList();
    final missingExpenseCategories = configuredLimits.entries
        .where(
          (entry) =>
              entry.value > 0 &&
              !categoriesById.containsKey(entry.key) &&
              !initialExpenseFallbacks.containsKey(entry.key),
        )
        .map((entry) => '#${entry.key}')
        .toList();

    if (missingIncomeCategories.isNotEmpty ||
        missingExpenseCategories.isNotEmpty) {
      _showError(
        'Algunas categorías cambiaron. Revísalas antes de guardar el presupuesto.',
      );
      return;
    }

    final budgetCats = <String, BudgetCategory>{};
    for (final entry in configuredLimits.entries) {
      final category = categoriesById[entry.key];
      final fallback = initialExpenseFallbacks[entry.key];
      if (category != null) {
        budgetCats[category.slug] = BudgetCategory(
          categoryId: category.id,
          parentCategoryId: category.categoriaParadreId,
          slug: category.slug,
          tipo: category.tipo,
          label: category.nombre,
          icono: category.icono,
          color: category.color,
          limite: entry.value,
        );
        continue;
      }
      if (fallback?.slug != null && fallback!.slug!.isNotEmpty) {
        budgetCats[fallback.slug!] = BudgetCategory(
          categoryId: fallback.categoryId,
          parentCategoryId: fallback.parentCategoryId,
          slug: fallback.slug,
          tipo: fallback.tipo,
          label: fallback.label,
          icono: fallback.icono,
          color: fallback.color,
          limite: entry.value,
        );
      }
    }

    final budget = MenudoBudget(
      id: widget.initialBudget?.id ?? 0,
      espacioId: widget.initialBudget?.espacioId,
      nombre: _nombre.trim(),
      periodo: _periodo,
      diaInicio: _diaInicio,
      activo: widget.initialBudget?.activo ?? true,
      miembros: [],
      ingresos: ing,
      ahorroObjetivo: aho,
      cats: budgetCats,
      incomePlan: configuredIncome,
    );

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(budgetNotifierProvider.notifier);
      final categoryMap = {
        for (final category in categories) category.slug: category.id,
      };
      if (_isEditing) {
        await notifier.updateBudget(budget, categoryMap, configuredIncome);
      } else {
        await notifier.createBudget(
          budget,
          categoryMap,
          configuredIncome,
          invitedEmails: _miembros,
        );
      }
      if (!mounted) return;
      MenudoHaptics.success();
      Navigator.pop(context, true);
    } catch (error) {
      _showError(presentError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  void _setPeriod(String value) {
    setState(() {
      _periodo = value;
      switch (value) {
        case 'mensual':
          _diaInicio = _diaInicio.clamp(1, 28);
          break;
        case 'quincenal':
          _diaInicio = _diaInicio >= 15 ? 15 : 1;
          break;
        case 'semanal':
        case 'unico':
          _diaInicio = 1;
          break;
      }
    });
  }

  String _periodSummaryLabel() {
    return switch (_periodo) {
      'semanal' => 'Semanal',
      'quincenal' => 'Quincenal',
      'unico' => 'Puntual',
      _ => 'Mensual',
    };
  }

  String _periodStartSummary() {
    return switch (_periodo) {
      'semanal' => 'Últimos 7 días',
      'unico' => 'Desde creación',
      'quincenal' => _diaInicio == 15 ? 'Desde día 15' : 'Desde día 1',
      _ => 'Día $_diaInicio',
    };
  }

  Widget _buildPeriodStartSelector() {
    if (_periodo == 'semanal') {
      return _BudgetHintCard(
        icon: MenudoCupertinoIcons.calendarDays,
        title: 'Semana móvil',
        body: 'Siempre tomará los últimos 7 días.',
      );
    }

    if (_periodo == 'unico') {
      return _BudgetHintCard(
        icon: MenudoCupertinoIcons.flag,
        title: 'Una sola vez',
        body: 'Empieza cuando lo creas. No necesita un día de inicio.',
      );
    }

    final options = _periodo == 'quincenal'
        ? [1, 15]
        : List<int>.generate(28, (index) => index + 1);
    final title = _periodo == 'quincenal'
        ? 'Inicio del ciclo'
        : 'Día de inicio';
    final subtitle = _periodo == 'quincenal'
        ? 'Elige desde qué día empieza cada bloque.'
        : 'Ese día marcará el inicio de cada ciclo.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.menudo.textSecondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: context.menudo.textMuted),
        ),
        SizedBox(height: (10)),
        if (_periodo == 'quincenal')
          Row(
            children: options.map((day) {
              final selected = _diaInicio == day;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: day == options.last ? 0 : 12),
                  child: MenudoGestureDetector(
                    onTap: () => setState(() => _diaInicio = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? context.menudo.primary
                            : context.menudo.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? context.menudo.primary
                              : context.menudo.border,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Día $day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : context.menudo.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        else
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
            children: options.map((day) {
              final selected = _diaInicio == day;
              return MenudoGestureDetector(
                onTap: () => setState(() => _diaInicio = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.menudo.primary
                        : context.menudo.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? context.menudo.primary
                          : context.menudo.border,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : context.menudo.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.menudo.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(bottom: 14),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MenudoGestureDetector(
                      onTap: () {
                        if (_step == 0) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _step--);
                        }
                      },
                      child: Container(
                        width: (30),
                        height: (30),
                        decoration: BoxDecoration(
                          color: context.menudo.surface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _step == 0
                              ? MenudoCupertinoIcons.close
                              : MenudoCupertinoIcons.arrow_back,
                          size: (16),
                          color: context.menudo.textSecondary,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        _steps.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          height: 8,
                          width: index <= _step ? 20 : 8,
                          decoration: BoxDecoration(
                            color: index < _step
                                ? context.menudo.primary
                                : index == _step
                                ? AppColors.o5
                                : context.menudo.border,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      "${_step + 1}/${_steps.length}",
                      style: TextStyle(
                        fontSize: 12,
                        color: context.menudo.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: (24)),

          Expanded(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardBottom > 0 ? 20 : 0),
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCurrentStep(),
              ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.menudo.divider)),
            ),
            child: _step == _lastStepIndex || _isSaving
                ? MenudoButton(
                    label: _isSaving
                        ? (_isEditing
                            ? "Guardando presupuesto..."
                            : "Creando presupuesto...")
                        : (_isEditing
                            ? "Guardar presupuesto"
                            : _miembros.isNotEmpty
                                ? "Crear e invitar"
                                : "Crear presupuesto"),
                    isFullWidth: true,
                    isDisabled: !_canNext() || _isSaving,
                    onTap: () => _onNextOrSave(),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.menudo.surface,
                      foregroundColor: context.menudo.textMain,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: context.menudo.border, width: 2),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (!_canNext() || _isSaving) ? null : () => _onNextOrSave(),
                    child: Text(
                      "Siguiente \u2192",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _isEditing ? _buildStep5() : _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return SizedBox();
    }
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? "Editar presupuesto" : "Nuevo presupuesto",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _isEditing
              ? "Ajusta el nombre o el período cuando lo necesites."
              : "Ponle un nombre y elige cómo quieres organizarlo.",
          style: TextStyle(fontSize: 14, color: context.menudo.textMuted),
        ),
        SizedBox(height: (24)),

        Text(
          "Nombre",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.menudo.textSecondary,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          onChanged: (v) => setState(() => _nombre = v),
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: _nombre,
              selection: TextSelection.collapsed(offset: _nombre.length),
            ),
          ),
          decoration: InputDecoration(
            hintText: "ej: Hogar Abril, Viaje, Personal",
            hintStyle: TextStyle(
              color: context.menudo.textMuted,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: context.menudo.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.menudo.border, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.menudo.textMain, width: 2),
            ),
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.menudo.textMain,
          ),
        ),

        SizedBox(height: (16)),
        Text(
          "Período",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.menudo.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children:
              [
                    {"v": "semanal", "l": "Semanal"},
                    {"v": "quincenal", "l": "Quincenal"},
                    {"v": "mensual", "l": "Mensual"},
                    if (_isEditing && _periodo == 'unico')
                      {"v": "unico", "l": "Puntual"},
                  ]
                  .map(
                    (p) => MenudoGestureDetector(
                      onTap: () => _setPeriod(p["v"]!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _periodo == p["v"]
                              ? context.menudo.primary.withValues(alpha: 0.1)
                              : context.menudo.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _periodo == p["v"]
                                ? context.menudo.primary
                                : context.menudo.border,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p["l"]!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _periodo == p["v"]
                                ? context.menudo.primary
                                : context.menudo.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),

        SizedBox(height: (16)),
        _buildPeriodStartSelector(),
      ],
    );
  }

  Widget _buildPlannedAmountCard({
    required String label,
    required String subtitle,
    required double amount,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              fmt(amount),
              key: ValueKey(amount.round()),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -1.2,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPlannerGroup({
    required MenudoCategory parent,
    required List<MenudoCategory> categories,
    required Map<int, String> values,
    required bool showPercent,
    required double totalBase,
  }) {
    final isCompactAmountLayout = MediaQuery.of(context).size.width < 390;
    final sortedCategories = [...categories]
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final groupTotal = sortedCategories.fold<double>(
      0,
      (sum, category) => sum + _parseAmount(values[category.id]),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        border: Border.all(color: context.menudo.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: parent.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(parent.icono, color: parent.color, size: (20)),
              ),
              SizedBox(width: (12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.nombre,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.menudo.textMain,
                      ),
                    ),
                    Text(
                      sortedCategories.isEmpty
                          ? 'Aún no agregas categorías'
                          : '${sortedCategories.length} opciones',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.menudo.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (groupTotal > 0)
                MenudoChip.custom(
                  label: fmt(groupTotal),
                  color: parent.color,
                  isSmall: true,
                ),
              SizedBox(width: 8),
              MenudoGestureDetector(
                onTap: () => _showAddSubcategory(parent),
                child: Container(
                  width: (34),
                  height: (34),
                  decoration: BoxDecoration(
                    color: parent.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    MenudoCupertinoIcons.plus,
                    size: (16),
                    color: parent.color,
                  ),
                ),
              ),
            ],
          ),
          if (sortedCategories.isEmpty) ...[
            SizedBox(height: (14)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.menudo.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Agrega una categoría aquí para poder asignarle un monto.',
                style: TextStyle(fontSize: 13, color: context.menudo.textMuted),
              ),
            ),
          ] else ...[
            SizedBox(height: (14)),
            ...sortedCategories.map((category) {
              final amount = _parseAmount(values[category.id]);
              final pct = totalBase > 0
                  ? (amount / totalBase * 100).round()
                  : 0;
              final currentValue = values[category.id] ?? '';
              final amountEditor = Container(
                width: isCompactAmountLayout ? double.infinity : 118,
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.menudo.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.18),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BudgetAmountField(
                      value: currentValue,
                      onChanged: (value) {
                        setState(() => values[category.id] = value);
                      },
                      textAlign: isCompactAmountLayout
                          ? TextAlign.start
                          : TextAlign.end,
                      textStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.menudo.textMain,
                      ),
                      prefixText: 'RD\$ ',
                      prefixStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.menudo.textMuted,
                      ),
                      hintText: '',
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      borderRadius: 12,
                      borderless: true,
                    ),
                  ],
                ),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: isCompactAmountLayout
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: (38),
                                height: (38),
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  category.icono,
                                  color: category.color,
                                  size: (18),
                                ),
                              ),
                              SizedBox(width: (12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.nombre,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: context.menudo.textMain,
                                      ),
                                    ),
                                    if (showPercent && amount > 0)
                                      Text(
                                        '$pct% del total',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.menudo.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: (10)),
                          amountEditor,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: (38),
                            height: (38),
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              category.icono,
                              color: category.color,
                              size: (18),
                            ),
                          ),
                          SizedBox(width: (12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.nombre,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.menudo.textMain,
                                  ),
                                ),
                                if (showPercent && amount > 0)
                                  Text(
                                    '$pct% del total',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.menudo.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: (12)),
                          amountEditor,
                        ],
                      ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final categories = ref.watch(effectiveCategoriesProvider);
    final incomeGroups = _incomeGroups(categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ingresos",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Define de dónde entra el dinero.",
          style: TextStyle(fontSize: 14, color: context.menudo.textMuted),
        ),
        SizedBox(height: (20)),
        _buildPlannedAmountCard(
          label: "MONTO DE INGRESOS",
          subtitle: "Se calcula con las fuentes que agregues abajo.",
          amount: ing,
          backgroundColor: context.menudo.successLight,
          borderColor: AppColors.e7.withValues(alpha: 0.13),
          textColor: AppColors.e7,
        ),
        SizedBox(height: (18)),
        if (incomeGroups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.menudo.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.menudo.border, width: 1.5),
            ),
            child: Text(
              'Cuando tengas categorías de ingresos, podrás repartir el monto aquí.',
              style: TextStyle(fontSize: 13, color: context.menudo.textMuted),
            ),
          )
        else
          ...incomeGroups.map(
            (group) => _buildCategoryPlannerGroup(
              parent: group.key,
              categories: group.value,
              values: _incomePlan,
              showPercent: false,
              totalBase: ing,
            ),
          ),
      ],
    );
  }

  Widget _buildStep2() {
    final categories = ref.watch(effectiveCategoriesProvider);
    final expenseGroups = _expenseGroups(categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gastos",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Elige cuánto quieres asignar a cada categoría.",
          style: TextStyle(fontSize: 14, color: context.menudo.textMuted),
        ),
        SizedBox(height: (16)),

        if (ing > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.menudo.background,
              border: Border.all(color: context.menudo.border, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ingresos totales",
                  style: TextStyle(
                    fontSize: 13,
                    color: context.menudo.textMuted,
                  ),
                ),
                Text(
                  fmt(ing),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.menudo.textMain,
                  ),
                ),
              ],
            ),
          ),

        if (expenseGroups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.menudo.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.menudo.border, width: 1.5),
            ),
            child: Text(
              'Cuando tengas categorías de gastos, podrás repartir el plan aquí.',
              style: TextStyle(fontSize: 13, color: context.menudo.textMuted),
            ),
          )
        else
          ...expenseGroups.map(
            (group) => _buildCategoryPlannerGroup(
              parent: group.key,
              categories: group.value,
              values: _expensePlan,
              showPercent: true,
              totalBase: ing > 0 ? ing : gastos,
            ),
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ahorro",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.menudo.textMain,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "¿Cuánto quieres apartar este período?",
          style: TextStyle(fontSize: 14, color: context.menudo.textMuted),
        ),
        SizedBox(height: (20)),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            color: context.menudo.warningLight,
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.13),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "META DE AHORRO",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.a5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Escribe cuanto quieres reservar en este periodo.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.a5,
                  height: 1.35,
                ),
              ),
              SizedBox(height: (16)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.menudo.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.menudo.warningLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        MenudoCupertinoIcons.wallet,
                        size: (20),
                        color: AppColors.a5,
                      ),
                    ),
                    SizedBox(width: (12)),
                    Expanded(
                      child: _BudgetAmountField(
                        value: _savingsTarget,
                        onChanged: (value) =>
                            setState(() => _savingsTarget = value),
                        textAlign: TextAlign.start,
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.a5,
                        ),
                        prefixText: 'RD\$ ',
                        prefixStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.a5,
                        ),
                        hintText: '',
                        fillColor: Colors.transparent,
                        borderRadius: 0,
                        borderless: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: (12)),
              Text(
                'Si lo dejas vacio, este periodo quedara sin meta de ahorro.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.menudo.textMuted,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: (16)),
        if (ing > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.menudo.surface,
              border: Border.all(color: context.menudo.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Resumen del período",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.menudo.textSecondary,
                  ),
                ),
                SizedBox(height: (10)),
                ...[
                  {
                    'label': 'Gastos planificados',
                    'val': gastos,
                    'color': context.menudo.textMain,
                  },
                  {'label': 'Ahorro', 'val': aho, 'color': AppColors.a5},
                ].where((entry) => (entry['val'] as double) > 0).map((entry) {
                  final v = entry['val'] as double;
                  final pct = ing > 0 ? (v / ing * 100).round() : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.menudo.textSecondary,
                              ),
                            ),
                            Text(
                              "$pct%",
                              style: TextStyle(
                                fontSize: 12,
                                color: context.menudo.textMain,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3),
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: context.menudo.surface,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          alignment: Alignment.centerLeft,
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              return Container(
                                height: 5,
                                width: constraints.maxWidth * min(v / ing, 1.0),
                                decoration: BoxDecoration(
                                  color: entry['color'] as Color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.menudo.divider),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Disponible",
                        style: TextStyle(
                          fontSize: 13,
                          color: context.menudo.textMuted,
                        ),
                      ),
                      Text(
                        fmt(sobrante),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: sobrante >= 0 ? AppColors.e6 : AppColors.r5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStepHeading({
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: (20)),
        ),
        SizedBox(width: (12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.textMain,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: context.menudo.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    final profile = ref.watch(authProvider).profile;
    final currentUserName = profile?.name.isNotEmpty == true
        ? profile!.name
        : 'Tu usuario';
    final initials = currentUserName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeading(
          icon: MenudoCupertinoIcons.groups_rounded,
          iconColor: context.menudo.textMain,
          iconBackgroundColor: context.menudo.successLight,
          title: "Miembros",
          subtitle: _canInviteMembers
              ? "Agrega hasta 3 correos para compartirlo."
              : "Aquí puedes revisar quién tendrá acceso.",
        ),
        SizedBox(height: (20)),

        if (!_canInviteMembers)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.menudo.successLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.menudo.border),
            ),
            child: Text(
              "Si luego quieres sumar a alguien, podrás hacerlo desde el presupuesto.",
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: context.menudo.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.menudo.surface,
            border: Border.all(color: context.menudo.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.menudo.textMain,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.isEmpty ? 'T' : initials,
                  style: TextStyle(
                    color: context.menudo.surface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: (12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUserName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.menudo.textMain,
                    ),
                  ),
                  Text(
                    "Tú",
                    style: TextStyle(
                      fontSize: 12,
                      color: context.menudo.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_canInviteMembers)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.menudo.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.menudo.primaryLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  MenudoCupertinoIcons.mail_outline_rounded,
                  color: AppColors.o5,
                  size: (18),
                ),
                SizedBox(width: (10)),
                Expanded(
                  child: Text(
                    _miembros.isEmpty
                        ? "Las invitaciones se enviarán cuando termines de crear el presupuesto."
                        : "${_miembros.length} invitación${_miembros.length == 1 ? '' : 'es'} lista${_miembros.length == 1 ? '' : 's'} para salir cuando lo crees.",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: context.menudo.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ...List.generate(_miembros.length, (i) {
          final m = _miembros[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.menudo.surface,
              border: Border.all(color: context.menudo.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.o5,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    m.isNotEmpty ? m[0].toUpperCase() : "?",
                    style: TextStyle(
                      color: context.menudo.surface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: (12)),
                Expanded(
                  child: Text(
                    m,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.menudo.textMain,
                    ),
                  ),
                ),
                MenudoGestureDetector(
                  onTap: () => setState(() => _miembros.removeAt(i)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.menudo.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      MenudoCupertinoIcons.x,
                      size: (14),
                      color: AppColors.r5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        if (_canInviteMembers && _miembros.length < 3)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.menudo.background,
              border: Border.all(
                color: context.menudo.border,
                style: BorderStyle.none,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            // Note: drawing dashed borders is complex in flutter natively without a package, so I'll just use solid border for now
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Agregar correo",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.menudo.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _emailInput = v),
                        controller: TextEditingController.fromValue(
                          TextEditingValue(
                            text: _emailInput,
                            selection: TextSelection.collapsed(
                              offset: _emailInput.length,
                            ),
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText: "correo@ejemplo.com",
                          filled: true,
                          fillColor: context.menudo.surface,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: context.menudo.border,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: context.menudo.textMain,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    MenudoGestureDetector(
                      onTap: _addMemberEmail,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ), // matched visually to textfield height roughly
                        decoration: BoxDecoration(
                          color: context.menudo.textMain,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "+",
                          style: TextStyle(
                            color: context.menudo.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStep5() {
    final categoriesById = {
      for (final category in ref.watch(effectiveCategoriesProvider))
        category.id: category,
    };
    final incomeEntries =
        _incomePlan.entries
            .map((entry) => MapEntry(entry.key, _parseAmount(entry.value)))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final expenseEntries =
        _expensePlan.entries
            .map((entry) => MapEntry(entry.key, _parseAmount(entry.value)))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeading(
          icon: MenudoCupertinoIcons.task_alt_rounded,
          iconColor: AppColors.o5,
          iconBackgroundColor: context.menudo.primaryLight,
          title: "Resumen",
          subtitle: "Revisa lo importante antes de terminar.",
        ),
        SizedBox(height: (20)),

        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.menudo.textMain,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Así quedará",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.menudo.surface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 4),
              Text(
                _nombre.isEmpty ? "Tu presupuesto" : _nombre,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.menudo.surface,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  MenudoChip.custom(
                    label: _periodSummaryLabel(),
                    color: context.menudo.surface.withValues(alpha: 0.8),
                    bgColor: context.menudo.surface.withValues(alpha: 0.15),
                    isSmall: true,
                  ),
                  SizedBox(width: 8),
                  MenudoChip.custom(
                    label: _periodStartSummary(),
                    color: context.menudo.surface.withValues(alpha: 0.8),
                    bgColor: context.menudo.surface.withValues(alpha: 0.15),
                    isSmall: true,
                  ),
                ],
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.menudo.surface,
            border: Border.all(color: context.menudo.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ingresos",
                    style: TextStyle(
                      fontSize: 13,
                      color: context.menudo.textMuted,
                    ),
                  ),
                  Text(
                    fmt(ing),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.e6,
                    ),
                  ),
                ],
              ),
              SizedBox(height: (10)),
              ...incomeEntries.map((entry) {
                final category = categoriesById[entry.key];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category?.nombre ?? 'Ingreso #${entry.key}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.menudo.textMuted,
                        ),
                      ),
                      Text(
                        fmt(entry.value),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.e6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (expenseEntries.isNotEmpty) ...[
                SizedBox(height: (10)),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: context.menudo.divider,
                ),
                SizedBox(height: (9)),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        "Gastos",
                        style: TextStyle(
                          fontSize: 13,
                          color: context.menudo.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ...expenseEntries.map((entry) {
                final category = categoriesById[entry.key];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category?.nombre ?? 'Gasto #${entry.key}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.menudo.textMuted,
                        ),
                      ),
                      Text(
                        fmt(entry.value),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.menudo.textMain,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (aho > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ahorro",
                        style: TextStyle(
                          fontSize: 13,
                          color: context.menudo.textMuted,
                        ),
                      ),
                      Text(
                        fmt(aho),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              Divider(height: 1, thickness: 0.5, color: context.menudo.divider),
              SizedBox(height: (19)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Disponible",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.menudo.textSecondary,
                    ),
                  ),
                  Text(
                    fmt(sobrante),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: sobrante >= 0 ? AppColors.e6 : AppColors.r5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_miembros.isNotEmpty) ...[
          SizedBox(height: (12)),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.menudo.surface,
              border: Border.all(color: context.menudo.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Invitaciones",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.menudo.textSecondary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Se enviarán al guardar.",
                  style: TextStyle(
                    fontSize: 12,
                    color: context.menudo.textMuted,
                  ),
                ),
                SizedBox(height: (12)),
                ..._miembros.map((email) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.o5,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: (10)),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.menudo.textMain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BudgetHintCard extends StatelessWidget {
  const _BudgetHintCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.menudo.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.menudo.successLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: (36),
            height: (36),
            decoration: BoxDecoration(
              color: context.menudo.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: (18), color: context.menudo.textMain),
          ),
          SizedBox(width: (12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.menudo.textMain,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: context.menudo.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetAmountField extends StatefulWidget {
  const _BudgetAmountField({
    required this.value,
    required this.onChanged,
    required this.textStyle,
    required this.hintText,
    required this.fillColor,
    required this.contentPadding,
    this.prefixText,
    this.prefixStyle,
    this.textAlign = TextAlign.start,
    this.borderRadius = 12,
    this.borderless = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final TextStyle textStyle;
  final String hintText;
  final Color fillColor;
  final EdgeInsetsGeometry contentPadding;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final TextAlign textAlign;
  final double borderRadius;
  final bool borderless;

  @override
  State<_BudgetAmountField> createState() => _BudgetAmountFieldState();
}

class _BudgetAmountFieldState extends State<_BudgetAmountField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(
      text: _formatBudgetNumber(widget.value),
    );
  }

  @override
  void didUpdateWidget(covariant _BudgetAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;

    final formatted = _formatBudgetNumber(widget.value);
    if (_controller.text == formatted) return;

    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final raw = _sanitizeBudgetNumber(value);
    final formatted = _formatBudgetNumber(raw);

    if (_controller.text != formatted) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    widget.onChanged(raw);
  }

  Future<void> _ensureVisible() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!mounted) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 220),
      alignment: 0.2,
      curve: Curves.easeOut,
    );
  }

  Future<void> _focusAndShowKeyboard() async {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    await _ensureVisible();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.borderless
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(color: context.menudo.border, width: 1.8),
          );
    final focusedBorder = widget.borderless
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(color: context.menudo.textMain, width: 2),
          );

    return TextField(
      focusNode: _focusNode,
      controller: _controller,
      onChanged: _handleChanged,
      onTap: _focusAndShowKeyboard,
      onTapOutside: (_) => _focusNode.unfocus(),
      showCursor: true,
      keyboardType: const TextInputType.numberWithOptions(
        signed: false,
        decimal: false,
      ),
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
      enableSuggestions: false,
      autocorrect: false,
      scrollPadding: const EdgeInsets.only(bottom: 140),
      textAlign: widget.textAlign,
      style: widget.textStyle,
      decoration: InputDecoration(
        prefixText: widget.prefixText,
        prefixStyle: widget.prefixStyle,
        hintText: widget.hintText,
        filled: true,
        fillColor: widget.fillColor,
        isDense: true,
        contentPadding: widget.contentPadding,
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
      ),
    );
  }
}

String _sanitizeBudgetNumber(String value) {
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) return '';
  final trimmed = digitsOnly.length > 9
      ? digitsOnly.substring(0, 9)
      : digitsOnly;
  final normalized = trimmed.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  return normalized;
}

String _formatBudgetNumber(String value) {
  final raw = _sanitizeBudgetNumber(value);
  if (raw.isEmpty) return '';
  return raw.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}
