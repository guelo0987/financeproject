import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../../../shared/widgets/menudo_chip.dart';

class CreateBudgetWizard extends StatefulWidget {
  const CreateBudgetWizard({super.key});

  @override
  State<CreateBudgetWizard> createState() => _CreateBudgetWizardState();
}

class _CreateBudgetWizardState extends State<CreateBudgetWizard> {
  int _step = 0;
  final List<String> _steps = ["Básico", "Ingresos", "Gastos", "Ahorro", "Miembros", "Resumen"];
  
  // Form Data
  String _nombre = "";
  String _periodo = "mensual";
  int _diaInicio = 1;
  String _ingresos = "";
  final Map<String, String> _cats = {
    "vivienda": "",
    "comida": "",
    "transporte": "",
    "estiloVida": "",
    "ahorro": "",
  };
  final List<String> _miembros = [];
  String _emailInput = "";

  final Map<String, dynamic> _catsConfig = {
    "vivienda": {"label": "Vivienda/Renta", "icono": "🏠", "color": AppColors.e7},
    "comida": {"label": "Comida", "icono": "🍽️", "color": AppColors.o5},
    "transporte": {"label": "Transporte", "icono": "🚗", "color": AppColors.p5},
    "estiloVida": {"label": "Estilo de vida", "icono": "✨", "color": AppColors.pk},
    "ahorro": {"label": "Ahorro", "icono": "💰", "color": AppColors.a5},
  };
  
  final List<String> _catOrder = ["vivienda", "comida", "transporte", "estiloVida"];

  double get ing => double.tryParse(_ingresos) ?? 0;
  double get gastos => _catOrder.fold(0.0, (sum, k) => sum + (double.tryParse(_cats[k]!) ?? 0));
  double get aho => double.tryParse(_cats["ahorro"]!) ?? 0;
  double get sobrante => ing - gastos - aho;

  bool _canNext() {
    switch (_step) {
      case 0: return _nombre.trim().isNotEmpty;
      case 1: return _ingresos.isNotEmpty && ing > 0;
      case 2: return true;
      case 3: return true;
      case 4: return true;
      case 5: return true;
      default: return false;
    }
  }

  void _onNextOrSave() {
    if (_step < 5) {
      setState(() => _step++);
    } else {
      // Save logic
      Navigator.pop(context);
    }
  }

  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

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
                  width: 40, height: 4, decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(2)),
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
                        width: 30, height: 30,
                        decoration: const BoxDecoration(color: AppColors.g1, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Icon(_step == 0 ? Icons.close : Icons.arrow_back, size: 16, color: AppColors.g5),
                      ),
                    ),
                    Row(
                      children: List.generate(_steps.length, (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        height: 8,
                        width: index <= _step ? 20 : 8,
                        decoration: BoxDecoration(
                          color: index < _step ? AppColors.e8 : index == _step ? AppColors.o5 : AppColors.g2,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      )),
                    ),
                    Text("${_step + 1}/${_steps.length}", style: const TextStyle(fontSize: 12, color: AppColors.g4, fontWeight: FontWeight.w600)),
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
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: MenudoButton(
              label: _step == 5 ? "🎉 Crear presupuesto" : "Siguiente \u2192", // right arrow
              isFullWidth: true,
              isDisabled: !_canNext(),
              onTap: _onNextOrSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      case 5: return _buildStep5();
      default: return const SizedBox();
    }
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Nuevo presupuesto", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        const SizedBox(height: 4),
        const Text("¿Cómo se llamará y qué período tendrá?", style: TextStyle(fontSize: 14, color: AppColors.g4)),
        const SizedBox(height: 24),
        
        const Text("Nombre", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.g5)),
        const SizedBox(height: 6),
        TextField(
          onChanged: (v) => setState(() => _nombre = v),
          controller: TextEditingController.fromValue(TextEditingValue(text: _nombre, selection: TextSelection.collapsed(offset: _nombre.length))),
          decoration: InputDecoration(
            hintText: "ej: Hogar Abril, Viaje, Personal",
            hintStyle: const TextStyle(color: AppColors.g3, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: AppColors.g0,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.g2, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.e8, width: 2)),
          ),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.e8),
        ),
        
        const SizedBox(height: 16),
        const Text("Período", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.g5)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            {"v": "semanal", "l": "Semanal"},
            {"v": "quincenal", "l": "Quincenal"},
            {"v": "mensual", "l": "Mensual"},
            {"v": "anual", "l": "Anual"},
          ].map((p) => GestureDetector(
            onTap: () => setState(() => _periodo = p["v"]!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _periodo == p["v"] ? AppColors.e0 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _periodo == p["v"] ? AppColors.e8 : AppColors.g2, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(p["l"]!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _periodo == p["v"] ? AppColors.e8 : AppColors.g5)),
            ),
          )).toList(),
        ),
        
        const SizedBox(height: 16),
        const Text("Día de inicio", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.g5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 5, 10, 15, 20, 25, 30].map((d) => GestureDetector(
            onTap: () => setState(() => _diaInicio = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _diaInicio == d ? AppColors.e8 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _diaInicio == d ? AppColors.e8 : AppColors.g2, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(d.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _diaInicio == d ? Colors.white : AppColors.g5)),
            ),
          )).toList(),
        )
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ingresos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        const SizedBox(height: 4),
        const Text("¿Cuánto recibes en este período?", style: TextStyle(fontSize: 14, color: AppColors.g4)),
        const SizedBox(height: 20),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.e0,
            border: Border.all(color: AppColors.e7.withValues(alpha: 0.13), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text("MONTO DE INGRESOS", style: TextStyle(fontSize: 11, color: AppColors.e7, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("RD\$", style: TextStyle(fontSize: 22, color: AppColors.e7, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  IntrinsicWidth(
                    child: TextField(
                      onChanged: (v) => setState(() => _ingresos = v),
                      controller: TextEditingController.fromValue(TextEditingValue(text: _ingresos, selection: TextSelection.collapsed(offset: _ingresos.length))),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.e8),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "0",
                        hintStyle: TextStyle(color: AppColors.e7),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        ...[
          {"label": "Salario", "icon": "💼", "val": "95000"},
          {"label": "Freelance", "icon": "💻", "val": "20000"},
          {"label": "Negocio", "icon": "🏪", "val": "50000"}
        ].map((s) => GestureDetector(
          onTap: () => setState(() => _ingresos = s["val"]!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(color: AppColors.g0, border: Border.all(color: AppColors.g2, width: 2), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Text(s["icon"]!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(s["label"]!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8)),
                const Spacer(),
                Text("RD\$${int.parse(s["val"]!).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.o5)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gastos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        const SizedBox(height: 4),
        const Text("¿Cuánto destinas a cada categoría?", style: TextStyle(fontSize: 14, color: AppColors.g4)),
        const SizedBox(height: 16),
        
        if (ing > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.g0, border: Border.all(color: AppColors.g2, width: 1.5), borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ingresos totales", style: TextStyle(fontSize: 13, color: AppColors.g4)),
                Text(fmt(ing), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.e8)),
              ],
            ),
          ),
          
        ..._catOrder.map((k) {
          final cfg = _catsConfig[k];
          final val = double.tryParse(_cats[k]!) ?? 0;
          final pct = ing > 0 ? (val / ing * 100).round() : 0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: cfg["color"].withValues(alpha: 0.13), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(cfg["icono"], style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(cfg["label"], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8))),
                    if (pct > 0) MenudoChip.custom(label: "$pct%", color: cfg["color"], isSmall: true),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("RD\$", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.g4)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _cats[k] = v),
                        controller: TextEditingController.fromValue(TextEditingValue(text: _cats[k]!, selection: TextSelection.collapsed(offset: _cats[k]!.length))),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8),
                        decoration: InputDecoration(
                          hintText: "0",
                          filled: true,
                          fillColor: AppColors.g0,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.g2, width: 2)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.g2, width: 2)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.e8, width: 2)),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ahorro", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        const SizedBox(height: 4),
        const Text("¿Cuánto quieres apartar este período?", style: TextStyle(fontSize: 14, color: AppColors.g4)),
        const SizedBox(height: 20),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.a1,
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.13), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text("META DE AHORRO", style: TextStyle(fontSize: 11, color: AppColors.a5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("RD\$", style: TextStyle(fontSize: 22, color: AppColors.a5, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  IntrinsicWidth(
                    child: TextField(
                      onChanged: (v) => setState(() => _cats["ahorro"] = v),
                      controller: TextEditingController.fromValue(TextEditingValue(text: _cats["ahorro"]!, selection: TextSelection.collapsed(offset: _cats["ahorro"]!.length))),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.a5),
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
              )
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        if (ing > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Distribución", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.g5)),
                const SizedBox(height: 10),
                ...[..._catOrder.map((k) => {"cfg": _catsConfig[k], "val": double.tryParse(_cats[k]!) ?? 0}), {"cfg": _catsConfig["ahorro"], "val": aho}]
                  .where((e) => (e["val"] as double) > 0)
                  .map((e) {
                    final cfg = e["cfg"] as Map;
                    final v = e["val"] as double;
                    final pct = (v / ing * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${cfg["icono"]} ${cfg["label"]}", style: const TextStyle(fontSize: 12, color: AppColors.g5)),
                              Text("$pct%", style: const TextStyle(fontSize: 12, color: AppColors.e8, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 5, decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(3)),
                            alignment: Alignment.centerLeft,
                            child: LayoutBuilder(builder: (ctx, constraints) {
                              return Container(
                                height: 5, width: constraints.maxWidth * min(v / ing, 1.0),
                                decoration: BoxDecoration(color: cfg["color"], borderRadius: BorderRadius.circular(3)),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Sin asignar", style: TextStyle(fontSize: 13, color: AppColors.g4)),
                      Text(fmt(sobrante), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: sobrante >= 0 ? AppColors.e6 : AppColors.r5)),
                    ],
                  ),
                )
              ],
            ),
          )
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("👥 Miembros", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        const SizedBox(height: 4),
        const Text("Invita hasta 3 personas (máximo 4 contigo).", style: TextStyle(fontSize: 14, color: AppColors.g4)),
        const SizedBox(height: 20),
        
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.e8, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Text("M", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Marcos Pérez (Tú)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.e8)),
                  Text("Admin", style: TextStyle(fontSize: 12, color: AppColors.g4)),
                ],
              )
            ],
          ),
        ),
        
        ...List.generate(_miembros.length, (i) {
          final m = _miembros[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.o5, borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(m.isNotEmpty ? m[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(child: Text(m, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.e8))),
                GestureDetector(
                  onTap: () => setState(() => _miembros.removeAt(i)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.r1, borderRadius: BorderRadius.circular(8)),
                    child: const Text("✕", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.r5)),
                  ),
                )
              ],
            ),
          );
        }),
        
        if (_miembros.length < 3)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.g0, border: Border.all(color: AppColors.g2, style: BorderStyle.none), borderRadius: BorderRadius.circular(16)),
            // Note: drawing dashed borders is complex in flutter natively without a package, so I'll just use solid border for now
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Invitar por correo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.g5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _emailInput = v),
                        controller: TextEditingController.fromValue(TextEditingValue(text: _emailInput, selection: TextSelection.collapsed(offset: _emailInput.length))),
                        decoration: InputDecoration(
                          hintText: "correo@ejemplo.com",
                          filled: true, fillColor: Colors.white,
                          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.g2, width: 2)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.e8, width: 2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (_emailInput.isNotEmpty) {
                          setState(() {
                            _miembros.add(_emailInput);
                            _emailInput = "";
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), // matched visually to textfield height roughly
                        decoration: BoxDecoration(color: AppColors.e8, borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: const Text("+", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("✅ Resumen", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        const SizedBox(height: 4),
        const Text("Todo listo. Revisa antes de crear.", style: TextStyle(fontSize: 14, color: AppColors.g4)),
        const SizedBox(height: 20),
        
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.e8, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Presupuesto", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 4),
              Text(_nombre.isEmpty ? "Sin nombre" : _nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  MenudoChip.custom(label: _periodo, color: Colors.white.withValues(alpha: 0.8), bgColor: Colors.white.withValues(alpha: 0.15), isSmall: true),
                  const SizedBox(width: 8),
                  MenudoChip.custom(label: "Día $_diaInicio", color: Colors.white.withValues(alpha: 0.8), bgColor: Colors.white.withValues(alpha: 0.15), isSmall: true),
                ],
              )
            ],
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Ingresos", style: TextStyle(fontSize: 13, color: AppColors.g4)), Text(fmt(ing), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.e6))]),
              const SizedBox(height: 10),
              ..._catOrder.map((k) {
                final val = double.tryParse(_cats[k]!) ?? 0;
                if (val <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_catsConfig[k]["label"] as String, style: const TextStyle(fontSize: 13, color: AppColors.g4)), Text(fmt(val), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.e8))]),
                );
              }),
              if (aho > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Ahorro", style: TextStyle(fontSize: 13, color: AppColors.g4)), Text(fmt(aho), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning))]),
                ),
              const Divider(height: 20, color: AppColors.g1),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Sin asignar", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.g5)), Text(fmt(sobrante), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: sobrante >= 0 ? AppColors.e6 : AppColors.r5))]),
            ],
          ),
        )
      ],
    );
  }
}
