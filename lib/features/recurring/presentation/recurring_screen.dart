import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  late List<RecurringTransaction> _items;

  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  @override
  void initState() {
    super.initState();
    _items = List.from(mockRecurring);
  }

  String _frecuenciaLabel(String f, int dia) {
    switch (f) {
      case 'mensual': return 'Mensual · día $dia';
      case 'quincenal': return 'Quincenal · días 1 y 15';
      case 'semanal': return 'Semanal · día $dia';
      default: return f;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingresos = _items.where((r) => r.tipo == 'ingreso' && r.activo);
    final gastos = _items.where((r) => r.tipo == 'gasto' && r.activo);
    final inactivos = _items.where((r) => !r.activo);

    final totalEntrada = ingresos.fold(0.0, (s, r) => s + r.monto);
    final totalSalida = gastos.fold(0.0, (s, r) => s + r.monto);

    return Scaffold(
      backgroundColor: AppColors.g0,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.arrowLeft, color: AppColors.e8, size: 22),
          ),
        ),
        title: const Text('Automáticas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showAddSheet(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.o5,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [const BoxShadow(color: Color(0x44F97316), blurRadius: 12, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: const Text("+ Nueva", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Summary row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.e8,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [const BoxShadow(color: Color(0x33065F46), blurRadius: 20, offset: Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ENTRADAS/MES", style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(fmt(totalEntrada), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7), letterSpacing: -0.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SALIDAS/MES", style: TextStyle(fontSize: 10, color: AppColors.g4, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(fmt(totalSalida), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.r5, letterSpacing: -0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

          if (ingresos.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("Ingresos recurrentes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
            const SizedBox(height: 4),
            const Text("Se aplican automáticamente", style: TextStyle(fontSize: 12, color: AppColors.g4)),
            const SizedBox(height: 12),
            _buildList(ingresos.toList(), isIngreso: true),
          ],

          if (gastos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text("Gastos recurrentes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
            const SizedBox(height: 4),
            const Text("Descuentos automáticos del presupuesto", style: TextStyle(fontSize: 12, color: AppColors.g4)),
            const SizedBox(height: 12),
            _buildList(gastos.toList(), isIngreso: false),
          ],

          if (inactivos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text("Pausadas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
            const SizedBox(height: 4),
            const Text("No se aplican al presupuesto", style: TextStyle(fontSize: 12, color: AppColors.g4)),
            const SizedBox(height: 12),
            _buildList(inactivos.toList(), isIngreso: false, isInactive: true),
          ],
        ],
      ),
    );
  }

  Widget _buildList(List<RecurringTransaction> items, {required bool isIngreso, bool isInactive = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final r = items[i];
          return Column(
            children: [
              if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 68, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: (isIngreso ? AppColors.e6 : AppColors.r5).withValues(alpha: isInactive ? 0.07 : 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(r.icono, size: 19, color: isInactive ? AppColors.g4 : (isIngreso ? AppColors.e6 : AppColors.r5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.desc, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isInactive ? AppColors.g4 : AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(_frecuenciaLabel(r.frecuencia, r.diaEjecucion), style: const TextStyle(fontSize: 11, color: AppColors.g4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${isIngreso ? '+' : '-'} ${fmt(r.monto)}",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isInactive ? AppColors.g4 : (isIngreso ? AppColors.e6 : AppColors.r5)),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final idx = _items.indexWhere((x) => x.id == r.id);
                            if (idx >= 0) {
                              setState(() {
                                _items[idx] = RecurringTransaction(
                                  id: r.id, desc: r.desc, catKey: r.catKey, monto: r.monto,
                                  tipo: r.tipo, icono: r.icono, frecuencia: r.frecuencia,
                                  diaEjecucion: r.diaEjecucion, activo: !r.activo, nota: r.nota,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: r.activo ? AppColors.e1 : AppColors.g1,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.activo ? "Activa" : "Pausada",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: r.activo ? AppColors.e6 : AppColors.g4),
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
        }),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 150.ms).slideY(begin: 0.04, end: 0, duration: 350.ms, delay: 150.ms);
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRecurringSheet(),
    ).then((result) {
      if (result != null && result is RecurringTransaction) {
        setState(() => _items.add(result));
      }
    });
  }
}

class _AddRecurringSheet extends StatefulWidget {
  const _AddRecurringSheet();

  @override
  State<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<_AddRecurringSheet> {
  String _amount = "";
  int _typeIndex = 0; // 0: Gasto, 1: Ingreso
  String _frecuencia = "mensual";
  int _dia = 1;
  final _descController = TextEditingController();
  
  String _cat = "Seleccionar";
  String? _catKey;
  int? _accountId;
  int? _presupuestoId;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'backspace') {
        if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount = _amount.isEmpty ? "0." : "$_amount.";
      } else {
        if (_amount == "0") {
          _amount = key;
        } else if (_amount.length < 9) {
          _amount += key;
        }
      }
    });
  }

  String _accountName(int? id) {
    if (id == null) return "Seleccionar";
    return mockWallets.firstWhere((w) => w.id == id, orElse: () => mockWallets.first).nombre;
  }

  String _budgetName(int? id) {
    if (id == null) return "Seleccionar";
    return mockBudgets.firstWhere((b) => b.id == id, orElse: () => mockBudgets.first).nombre;
  }

  void _pickAccount() {
    // Reusing the simple list logic for demo purposes
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(3)), margin: const EdgeInsets.only(bottom: 24)),
            const Text("Cuenta origen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.e8)),
            const SizedBox(height: 24),
            ...mockWallets.map((w) => GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context, w.id); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: w.id == _accountId ? AppColors.e8 : AppColors.g0, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(w.icono, color: w.id == _accountId ? Colors.white : w.color),
                    const SizedBox(width: 16),
                    Text(w.nombre, style: TextStyle(fontWeight: FontWeight.w700, color: w.id == _accountId ? Colors.white : AppColors.e8)),
                    const Spacer(),
                    if (w.id == _accountId) const Icon(LucideIcons.check, color: Colors.white, size: 18),
                  ],
                ),
              ),
            )),
          ],
        ),
      )
    ).then((id) {
      if (id != null) setState(() => _accountId = id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = double.tryParse(_amount) ?? 0;
    final accentColor = _typeIndex == 1 ? AppColors.e6 : AppColors.e8;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.g0,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 5, width: 40,
                  decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Nueva automática", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.e8, letterSpacing: -0.5)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(LucideIcons.x, color: AppColors.g5, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              // Type toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildSeg('Gasto', 0),
                      _buildSeg('Ingreso', 1),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Amount
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(_typeIndex == 1 ? '+RD\$' : '-RD\$', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: accentColor.withValues(alpha: 0.4))),
                    const SizedBox(width: 8),
                    Text(
                      _amount.isEmpty ? "0" : _amount.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                      style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2, color: accentColor),
                    ),
                  ],
                ).animate(key: ValueKey(_typeIndex)).fadeIn().scale(begin: const Offset(0.95, 0.95)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Detalles (Category, Account, Budget)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.g2),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: LucideIcons.tag, color: AppColors.o5, label: "Categoría", value: _cat,
                            onTap: () {
                              // In a real app, open CategoryPickerSheet
                              HapticFeedback.lightImpact();
                              setState(() { _catKey = 'suscripciones'; _cat = 'Suscripciones'; });
                            },
                          ),
                          _DetailRow(
                            icon: LucideIcons.landmark, color: AppColors.b5, label: "Cuenta", value: _accountName(_accountId),
                            onTap: _pickAccount,
                          ),
                          _DetailRow(
                            icon: LucideIcons.layoutGrid, color: AppColors.p5, label: "Presupuesto", value: _budgetName(_presupuestoId),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _presupuestoId = mockBudgets.first.id);
                            },
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Descripción
                    TextField(
                      controller: _descController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.e8),
                      decoration: InputDecoration(
                        hintText: "Descripción (ej. Sueldo, Netflix)",
                        hintStyle: const TextStyle(color: AppColors.g4, fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.g2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFF3F4F6), width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.e8, width: 2.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Frecuencia
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Frecuencia", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.g4, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Row(
                            children: ['mensual', 'quincenal', 'semanal'].map((f) {
                              final isSel = _frecuencia == f;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () { HapticFeedback.selectionClick(); setState(() => _frecuencia = f); },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSel ? AppColors.e8 : AppColors.g1,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(f[0].toUpperCase() + f.substring(1), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? Colors.white : AppColors.g5)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_frecuencia != 'quincenal') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(_frecuencia == 'mensual' ? "Día del mes:" : "Día de semana:", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.e8)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () { HapticFeedback.selectionClick(); setState(() => _dia = (_dia - 1).clamp(1, _frecuencia == 'mensual' ? 28 : 7)); },
                                  child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: const Icon(LucideIcons.minus, size: 18, color: AppColors.g5)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text("$_dia", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.e8)),
                                ),
                                GestureDetector(
                                  onTap: () { HapticFeedback.selectionClick(); setState(() => _dia = (_dia + 1).clamp(1, _frecuencia == 'mensual' ? 28 : 7)); },
                                  child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: const Icon(LucideIcons.plus, size: 18, color: AppColors.g5)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Numpad
                    GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.8,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ...'123456789.0'.split(''),
                        'backspace',
                      ].map((k) => _NumpadKey(value: k, onTap: () => _onKeyTap(k))).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.of(context).padding.bottom),
                child: GestureDetector(
                  onTap: amountValue > 0 && _descController.text.trim().isNotEmpty ? () {
                    HapticFeedback.mediumImpact();
                    final r = RecurringTransaction(
                      id: DateTime.now().millisecondsSinceEpoch,
                      desc: _descController.text.trim(),
                      catKey: _catKey ?? (_typeIndex == 1 ? 'ingreso' : 'otro'),
                      monto: amountValue,
                      tipo: _typeIndex == 1 ? 'ingreso' : 'gasto',
                      icono: _typeIndex == 1 ? LucideIcons.trendingUp : LucideIcons.tag,
                      frecuencia: _frecuencia,
                      diaEjecucion: _dia,
                      accountId: _accountId,
                      presupuestoId: _presupuestoId,
                    );
                    Navigator.pop(context, r);
                  } : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: amountValue > 0 && _descController.text.trim().isNotEmpty ? AppColors.e8 : AppColors.g2,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: amountValue > 0 ? [BoxShadow(color: AppColors.e8.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))] : [],
                    ),
                    alignment: Alignment.center,
                    child: Text("GUARDAR AUTOMÁTICA", style: TextStyle(color: amountValue > 0 ? Colors.white : AppColors.g4, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeg(String title, int index) {
    final isSelected = _typeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _typeIndex = index); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppColors.e8 : AppColors.g4)),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final VoidCallback? onTap;
  final bool isLast;

  const _DetailRow({required this.icon, required this.color, required this.label, required this.value, this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.g4, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.e8)),
                    ],
                  ),
                ),
                if (onTap != null) Icon(LucideIcons.chevronRight, size: 16, color: AppColors.g3),
              ],
            ),
          ),
          if (!isLast) Divider(height: 1, color: AppColors.g1, indent: 56, endIndent: 16),
        ],
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _NumpadKey({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isBack = value == 'backspace';
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: isBack 
          ? const Icon(LucideIcons.delete, color: AppColors.e8, size: 22)
          : Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.e8)),
      ),
    );
  }
}
