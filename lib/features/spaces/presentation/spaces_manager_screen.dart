import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class SpacesManagerScreen extends StatefulWidget {
  const SpacesManagerScreen({super.key});

  @override
  State<SpacesManagerScreen> createState() => _SpacesManagerScreenState();
}

class _SpacesManagerScreenState extends State<SpacesManagerScreen> {
  // Example spaces
  final List<Map<String, dynamic>> _spaces = [
    {
      'nombre': 'Hogar Cruz',
      'emoji': '🏠',
      'desc': 'Presupuesto familiar compartido',
      'miembros': [
        {'nombre': 'Miguel Cruz', 'inicial': 'M', 'color': AppColors.e8, 'rol': 'Admin', 'esYo': true},
        {'nombre': 'Sarah Cruz', 'inicial': 'S', 'color': AppColors.o5, 'rol': 'Admin', 'esYo': false},
        {'nombre': 'Carlos Cruz', 'inicial': 'C', 'color': AppColors.b5, 'rol': 'Miembro', 'esYo': false},
      ],
      'presupuesto': 95000.0,
      'gastado': 44000.0,
      'activo': true,
    },
    {
      'nombre': 'Viaje Punta Cana',
      'emoji': '🌴',
      'desc': 'Gastos compartidos del viaje',
      'miembros': [
        {'nombre': 'Miguel Cruz', 'inicial': 'M', 'color': AppColors.e8, 'rol': 'Admin', 'esYo': true},
        {'nombre': 'Laura Gómez', 'inicial': 'L', 'color': AppColors.pk, 'rol': 'Miembro', 'esYo': false},
        {'nombre': 'Roberto D.', 'inicial': 'R', 'color': AppColors.p5, 'rol': 'Miembro', 'esYo': false, 'pendiente': true},
      ],
      'presupuesto': 40000.0,
      'gastado': 12500.0,
      'activo': false,
    },
  ];

  String fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  void _showCreateSpace() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Crear espacio próximamente', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.e8,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyInviteLink(String spaceName) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Enlace de "$spaceName" copiado!', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.e6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Espacios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.e8)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
        actions: [
          GestureDetector(
            onTap: _showCreateSpace,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.o5,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [const BoxShadow(color: Color(0x44F97316), blurRadius: 12, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: const Text("+ Nuevo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // What are spaces
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.e8,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [const BoxShadow(color: Color(0x33065F46), blurRadius: 32, offset: Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.users, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Espacios compartidos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                          SizedBox(height: 3),
                          Text("Finanzas en equipo, sin complicaciones", style: TextStyle(fontSize: 12, color: Color(0xFF6EE7B7))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Benefits
                ...[
                  (LucideIcons.eye, "Transparencia total", "Todos ven los gastos en tiempo real"),
                  (LucideIcons.splitSquareHorizontal, "Divide gastos", "Asigna quién paga qué automáticamente"),
                  (LucideIcons.bell, "Alertas compartidas", "Recibe notificaciones cuando alguien gasta"),
                ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Icon(item.$1, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text(item.$3, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 24),

          // Spaces list
          const Text("Tus espacios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
          const SizedBox(height: 4),
          Text("${_spaces.length} espacios activos", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
          const SizedBox(height: 12),

          ..._spaces.asMap().entries.map((entry) {
            final idx = entry.key;
            final space = entry.value;
            final miembros = space['miembros'] as List;
            final presupuesto = space['presupuesto'] as double;
            final gastado = space['gastado'] as double;
            final pct = (gastado / presupuesto).clamp(0.0, 1.0);
            final isActivo = space['activo'] as bool;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: isActivo ? AppColors.e8.withValues(alpha: 0.2) : const Color(0xFFF3F4F6), width: 1.5),
                borderRadius: BorderRadius.circular(22),
                boxShadow: isActivo ? [const BoxShadow(color: Color(0x0A065F46), blurRadius: 16, offset: Offset(0, 4))] : [],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: Text(space['emoji'], style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(space['nombre'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
                                  if (isActivo) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.e1, borderRadius: BorderRadius.circular(6)),
                                      child: const Text("Activo", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.e6)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(space['desc'], style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _copyInviteLink(space['nombre']),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.link, size: 16, color: AppColors.g5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Budget progress
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${fmt(gastado)} gastado", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.r5)),
                            Text("de ${fmt(presupuesto)}", style: const TextStyle(fontSize: 12, color: AppColors.g4)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(3)),
                          alignment: Alignment.centerLeft,
                          child: LayoutBuilder(
                            builder: (ctx, constraints) => AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              height: 6,
                              width: constraints.maxWidth * pct,
                              decoration: BoxDecoration(
                                color: pct > 0.9 ? AppColors.r5 : AppColors.o5,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider + members
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Miembros", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.g4)),
                        const SizedBox(height: 10),
                        ...miembros.map<Widget>((m) {
                          final isPending = m['pendiente'] == true;
                          final isAdmin = m['rol'] == 'Admin';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: (m['color'] as Color).withValues(alpha: isPending ? 0.2 : 1.0),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(m['inicial'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(m['nombre'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isPending ? AppColors.g4 : AppColors.e8)),
                                          if (m['esYo'] == true) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(5)),
                                              child: const Text("Tú", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.g5)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPending ? AppColors.a1 : (isAdmin ? AppColors.e1 : AppColors.g1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPending ? "Pendiente" : m['rol'],
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPending ? AppColors.a5 : (isAdmin ? AppColors.e6 : AppColors.g5)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        // Invite more
                        GestureDetector(
                          onTap: () => _copyInviteLink(space['nombre']),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.o5.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.o5.withValues(alpha: 0.3), width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(LucideIcons.plus, size: 14, color: AppColors.o5),
                              ),
                              const SizedBox(width: 10),
                              const Text("Invitar persona", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.o5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (150 + idx * 100).ms).slideY(begin: 0.05, end: 0, duration: 400.ms, delay: (150 + idx * 100).ms);
          }),

          // Create new space card
          GestureDetector(
            onTap: _showCreateSpace,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.o1,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.o5.withValues(alpha: 0.3), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(LucideIcons.plus, size: 28, color: AppColors.o5),
                  SizedBox(height: 8),
                  Text("Crear nuevo espacio", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.e8)),
                  SizedBox(height: 3),
                  Text("Hogar · Pareja · Viaje · Negocio", style: TextStyle(fontSize: 12, color: AppColors.g4)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
        ],
      ),
    );
  }
}
