import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_chip.dart';
import '../subscription_provider.dart';
import '../subscription_state.dart';

class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    _CircleActionButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 14),
                    Text('Menudo Pro', style: MenudoTextStyles.h1),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.e8,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MenudoChip.custom(
                        label: _statusChipLabel(subscription),
                        color: Colors.white,
                        bgColor: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _headline(subscription),
                        style: MenudoTextStyles.h2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitle(subscription),
                        style: MenudoTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      if (subscription.expiresAt != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _dateLabel(subscription),
                                  style: MenudoTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: MenudoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      _BenefitRow(
                        icon: Icons.tune_rounded,
                        title: 'Todo en un solo lugar',
                        subtitle:
                            'Aquí ves tu estado, fecha importante y la acción correcta.',
                      ),
                      SizedBox(height: 16),
                      _BenefitRow(
                        icon: Icons.verified_outlined,
                        title: 'Más claridad',
                        subtitle:
                            'Te mostramos si tu acceso sigue activo, en prueba o si ya necesita atención.',
                      ),
                      SizedBox(height: 16),
                      _BenefitRow(
                        icon: Icons.credit_card_rounded,
                        title: 'Gestión segura',
                        subtitle:
                            'Los cambios del plan y la facturación se manejan desde tu cuenta de Apple.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: subscription.isActive
                    ? MenudoButton(
                        label: 'Abrir gestión del plan',
                        isFullWidth: true,
                        onTap: RevenueCatUI.presentCustomerCenter,
                      )
                    : MenudoButton(
                        label: 'Ver planes',
                        isFullWidth: true,
                        onTap: () => context.push('/paywall'),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Text(
                  subscription.isActive
                      ? 'Si quieres cambiar, cancelar o revisar cobros, lo haces desde esa gestión.'
                      : 'Si ya habías pagado antes, también puedes recuperar tu acceso desde la pantalla de planes.',
                  style: MenudoTextStyles.bodySmall.copyWith(
                    color: MenudoColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.e1,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: AppColors.e8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: MenudoTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
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
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: MenudoColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: MenudoColors.textMain),
      ),
    );
  }
}

String _statusChipLabel(SubscriptionState subscription) {
  if (subscription.hasVerificationIssue) return 'REVISAR';

  return switch (subscription.estado) {
    'prueba' => 'TRIAL',
    'activa' => 'PRO',
    'cancelada' => 'NO RENUEVA',
    'vencida' => 'VENCIDO',
    _ => 'MENUDO PRO',
  };
}

String _headline(SubscriptionState subscription) {
  if (subscription.hasVerificationIssue) {
    return 'No pudimos comprobar tu acceso';
  }

  return switch (subscription.estado) {
    'prueba' => 'Tu prueba está activa',
    'activa' =>
      subscription.plan == 'lifetime'
          ? 'Tienes acceso de por vida'
          : 'Tu plan está activo',
    'cancelada' => 'Tu plan sigue activo',
    'vencida' => 'Tu acceso venció',
    _ => 'Activa Menudo Pro',
  };
}

String _subtitle(SubscriptionState subscription) {
  if (subscription.hasVerificationIssue) {
    return 'Parece un problema momentáneo. Puedes seguir usando la app y volver a intentarlo más tarde.';
  }

  final planLabel = switch (subscription.plan) {
    'annual' => 'Plan anual',
    'lifetime' => 'Acceso de por vida',
    'monthly' => 'Plan mensual',
    _ => 'Suscripción',
  };

  return switch (subscription.estado) {
    'prueba' => '$planLabel con acceso completo mientras dura tu prueba.',
    'activa' =>
      '$planLabel listo para seguir acompañando tu control financiero.',
    'cancelada' => '$planLabel activo hasta que termine el período ya pagado.',
    'vencida' => 'Puedes reactivar Menudo Pro cuando quieras.',
    _ => 'Elige el plan que mejor vaya contigo.',
  };
}

String _dateLabel(SubscriptionState subscription) {
  final expiresAt = subscription.expiresAt;
  if (expiresAt == null) return 'Sin fecha disponible';

  final prefix = switch (subscription.estado) {
    'prueba' => 'Tu prueba termina',
    'cancelada' => 'Tu acceso termina',
    'activa' when subscription.plan == 'lifetime' => 'Tu acceso está activo',
    _ => 'Próxima fecha clave',
  };

  if (subscription.plan == 'lifetime') {
    return prefix;
  }

  return '$prefix el ${DateFormat('d MMM yyyy', 'es').format(expiresAt)}';
}
