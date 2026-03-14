import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../alerts/providers/alert_providers.dart';
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
    final unreadAlerts = ref
        .watch(unreadAlertsCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);

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
                    Text('Ajustes', style: MenudoTextStyles.h1),
                    const SizedBox(height: 32),

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
                            'Todo en orden',
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
                    _buildSectionHeader('Herramientas'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
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

                    _buildSectionHeader('Cuenta'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildListTile(
                            Icons.notifications_none,
                            'Alertas',
                            () {
                              context.push('/alerts');
                            },
                            trailing: unreadAlerts > 0
                                ? MenudoChip(
                                    unreadAlerts.toString(),
                                    variant: MenudoChipVariant.primary,
                                  )
                                : null,
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

  Widget _buildListTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
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
            if (trailing != null) ...[trailing, const SizedBox(width: 12)],
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
