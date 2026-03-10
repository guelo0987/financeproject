import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/menudo_chip.dart';

class SpacesManagerScreen extends StatefulWidget {
  const SpacesManagerScreen({super.key});

  @override
  State<SpacesManagerScreen> createState() => _SpacesManagerScreenState();
}

class _SpacesManagerScreenState extends State<SpacesManagerScreen> {
  final List<Map<String, dynamic>> _spaces = [
    {
      'nombre': 'Hogar Cruz',
      'emoji': '🏠',
      'desc': 'Gastos compartidos del hogar y familia',
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
      'desc': 'Fondo compartido para vacaciones 2026',
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

  String _fmt(double val) => "RD\$${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  void _showCreateSpace() {
    HapticFeedback.mediumImpact();
    // Implementation for creating space
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppColors.e8),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
              centerTitle: false,
              title: const Text(
                'Espacios',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.e8,
                  letterSpacing: -0.8,
                ),
              ),
              background: Container(color: Colors.white),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  onPressed: _showCreateSpace,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.o5, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature Header
                  _SpacesHeroCard()
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  const Text(
                    "TUS ESPACIOS COMPARTIDOS",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.g4, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),

                  if (_spaces.isEmpty)
                    _buildEmptyState()
                  else
                    ..._spaces.asMap().entries.map((entry) {
                      return _SpaceCard(
                        space: entry.value,
                        fmt: _fmt,
                      ).animate().fadeIn(duration: 500.ms, delay: (100 + entry.key * 100).ms).slideY(begin: 0.05, end: 0);
                    }),
                  
                  const SizedBox(height: 24),
                  
                  _CreateNewSpaceAction(onTap: _showCreateSpace)
                      .animate().fadeIn(duration: 500.ms, delay: 400.ms),
                      
                  const SizedBox(height: 120),
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
            const Icon(LucideIcons.users, size: 48, color: AppColors.g3),
            const SizedBox(height: 16),
            const Text("No tienes espacios aún", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.e8)),
            const SizedBox(height: 8),
            const Text("Crea un espacio para compartir presupuestos", style: TextStyle(fontSize: 14, color: AppColors.g5)),
          ],
        ),
      ),
    );
  }
}

class _SpacesHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.e8,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.e8.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.users, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Colaboración", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    Text("Finanzas en equipo", style: TextStyle(fontSize: 13, color: Color(0xFF6EE7B7), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HeroFeature(icon: LucideIcons.eye, text: "Transparencia total en gastos"),
          const SizedBox(height: 12),
          _HeroFeature(icon: LucideIcons.splitSquareHorizontal, text: "División equitativa de cuentas"),
          const SizedBox(height: 12),
          _HeroFeature(icon: LucideIcons.bell, text: "Alertas grupales instantáneas"),
        ],
      ),
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
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

class _SpaceCard extends StatelessWidget {
  final Map<String, dynamic> space;
  final String Function(double) fmt;

  const _SpaceCard({required this.space, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final bool isActivo = space['activo'] as bool;
    final List miembros = space['miembros'] as List;
    final double sp = space['gastado'] as double;
    final double tot = space['presupuesto'] as double;
    final double pct = min(sp / (tot > 0 ? tot : 1), 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isActivo ? AppColors.e8.withValues(alpha: 0.3) : AppColors.g2, width: isActivo ? 2 : 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: Text(space['emoji'], style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(space['nombre'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.e8, letterSpacing: -0.4)),
                          if (isActivo) ...[
                            const SizedBox(width: 8),
                            MenudoChip.custom(label: "ACTIVO", color: AppColors.e6, bgColor: AppColors.e1, isSmall: true),
                          ],
                        ],
                      ),
                      Text(space['desc'], style: const TextStyle(fontSize: 12, color: AppColors.g4, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                _IconAction(
                  icon: LucideIcons.settings,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Configuración de "${space['nombre']}" próximamente'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
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
                    Text("${fmt(sp)} gastado", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.r5)),
                    Text("de ${fmt(tot)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.g4)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: AppColors.g1,
                    valueColor: AlwaysStoppedAnimation<Color>(pct > 0.9 ? AppColors.r5 : AppColors.o5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.g0,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MemberAvatars(miembros: miembros),
                _SmallInviteButton(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Enlace de invitación para "${space['nombre']}" copiado'),
                        backgroundColor: AppColors.e6,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  final List miembros;
  const _MemberAvatars({required this.miembros});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(miembros.length, (i) {
        final m = miembros[i];
        return Align(
          widthFactor: 0.7,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: m['color'],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(m['inicial'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        );
      }),
    );
  }
}

class _CreateNewSpaceAction extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateNewSpaceAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.o5.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.o1, shape: BoxShape.circle),
              child: const Icon(LucideIcons.plus, size: 24, color: AppColors.o5),
            ),
            const SizedBox(height: 12),
            const Text("CREAR NUEVO ESPACIO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.e8, letterSpacing: 0.5)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.g1, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: AppColors.g5),
      ),
    );
  }
}

class _SmallInviteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SmallInviteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(LucideIcons.userPlus, size: 14, color: AppColors.o5),
          const SizedBox(width: 6),
          const Text("Invitar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.o5)),
        ],
      ),
    );
  }
}

