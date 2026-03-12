import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/data/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_chip.dart';
import '../../../auth/auth_state.dart';
import '../../../categories/providers/category_providers.dart';
import '../../../categories/presentation/categories_screen.dart';
import '../../budget_providers.dart';

class CreateBudgetWizard extends ConsumerStatefulWidget {
  const CreateBudgetWizard({super.key, this.initialBudget});

  final MenudoBudget? initialBudget;

  @override
  ConsumerState<CreateBudgetWizard> createState() => _CreateBudgetWizardState();
}

class _CreateBudgetWizardState extends ConsumerState<CreateBudgetWizard> {
  int _step = 0;
  final List<String> _steps = [
    "Básico",
    "Ingresos",
    "Gastos",
    "Ahorro",
    "Miembros",
    "Resumen",
  ];

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

  @override
  void initState() {
    super.initState();
    _seedInitialBudget();
  }

  double _parseAmount(String? rawValue) {
    final normalized = rawValue?.replaceAll(',', '').trim() ?? '';
    return double.tryParse(normalized) ?? 0;
  }

  String _formatEditableAmount(double value) {
    if (value == 0) return '';
    final raw = value.truncateToDouble() == value
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return raw.replaceFirst(RegExp(r'([.]0+)?$'), '');
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
      _showError('Escribe un correo válido antes de agregarlo.');
      return;
    }
    if (_miembros.contains(normalized)) {
      _showError('Ese correo ya está agregado.');
      return;
    }
    if (_miembros.length >= 3) {
      _showError('Solo puedes invitar hasta 3 personas.');
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
    if (_step < 5) {
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
          (entry) => entry.value > 0 && !categoriesById.containsKey(entry.key),
        )
        .map((entry) => '#${entry.key}')
        .toList();
    final missingExpenseCategories = configuredLimits.entries
        .where(
          (entry) => entry.value > 0 && !categoriesById.containsKey(entry.key),
        )
        .map((entry) => '#${entry.key}')
        .toList();

    if (missingIncomeCategories.isNotEmpty ||
        missingExpenseCategories.isNotEmpty) {
      _showError(
        'Faltan categorías en el backend para este presupuesto. Revisa los datos antes de guardar.',
      );
      return;
    }

    final budgetCats = <String, BudgetCategory>{};
    for (final entry in configuredLimits.entries) {
      final category = categoriesById[entry.key]!;
      budgetCats[category.slug] = BudgetCategory(
        categoryId: category.id,
        label: category.nombre,
        icono: category.icono,
        color: category.color,
        limite: entry.value,
      );
    }

    final budget = MenudoBudget(
      id: widget.initialBudget?.id ?? 0,
      espacioId: widget.initialBudget?.espacioId,
      nombre: _nombre.trim(),
      periodo: _periodo,
      diaInicio: _diaInicio,
      activo: widget.initialBudget?.activo ?? true,
      miembros: const [],
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
      Navigator.pop(context, true);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String fmt(double val) =>
      "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
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
                    color: AppColors.g2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(bottom: 14),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_step == 0) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _step--);
                        }
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.g1,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _step == 0 ? Icons.close : Icons.arrow_back,
                          size: 16,
                          color: AppColors.g5,
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
                                ? AppColors.e8
                                : index == _step
                                ? AppColors.o5
                                : AppColors.g2,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      "${_step + 1}/${_steps.length}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.g4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCurrentStep(),
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
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: MenudoButton(
              label: _isSaving
                  ? (_isEditing ? "GUARDANDO..." : "CREANDO...")
                  : _step == 5
                  ? (_isEditing
                        ? "Guardar presupuesto"
                        : _miembros.isNotEmpty
                        ? "Crear e invitar"
                        : "Crear presupuesto")
                  : "Siguiente \u2192", // right arrow
              isFullWidth: true,
              isDisabled: !_canNext() || _isSaving,
              onTap: () => _onNextOrSave(),
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
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? "Configurar presupuesto" : "Nuevo presupuesto",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.e8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "¿Cómo se llamará y qué período tendrá?",
          style: TextStyle(fontSize: 14, color: AppColors.g4),
        ),
        const SizedBox(height: 24),

        const Text(
          "Nombre",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.g5,
          ),
        ),
        const SizedBox(height: 6),
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
            hintStyle: const TextStyle(
              color: AppColors.g3,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: AppColors.g0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.g2, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.e8, width: 2),
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.e8,
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          "Período",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.g5,
          ),
        ),
        const SizedBox(height: 8),
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
                    {"v": "unico", "l": "Único"},
                  ]
                  .map(
                    (p) => GestureDetector(
                      onTap: () => setState(() => _periodo = p["v"]!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _periodo == p["v"]
                              ? AppColors.e0
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _periodo == p["v"]
                                ? AppColors.e8
                                : AppColors.g2,
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
                                ? AppColors.e8
                                : AppColors.g5,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),

        const SizedBox(height: 16),
        const Text(
          "Día de inicio",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.g5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 5, 10, 15, 20, 25, 30]
              .map(
                (d) => GestureDetector(
                  onTap: () => setState(() => _diaInicio = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _diaInicio == d ? AppColors.e8 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _diaInicio == d ? AppColors.e8 : AppColors.g2,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      d.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _diaInicio == d ? Colors.white : AppColors.g5,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
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
          const SizedBox(height: 6),
          Text(
            fmt(amount),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 4),
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
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
                child: Icon(parent.icono, color: parent.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.e8,
                      ),
                    ),
                    Text(
                      sortedCategories.isEmpty
                          ? 'Sin subcategorías todavía'
                          : '${sortedCategories.length} opciones',
                      style: const TextStyle(fontSize: 12, color: AppColors.g4),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showAddSubcategory(parent),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: parent.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.plus, size: 16, color: parent.color),
                ),
              ),
            ],
          ),
          if (sortedCategories.isEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.g0,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Agrega una subcategoría dentro de este grupo para poder asignarle un monto.',
                style: TextStyle(fontSize: 13, color: AppColors.g4),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            ...sortedCategories.map((category) {
              final amount = _parseAmount(values[category.id]);
              final pct = totalBase > 0
                  ? (amount / totalBase * 100).round()
                  : 0;
              final currentValue = values[category.id] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        category.icono,
                        color: category.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.e8,
                            ),
                          ),
                          if (showPercent && amount > 0)
                            Text(
                              '$pct% del total',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.g4,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 118,
                      child: TextField(
                        onChanged: (value) {
                          setState(() => values[category.id] = value);
                        },
                        controller: TextEditingController.fromValue(
                          TextEditingValue(
                            text: currentValue,
                            selection: TextSelection.collapsed(
                              offset: currentValue.length,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.e8,
                        ),
                        decoration: InputDecoration(
                          prefixText: 'RD\$ ',
                          prefixStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.g4,
                          ),
                          hintText: '0',
                          filled: true,
                          fillColor: AppColors.g0,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: category.color.withValues(alpha: 0.18),
                              width: 1.8,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: category.color,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
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
        const Text(
          "Ingresos",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.e8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Asigna tus ingresos por categoría y subcategoría.",
          style: TextStyle(fontSize: 14, color: AppColors.g4),
        ),
        const SizedBox(height: 20),
        _buildPlannedAmountCard(
          label: "MONTO DE INGRESOS",
          subtitle: "El total se calcula con las fuentes que asignes abajo.",
          amount: ing,
          backgroundColor: AppColors.e0,
          borderColor: AppColors.e7.withValues(alpha: 0.13),
          textColor: AppColors.e7,
        ),
        const SizedBox(height: 18),
        if (incomeGroups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.g0,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.g2, width: 1.5),
            ),
            child: const Text(
              'No hay categorías de ingreso disponibles todavía. Crea o sincroniza al menos un grupo de ingresos desde el backend.',
              style: TextStyle(fontSize: 13, color: AppColors.g4),
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
        const Text(
          "Gastos",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.e8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Primero ves el grupo padre y debajo eliges sus subcategorías.",
          style: TextStyle(fontSize: 14, color: AppColors.g4),
        ),
        const SizedBox(height: 16),

        if (ing > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.g0,
              border: Border.all(color: AppColors.g2, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ingresos totales",
                  style: TextStyle(fontSize: 13, color: AppColors.g4),
                ),
                Text(
                  fmt(ing),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.e8,
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
              color: AppColors.g0,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.g2, width: 1.5),
            ),
            child: const Text(
              'No hay grupos de gastos disponibles desde el backend. Verifica la jerarquía de categorías.',
              style: TextStyle(fontSize: 13, color: AppColors.g4),
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
        const Text(
          "Ahorro",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.e8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "¿Cuánto quieres apartar este período?",
          style: TextStyle(fontSize: 14, color: AppColors.g4),
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.a1,
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.13),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                "META DE AHORRO",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.a5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "RD\$",
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.a5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IntrinsicWidth(
                    child: TextField(
                      onChanged: (v) => setState(() => _savingsTarget = v),
                      controller: TextEditingController.fromValue(
                        TextEditingValue(
                          text: _savingsTarget,
                          selection: TextSelection.collapsed(
                            offset: _savingsTarget.length,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.a5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "0",
                        hintStyle: TextStyle(color: AppColors.a5),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        if (ing > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Distribución",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.g5,
                  ),
                ),
                const SizedBox(height: 10),
                ...[
                  {
                    'label': 'Gastos planificados',
                    'val': gastos,
                    'color': AppColors.e8,
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.g5,
                              ),
                            ),
                            Text(
                              "$pct%",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.e8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.g1,
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
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sin asignar",
                        style: TextStyle(fontSize: 13, color: AppColors.g4),
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
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.e8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: AppColors.g4),
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
          icon: Icons.groups_rounded,
          iconColor: AppColors.e8,
          iconBackgroundColor: AppColors.e1,
          title: "Miembros",
          subtitle: _canInviteMembers
              ? "Agrega hasta 3 correos. Se enviarán al crear el presupuesto."
              : "La colaboración nueva se define al crear el presupuesto.",
        ),
        const SizedBox(height: 20),

        if (!_canInviteMembers)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.e1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.g2),
            ),
            child: const Text(
              "Los miembros actuales se gestionan desde el detalle del presupuesto. En esta edición puedes actualizar nombre, ingresos y límites, pero este backend no agrega invitados nuevos vía update.",
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.e8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.e8,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.isEmpty ? 'T' : initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUserName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.e8,
                    ),
                  ),
                  Text(
                    "Admin",
                    style: TextStyle(fontSize: 12, color: AppColors.g4),
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
              color: AppColors.o1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.o1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.o5,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _miembros.isEmpty
                        ? "Si agregas correos aquí, las invitaciones se enviarán al final cuando toques Crear presupuesto."
                        : "Tienes ${_miembros.length} invitación${_miembros.length == 1 ? '' : 'es'} lista${_miembros.length == 1 ? '' : 's'}. Se enviarán al finalizar.",
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.g5,
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
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    m,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.e8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _miembros.removeAt(i)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.r1,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "✕",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.r5,
                      ),
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
              color: AppColors.g0,
              border: Border.all(color: AppColors.g2, style: BorderStyle.none),
              borderRadius: BorderRadius.circular(16),
            ),
            // Note: drawing dashed borders is complex in flutter natively without a package, so I'll just use solid border for now
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Invitar por correo",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.g5,
                  ),
                ),
                const SizedBox(height: 8),
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
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.g2,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.e8,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addMemberEmail,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ), // matched visually to textfield height roughly
                        decoration: BoxDecoration(
                          color: AppColors.e8,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "+",
                          style: TextStyle(
                            color: Colors.white,
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
          icon: Icons.task_alt_rounded,
          iconColor: AppColors.o5,
          iconBackgroundColor: AppColors.o1,
          title: "Resumen",
          subtitle: "Todo listo. Revisa antes de crear.",
        ),
        const SizedBox(height: 20),

        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.e8,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Presupuesto",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _nombre.isEmpty ? "Sin nombre" : _nombre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  MenudoChip.custom(
                    label: _periodo,
                    color: Colors.white.withValues(alpha: 0.8),
                    bgColor: Colors.white.withValues(alpha: 0.15),
                    isSmall: true,
                  ),
                  const SizedBox(width: 8),
                  MenudoChip.custom(
                    label: "Día $_diaInicio",
                    color: Colors.white.withValues(alpha: 0.8),
                    bgColor: Colors.white.withValues(alpha: 0.15),
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
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ingresos",
                    style: TextStyle(fontSize: 13, color: AppColors.g4),
                  ),
                  Text(
                    fmt(ing),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.e6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...incomeEntries.map((entry) {
                final category = categoriesById[entry.key];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category?.nombre ?? 'Ingreso #${entry.key}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.g4,
                        ),
                      ),
                      Text(
                        fmt(entry.value),
                        style: const TextStyle(
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
                const Divider(height: 20, color: AppColors.g1),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        "Gastos",
                        style: TextStyle(fontSize: 13, color: AppColors.g4),
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.g4,
                        ),
                      ),
                      Text(
                        fmt(entry.value),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.e8,
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
                      const Text(
                        "Ahorro",
                        style: TextStyle(fontSize: 13, color: AppColors.g4),
                      ),
                      Text(
                        fmt(aho),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 20, color: AppColors.g1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Sin asignar",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.g5,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Invitaciones",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.g5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Estos correos se enviarán cuando crees el presupuesto.",
                  style: TextStyle(fontSize: 12, color: AppColors.g4),
                ),
                const SizedBox(height: 12),
                ..._miembros.map((email) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.o5,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.e8,
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
