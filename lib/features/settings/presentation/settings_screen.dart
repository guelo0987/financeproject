import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../alerts/providers/alert_providers.dart';
import '../../auth/auth_state.dart';
import '../../subscription/subscription_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_chip.dart';
import '../../../shared/widgets/menudo_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAlerts = ref
        .watch(unreadAlertsCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);
    final profile = ref.watch(authProvider).profile;
    final subscription = ref.watch(subscriptionProvider);
    final initials = (profile?.name ?? 'M')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

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
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.e8,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials.isEmpty ? 'M' : initials,
                              style: MenudoTextStyles.h2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.name ?? 'Tu cuenta',
                                  style: MenudoTextStyles.h3.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  profile?.email ?? 'Sesión activa',
                                  style: MenudoTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                MenudoChip.custom(
                                  label: profile?.baseCurrency ?? 'DOP',
                                  color: Colors.white,
                                  bgColor: Colors.white.withValues(alpha: 0.12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 250.ms),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader('Cuenta'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.person_outline_rounded,
                            title: 'Mi perfil',
                            subtitle: 'Nombre, meta y seguridad',
                            onTap: () => context.push('/profile'),
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _SettingsTile(
                            icon: Icons.notifications_none_rounded,
                            title: 'Alertas',
                            subtitle: unreadAlerts > 0
                                ? '$unreadAlerts sin leer'
                                : 'Todo al día',
                            trailing: unreadAlerts > 0
                                ? MenudoChip(
                                    unreadAlerts.toString(),
                                    variant: MenudoChipVariant.primary,
                                  )
                                : null,
                            onTap: () => context.push('/alerts'),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.04),
                    const SizedBox(height: 24),
                    _SectionHeader('Herramientas'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.repeat_rounded,
                            title: 'Transacciones automáticas',
                            subtitle: 'Cobros y pagos recurrentes',
                            onTap: () => context.push('/recurring'),
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _SettingsTile(
                            icon: Icons.grid_view_rounded,
                            title: 'Herramientas de categorías',
                            subtitle: 'Organiza y ajusta tus categorías',
                            onTap: () => context.push('/tools'),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.04),
                    const SizedBox(height: 24),
                    _SectionHeader('Suscripción'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.star_outline_rounded,
                            title: 'Menudo Pro',
                            subtitle: subscription.isActive
                                ? subscription.plan == 'lifetime'
                                    ? 'Acceso de por vida'
                                    : subscription.plan == 'annual'
                                        ? 'Plan anual activo'
                                        : 'Plan mensual activo'
                                : 'Activar suscripción',
                            trailing: subscription.isActive
                                ? MenudoChip(
                                    'PRO',
                                    variant: MenudoChipVariant.primary,
                                  )
                                : null,
                            onTap: () => context.push('/paywall'),
                          ),
                          const Divider(height: 1, color: MenudoColors.divider),
                          _SettingsTile(
                            icon: Icons.manage_accounts_outlined,
                            title: 'Gestionar plan',
                            subtitle: 'Cancelar, restaurar y facturación',
                            onTap: () => RevenueCatUI.presentCustomerCenter(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.04),
                    const SizedBox(height: 24),
                    _SectionHeader('Contacto'),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: _SettingsTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Reportes y sugerencias',
                        subtitle: 'Bugs, mejoras y ayuda',
                        onTap: () => context.push('/contact'),
                      ),
                    ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.04),
                    const SizedBox(height: 40),
                    MenudoSecondaryButton(
                      label: 'Cerrar sesión',
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                    ).animate().fadeIn(delay: 320.ms),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
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
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.g1,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: MenudoColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: MenudoTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: MenudoTextStyles.bodySmall.copyWith(
                      color: MenudoColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
            const Icon(
              Icons.chevron_right_rounded,
              color: MenudoColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
