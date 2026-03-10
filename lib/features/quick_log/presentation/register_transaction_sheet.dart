import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/models.dart';
import '../../../../shared/widgets/menudo_button.dart';
import '../../categories/presentation/category_picker_sheet.dart';
import '../../wallet/providers/wallet_providers.dart';

class RegisterTransactionSheet extends ConsumerStatefulWidget {
  final MenudoTransaction? transaction;

  const RegisterTransactionSheet({super.key, this.transaction});

  @override
  ConsumerState<RegisterTransactionSheet> createState() => _RegisterTransactionSheetState();
}

class _RegisterTransactionSheetState extends ConsumerState<RegisterTransactionSheet> {
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
    
    // Initial wallet selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isEditing) {
        final defaultId = ref.read(defaultWalletIdProvider);
        if (defaultId != null) {
          setState(() {
            _fromAccountId = defaultId;
          });
        }
      }
    });

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
      _cat = t.catKey.toUpperCase();
    }
  }

  Color get _accentColor {
    if (_selectedTypeIndex == 1) return AppColors.e6;
    if (_selectedTypeIndex == 2) return AppColors.b5;
    return AppColors.e8;
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

  void _saveTransaction() {
    if (_amount.isEmpty || double.parse(_amount) == 0) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
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
          if (isFrom) _fromAccountId = id;
          else _toAccountId = id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(_amount) ?? 0;
    final bool isTransfer = _selectedTypeIndex == 2;

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: AppColors.g0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 5, width: 40,
              decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(3)),
            ),
          ),

          // Segment Control
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Container(
              decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _TypeSegment(label: 'Gasto', index: 0, current: _selectedTypeIndex, onTap: (i) => setState(() => _selectedTypeIndex = i)),
                  _TypeSegment(label: 'Ingreso', index: 1, current: _selectedTypeIndex, onTap: (i) => setState(() => _selectedTypeIndex = i)),
                  _TypeSegment(label: 'Transfer.', index: 2, current: _selectedTypeIndex, onTap: (i) => setState(() => _selectedTypeIndex = i)),
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _accentColor.withValues(alpha: 0.4)),
                ),
                const SizedBox(width: 8),
                Text(
                  _amount.isEmpty ? "0" : _amount.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: _accentColor,
                  ),
                ),
              ],
            ).animate(key: ValueKey(_selectedTypeIndex)).fadeIn().scale(begin: const Offset(0.95, 0.95)),
          ),

          // Details List
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.g2),
                  ),
                  child: Column(
                    children: [
                      if (isTransfer) ...[
                        _DetailRow(
                          icon: LucideIcons.arrowUpFromLine, color: AppColors.e6, label: "Origen", value: _accountName(_fromAccountId),
                          onTap: () => _pickAccount(isFrom: true),
                        ),
                        _DetailRow(
                          icon: LucideIcons.arrowDownToLine, color: AppColors.b5, label: "Destino", value: _accountName(_toAccountId),
                          onTap: () => _pickAccount(isFrom: false),
                        ),
                      ] else ...[
                        _DetailRow(
                          icon: LucideIcons.tag, color: AppColors.o5, label: "Categoría", value: _cat,
                          onTap: () async {
                            final res = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CategoryPickerSheet(initialCatKey: _catKey),
                            );
                            if (res != null) setState(() { _catKey = res; _cat = res.toUpperCase(); });
                          },
                        ),
                        _DetailRow(
                          icon: LucideIcons.landmark, color: AppColors.b5, label: "Cuenta", value: _accountName(_fromAccountId),
                          onTap: () => _pickAccount(isFrom: true),
                        ),
                      ],
                      _DetailRow(
                        icon: LucideIcons.fileText, color: AppColors.p5, label: "Nota", value: _nota ?? "Opcional",
                        onTap: () => _showNoteDialog(),
                      ),
                      _DetailRow(icon: LucideIcons.calendar, color: AppColors.e8, label: "Fecha", value: "Hoy", isLast: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Premium Numpad
                _Numpad(onKeyTap: _onKeyTap),
                
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.of(context).padding.bottom),
            child: MenudoButton(
              label: _isEditing ? "ACTUALIZAR" : "REGISTRAR",
              isFullWidth: true,
              isDisabled: amountValue == 0,
              onTap: _saveTransaction,
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog() {
    final ctrl = TextEditingController(text: _nota);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Nota de transacción", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.e8)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Escribe algo aquí...",
            filled: true,
            fillColor: AppColors.g0,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: AppColors.g4))),
          TextButton(onPressed: () {
            setState(() => _nota = ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
            Navigator.pop(context);
          }, child: const Text("Guardar", style: TextStyle(color: AppColors.o5, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  final String label;
  final int index, current;
  final Function(int) onTap;

  const _TypeSegment({required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(index); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? AppColors.e8 : AppColors.g4)),
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

class _Numpad extends StatelessWidget {
  final Function(String) onKeyTap;
  const _Numpad({required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        ...'123456789.0'.split(''),
        'backspace',
      ].map((k) => _NumpadKey(value: k, onTap: () => onKeyTap(k))).toList(),
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

class _AccountPickerSheet extends StatelessWidget {
  final String title;
  final int? selectedId, excludeId;

  const _AccountPickerSheet({required this.title, this.selectedId, this.excludeId});

  @override
  Widget build(BuildContext context) {
    final accounts = mockWallets.where((w) => w.id != excludeId).toList();
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.g2, borderRadius: BorderRadius.circular(3)), margin: const EdgeInsets.only(bottom: 24)),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.e8)),
          const SizedBox(height: 24),
          ...accounts.map((w) => GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context, w.id); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: w.id == selectedId ? AppColors.e8 : AppColors.g0,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(w.icono, color: w.id == selectedId ? Colors.white : w.color),
                  const SizedBox(width: 16),
                  Text(w.nombre, style: TextStyle(fontWeight: FontWeight.w700, color: w.id == selectedId ? Colors.white : AppColors.e8)),
                  const Spacer(),
                  if (w.id == selectedId) const Icon(LucideIcons.check, color: Colors.white, size: 18),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

