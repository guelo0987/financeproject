import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../categories/presentation/category_picker_sheet.dart';

class RegisterTransactionSheet extends StatefulWidget {
  /// Pass a transaction to pre-fill for editing mode
  final MenudoTransaction? transaction;

  const RegisterTransactionSheet({super.key, this.transaction});

  @override
  State<RegisterTransactionSheet> createState() => _RegisterTransactionSheetState();
}

class _RegisterTransactionSheetState extends State<RegisterTransactionSheet> {
  String _amount = "";
  int _selectedTypeIndex = 0; // 0: Gasto, 1: Ingreso, 2: Transferencia
  String _cat = "Seleccionar";
  String? _catKey;
  String? _nota;
  int? _fromAccountId;
  int? _toAccountId;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.transaction!;
      _amount = t.monto.abs().toStringAsFixed(t.monto.abs() % 1 == 0 ? 0 : 2);
      _catKey = t.catKey;
      _nota = t.nota;
      _fromAccountId = t.fromAccountId;
      _toAccountId = t.toAccountId;
      switch (t.tipo) {
        case 'ingreso': _selectedTypeIndex = 1;
        case 'transferencia': _selectedTypeIndex = 2;
        default: _selectedTypeIndex = 0;
      }
      // Set category label
      final catLabels = {
        'vivienda': 'Vivienda', 'comida': 'Comida', 'transporte': 'Transporte',
        'estiloVida': 'Estilo de vida', 'salud': 'Salud', 'educacion': 'Educación',
        'entretenimiento': 'Entretenimiento', 'servicios': 'Servicios', 'otro': 'Otro',
        'ingreso': 'Ingreso', 'transferencia': 'Transferencia',
      };
      _cat = catLabels[t.catKey] ?? t.catKey;
    }
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
        } else if (_amount.length < 10) {
          _amount += key;
        }
      }
    });
  }

  void _saveTransaction() {
    if (_amount.isEmpty || double.parse(_amount) == 0) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Transacción actualizada' : 'Transacción registrada',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.e6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _accountName(int? id) {
    if (id == null) return "Seleccionar";
    return mockWallets.firstWhere((w) => w.id == id, orElse: () => mockWallets.first).nombre;
  }

  void _pickAccount({required bool isFrom}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountPickerSheet(
        title: isFrom ? "Cuenta origen" : "Cuenta destino",
        selectedId: isFrom ? _fromAccountId : _toAccountId,
        excludeId: isFrom ? _toAccountId : _fromAccountId,
      ),
    ).then((id) {
      if (id != null) {
        setState(() {
          if (isFrom) {
            _fromAccountId = id;
          } else {
            _toAccountId = id;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(_amount) ?? 0;
    final bool isTransfer = _selectedTypeIndex == 2;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 5, width: 48,
                  decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(3)),
                ),
              ),

              // Title row (edit mode shows title)
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Editar transacción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.e8)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: AppColors.g4, size: 22),
                      ),
                    ],
                  ),
                ),

              // Segment Control
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildSegment('Gasto', 0),
                      _buildSegment('Ingreso', 1),
                      _buildSegment('Transferencia', 2),
                    ],
                  ),
                ),
              ),

              // Amount Display
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isTransfer ? 'RD\$' : (_selectedTypeIndex == 1 ? '+RD\$' : '-RD\$'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.g3),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _amount.isEmpty ? "0" : _amount.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        color: _selectedTypeIndex == 1 ? AppColors.e6 : (_selectedTypeIndex == 2 ? AppColors.b5 : AppColors.e8),
                      ),
                    ),
                  ],
                ),
              ),

              // Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Transfer: De → Para
                          if (isTransfer) ...[
                            _buildDetailRow(
                              LucideIcons.arrowUpFromLine, AppColors.e6, AppColors.e1, "De (origen)", _accountName(_fromAccountId),
                              isTappable: true, onTap: () => _pickAccount(isFrom: true),
                            ),
                            const Divider(height: 1, color: AppColors.g1),
                            _buildDetailRow(
                              LucideIcons.arrowDownToLine, AppColors.b5, const Color(0xFFEFF6FF), "Para (destino)", _accountName(_toAccountId),
                              isTappable: true, onTap: () => _pickAccount(isFrom: false),
                            ),
                            const Divider(height: 1, color: AppColors.g1),
                          ] else ...[
                            _buildDetailRow(
                              LucideIcons.tag, AppColors.o5, AppColors.o1, "Categoría", _cat,
                              isTappable: true, onTap: () async {
                                final result = await showModalBottomSheet<String>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => CategoryPickerSheet(initialCatKey: _catKey),
                                );
                                if (result != null) {
                                  final labels = {
                                    'vivienda': 'Vivienda', 'comida': 'Comida', 'transporte': 'Transporte',
                                    'estiloVida': 'Estilo de vida', 'salud': 'Salud', 'educacion': 'Educación',
                                    'entretenimiento': 'Entretenimiento', 'servicios': 'Servicios', 'otro': 'Otro',
                                  };
                                  setState(() { _catKey = result; _cat = labels[result] ?? result; });
                                }
                              },
                            ),
                            const Divider(height: 1, color: AppColors.g1),
                            _buildDetailRow(LucideIcons.landmark, AppColors.b5, const Color(0xFFEFF6FF), "Cuenta", "BHD León"),
                            const Divider(height: 1, color: AppColors.g1),
                          ],
                          _buildDetailRow(
                            LucideIcons.fileText, AppColors.p5, const Color(0xFFF3EEFF), "Nota", _nota ?? "Agregar nota...",
                            isTappable: true,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showNoteDialog();
                            },
                          ),
                          const Divider(height: 1, color: AppColors.g1),
                          _buildDetailRow(LucideIcons.calendarDays, AppColors.e8, AppColors.g1, "Fecha", "Hoy", hasBorder: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Numpad
                    GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2.1,
                      mainAxisSpacing: 12, crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildKey('1'), _buildKey('2'), _buildKey('3'),
                        _buildKey('4'), _buildKey('5'), _buildKey('6'),
                        _buildKey('7'), _buildKey('8'), _buildKey('9'),
                        _buildKey('.'), _buildKey('0'), _buildKey('backspace', isIcon: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Save Button
              Container(
                color: Colors.transparent,
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
                child: MenudoButton(
                  label: _isEditing ? "Guardar cambios" : "Agregar Transacción",
                  isFullWidth: true,
                  isDisabled: amountValue == 0,
                  onTap: _saveTransaction,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoteDialog() {
    final ctrl = TextEditingController(text: _nota);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Agregar nota", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(fontSize: 14, color: AppColors.e8),
          decoration: InputDecoration(
            hintText: "Escribe una nota...",
            hintStyle: const TextStyle(color: AppColors.g4),
            filled: true,
            fillColor: AppColors.g0,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: AppColors.g4))),
          TextButton(
            onPressed: () {
              setState(() => _nota = ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Guardar", style: TextStyle(color: AppColors.o5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String title, int index) {
    final isSelected = _selectedTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTypeIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [const BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))] : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? AppColors.e8 : AppColors.g4),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    Color iconColor,
    Color iconBg,
    String label,
    String value, {
    bool hasBorder = true,
    bool isTappable = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.g4, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                  const SizedBox(height: 3),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.e8), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isTappable || onTap != null) const Icon(Icons.chevron_right, color: AppColors.g3, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String value, {bool isIcon = false}) {
    return GestureDetector(
      onTapDown: (_) => _onKeyTap(value),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: isIcon
            ? const Icon(Icons.backspace_outlined, color: AppColors.e8, size: 24)
            : Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.e8)),
      ),
    );
  }
}

// ── Account Picker Sheet ──────────────────────────
class _AccountPickerSheet extends StatelessWidget {
  final String title;
  final int? selectedId;
  final int? excludeId;

  const _AccountPickerSheet({required this.title, this.selectedId, this.excludeId});

  @override
  Widget build(BuildContext context) {
    final accounts = mockWallets.where((w) => w.id != excludeId).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 5, width: 48, decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.e8)),
          const SizedBox(height: 20),
          ...accounts.map((w) {
            final isSelected = w.id == selectedId;
            return GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context, w.id); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.e8 : AppColors.g0,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.e8 : const Color(0xFFF3F4F6), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.2) : w.color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(w.icono, size: 18, color: isSelected ? Colors.white : w.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.nombre, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.e8)),
                          Text(w.tipo[0].toUpperCase() + w.tipo.substring(1), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white.withValues(alpha: 0.6) : AppColors.g4)),
                        ],
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
