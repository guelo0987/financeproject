import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/subscription_service.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_logo.dart';
import '../subscription_provider.dart';
import '../subscription_state.dart';

// ─── Plan Enum ────────────────────────────────────────────────────────────────

enum _Plan { monthly, annual, lifetime }

// ─── Screen ──────────────────────────────────────────────────────────────────

class PaywallScreen extends ConsumerStatefulWidget {
  final bool fromRegistration;

  const PaywallScreen({super.key, this.fromRegistration = false});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  _Plan _selected = _Plan.annual;
  Offering? _offering;
  bool _loadingOffering = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      final offering = await service.getOfferings();
      if (mounted) setState(() { _offering = offering; _loadingOffering = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingOffering = false);
    }
  }

  String _monthlyEquiv(double monthly) => '\$${monthly.toStringAsFixed(2)}';

  Package? get _selectedPackage {
    if (_offering == null) return null;
    return switch (_selected) {
      _Plan.monthly  => _offering!.monthly,
      _Plan.annual   => _offering!.annual,
      _Plan.lifetime => _offering!.lifetime,
    };
  }

  Future<void> _purchase() async {
    final pkg = _selectedPackage;
    if (pkg == null) return;

    setState(() => _purchasing = true);
    try {
      await Purchases.purchasePackage(pkg);
      // Success is handled by subscriptionProvider listener below
    } on PurchasesError catch (e) {
      if (mounted && e.code != PurchasesErrorCode.purchaseCancelledError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar el pago. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    try {
      await Purchases.restorePurchases();
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Navigate home as soon as subscription becomes active
    ref.listen<SubscriptionState>(subscriptionProvider, (prev, next) {
      if (!next.isLoading && next.isActive && mounted) {
        ref.read(authProvider.notifier).clearPaywallFlag();
        context.go('/');
      }
    });

    return PopScope(
      canPop: !widget.fromRegistration,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildBenefits()),
            SliverToBoxAdapter(child: _buildPlans()),
            SliverToBoxAdapter(child: _buildCTA()),
            SliverToBoxAdapter(child: _buildFooter()),
          ],
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      color: AppColors.g0,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 28,
        left: 24,
        right: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top nav bar
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) context.go('/login');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.g2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.e8, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        'Iniciar sesión',
                        style: MenudoTextStyles.bodySmall.copyWith(
                          color: AppColors.e8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (!widget.fromRegistration)
                GestureDetector(
                  onTap: () {
                    ref.read(authProvider.notifier).clearPaywallFlag();
                    if (context.canPop()) context.pop();
                    else context.go('/settings');
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.g2),
                    ),
                    child: const Icon(Icons.close_rounded, color: AppColors.e8, size: 18),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Logo on white card
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.e8.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: const MenudoLogo(size: 76),
          ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 20),

          // PRO badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.o5,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'PRO',
              style: MenudoTextStyles.labelCaps.copyWith(
                color: AppColors.white,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          Text(
            'Finanzas sin límites.',
            style: MenudoTextStyles.h1.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 6),

          Text(
            'Tú decides cuánto crecer.',
            style: MenudoTextStyles.bodyLarge.copyWith(color: AppColors.g5),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 20),

          // Trust pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.e0,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.e1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, color: AppColors.e6, size: 14),
                const SizedBox(width: 7),
                Text(
                  '7 días gratis — cancela cuando quieras',
                  style: MenudoTextStyles.labelCaps.copyWith(
                    color: AppColors.e7,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 380.ms),
        ],
      ),
    );
  }

  // ── Benefits ──────────────────────────────────────────────────────────────

  Widget _buildBenefits() {
    final items = [
      (Icons.account_balance_wallet_outlined, 'Billeteras ilimitadas',  'Registra todas tus cuentas y efectivo'),
      (Icons.pie_chart_outline_rounded,       'Presupuestos avanzados', 'Con metas, límites y seguimiento real'),
      (Icons.repeat_rounded,                  'Pagos recurrentes',      'Automatiza tus gastos fijos'),
      (Icons.group_outlined,                  'Espacios compartidos',   'Gestiona finanzas en pareja o familia'),
      (Icons.bar_chart_rounded,               'Reportes detallados',    'Visualiza tus patrones de gasto'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Todo lo que necesitas', style: MenudoTextStyles.h3)
              .animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 2),
          Text(
            'Una herramienta completa para tu salud financiera.',
            style: MenudoTextStyles.bodySmall.copyWith(color: AppColors.g5),
          ).animate().fadeIn(delay: 550.ms),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((e) => _BenefitRow(
            icon: e.value.$1,
            title: e.value.$2,
            subtitle: e.value.$3,
            delay: 600 + e.key * 70,
          )),
        ],
      ),
    );
  }

  // ── Plans ─────────────────────────────────────────────────────────────────

  Widget _buildPlans() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Elige tu plan', style: MenudoTextStyles.h3)
              .animate().fadeIn(delay: 950.ms),
          const SizedBox(height: 4),
          Text(
            'Empieza gratis. Sin compromiso.',
            style: MenudoTextStyles.bodySmall.copyWith(color: AppColors.g5),
          ).animate().fadeIn(delay: 1000.ms),
          const SizedBox(height: 16),

          _PlanCard(
            selected: _selected == _Plan.annual,
            title: 'Anual',
            price: _offering?.annual?.storeProduct.priceString ?? r'$53.99',
            period: r'/ año',
            detail: 'Solo ${_offering?.annual != null ? _monthlyEquiv(_offering!.annual!.storeProduct.price / 12) : "\$4.50"}/mes',
            badge: 'MÁS POPULAR',
            badgeColor: AppColors.o5,
            onTap: () => setState(() => _selected = _Plan.annual),
          ).animate().fadeIn(delay: 1050.ms).slideY(begin: 0.1),

          const SizedBox(height: 10),

          _PlanCard(
            selected: _selected == _Plan.monthly,
            title: 'Mensual',
            price: _offering?.monthly?.storeProduct.priceString ?? r'$7.99',
            period: r'/ mes',
            detail: 'Con período de prueba de 7 días',
            badge: null,
            badgeColor: null,
            onTap: () => setState(() => _selected = _Plan.monthly),
          ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1),

          const SizedBox(height: 10),

          _PlanCard(
            selected: _selected == _Plan.lifetime,
            title: 'De por vida',
            price: _offering?.lifetime?.storeProduct.priceString ?? r'$89.99',
            period: '',
            detail: 'Pago único — acceso permanente',
            badge: 'SIN RENOVACIÓN',
            badgeColor: AppColors.p5,
            onTap: () => setState(() => _selected = _Plan.lifetime),
          ).animate().fadeIn(delay: 1150.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  Widget _buildCTA() {
    final isLifetime = _selected == _Plan.lifetime;
    final label = _purchasing
        ? 'Procesando...'
        : isLifetime
            ? 'Obtener acceso de por vida'
            : 'Empezar 7 días gratis';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          MenudoPrimaryButton(
            label: label,
            onTap: (_purchasing || _loadingOffering) ? null : _purchase,
            isDisabled: _purchasing || _loadingOffering,
          ),
          if (!isLifetime) ...[
            const SizedBox(height: 10),
            Text(
              'Sin cobro durante 7 días. Cancela antes y no pagas nada.',
              style: MenudoTextStyles.bodySmall.copyWith(color: AppColors.g5),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ).animate().fadeIn(delay: 1250.ms),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Column(
        children: [
          TextButton(
            onPressed: _purchasing ? null : _restore,
            child: Text(
              'Restaurar compras anteriores',
              style: MenudoTextStyles.bodySmall.copyWith(color: AppColors.g5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Al continuar aceptas los Términos de Servicio\ny la Política de Privacidad de Menudo.',
            style: MenudoTextStyles.labelCaps.copyWith(
              color: AppColors.g4,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(delay: 1300.ms),
    );
  }
}

// ─── Benefit Row ─────────────────────────────────────────────────────────────

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.e0,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.e6, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MenudoTextStyles.bodyMedium),
                Text(
                  subtitle,
                  style: MenudoTextStyles.bodySmall.copyWith(color: AppColors.g5),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.e6, size: 20),
        ],
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: -0.05),
    );
  }
}

// ─── Plan Card ───────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String price;
  final String period;
  final String detail;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _PlanCard({
    required this.selected,
    required this.title,
    required this.price,
    required this.period,
    required this.detail,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.e8 : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.e8 : AppColors.g2,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.e8.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.white : AppColors.g3,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.e8,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Title + detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: MenudoTextStyles.bodyLarge.copyWith(
                          color: selected ? Colors.white : AppColors.e8,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.18)
                                : badgeColor!.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            badge!,
                            style: MenudoTextStyles.labelCaps.copyWith(
                              color: selected ? Colors.white : badgeColor,
                              fontSize: 8,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: MenudoTextStyles.bodySmall.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.65)
                          : AppColors.g5,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: MenudoTextStyles.amountMedium.copyWith(
                        color: selected ? Colors.white : AppColors.e8,
                      ),
                    ),
                    if (period.isNotEmpty)
                      Text(
                        period,
                        style: MenudoTextStyles.bodySmall.copyWith(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.65)
                              : AppColors.g5,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
