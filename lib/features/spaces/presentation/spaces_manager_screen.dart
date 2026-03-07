import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_chip.dart';

class SpacesManagerScreen extends StatefulWidget {
  const SpacesManagerScreen({super.key});

  @override
  State<SpacesManagerScreen> createState() => _SpacesManagerScreenState();
}

class _SpacesManagerScreenState extends State<SpacesManagerScreen> {
  final List<Map<String, dynamic>> _members = [
    {'name': 'Miguel Cruz', 'email': 'miguel@example.com', 'role': 'Admin', 'isMe': true},
    {'name': 'Sarah Cruz', 'email': 'sarah@example.com', 'role': 'Admin', 'isMe': false},
    {'name': 'Invitado Pendiente', 'email': 'familiar@example.com', 'role': 'Miembro', 'isMe': false, 'isPending': true},
  ];

  void _generateInviteLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Enlace de invitación copiado!'),
        backgroundColor: MenudoColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      appBar: AppBar(
        title: Text('Gestionar Espacio', style: MenudoTextStyles.h3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MenudoColors.textMain, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Espacio Info
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: MenudoColors.primaryLight.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: MenudoColors.primaryLight, width: 2),
                      ),
                      child: const Icon(Icons.people_alt, size: 40, color: MenudoColors.primary),
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(height: 16),
                    Text('Hogar', style: MenudoTextStyles.h2),
                    const SizedBox(height: 4),
                    Text('Espacio Familiar Compartido', style: MenudoTextStyles.bodyMedium.copyWith(color: MenudoColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Button Generate Link
              MenudoPrimaryButton(
                label: 'Generar Enlace de Invitación',
                icon: Icons.link,
                onTap: _generateInviteLink,
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 32),

              Text('Miembros del Espacio', style: MenudoTextStyles.h3),
              const SizedBox(height: 16),
              
              ...List.generate(_members.length, (index) {
                final member = _members[index];
                final isPending = member['isPending'] == true;
                final isAdmin = member['role'] == 'Admin';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MenudoCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isAdmin ? MenudoColors.primaryLight : MenudoColors.divider,
                          foregroundColor: isAdmin ? MenudoColors.primary : MenudoColors.textSecondary,
                          child: Text(member['name'].toString().substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(member['name'], style: MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                  if (member['isMe']) ...[
                                    const SizedBox(width: 8),
                                    const MenudoChip('Tú', variant: MenudoChipVariant.neutral, isSmall: true),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(member['email'], style: MenudoTextStyles.bodySmall.copyWith(color: MenudoColors.textMuted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            MenudoChip(
                              member['role'],
                              variant: isAdmin ? MenudoChipVariant.primary : MenudoChipVariant.neutral,
                              isSmall: true,
                            ),
                            if (isPending) ...[
                              const SizedBox(height: 4),
                              const MenudoChip('Pendiente', variant: MenudoChipVariant.warning, isSmall: true),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (200 + 100 * index).ms).slideY(begin: 0.1),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
