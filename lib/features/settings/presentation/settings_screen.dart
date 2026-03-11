import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/demo_mode_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_chip.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../auth/auth_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final demoMode = ref.watch(demoModeProvider);

    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    Text('Perfil', style: MenudoTextStyles.h1),
                    const SizedBox(height: 32),

                    // Avatar & Info
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MenudoColors.primaryLight.withValues(
                                alpha: 0.5,
                              ),
                              border: Border.all(
                                color: MenudoColors.primaryLight,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_outline,
                                size: 32,
                                color: MenudoColors.primary,
                              ),
                            ),
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 16),
                          Text(
                            'Tu cuenta',
                            style: MenudoTextStyles.h2,
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: 8),
                          const MenudoChip(
                            'Sesión activa',
                            variant: MenudoChipVariant.primary,
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Cuenta'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildListTile(
                            Icons.person_outline,
                            'Tus datos',
                            () {},
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _buildListTile(Icons.security, 'Seguridad', () {}),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _buildListTile(Icons.devices, 'Dispositivos', () {}),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Espacios'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildListTile(
                            Icons.group,
                            'Gestionar Espacios Compartidos',
                            () {
                              context.push('/spaces-manager');
                            },
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _buildListTile(
                            Icons.repeat,
                            'Transacciones Automáticas',
                            () {
                              context.push('/recurring');
                            },
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _buildListTile(
                            Icons.grid_view,
                            'Herramientas de categorías',
                            () {
                              context.push('/tools');
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Configuración'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildListTile(
                            Icons.notifications_none,
                            'Notificaciones',
                            () {},
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _buildListTile(
                            Icons.dark_mode_outlined,
                            'Tema (Claro/Oscuro)',
                            () {},
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _buildListTile(
                            Icons.help_outline,
                            'Centro de Ayuda',
                            () {},
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          SwitchListTile.adaptive(
                            value: demoMode,
                            onChanged: (value) => ref
                                .read(demoModeProvider.notifier)
                                .setEnabled(value),
                            title: const Text(
                              'Mostrar datos demo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text(
                              'Usa datos mock solo cuando tu cuenta esté vacía.',
                              style: TextStyle(fontSize: 12),
                            ),
                            secondary: const Icon(
                              Icons.science_outlined,
                              color: MenudoColors.textSecondary,
                            ),
                            activeThumbColor: MenudoColors.primary,
                            activeTrackColor: MenudoColors.primaryLight,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),

                    const SizedBox(height: 48),

                    MenudoSecondaryButton(
                      label: 'Cerrar sesión',
                      onTap: () {
                        // Logout logic
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 120), // Bottom nav padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: MenudoTextStyles.labelCaps.copyWith(
          color: MenudoColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: MenudoColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: MenudoTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: MenudoColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
