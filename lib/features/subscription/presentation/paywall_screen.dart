import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../core/utils/external_links.dart';
import '../../../services/subscription_service.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_logo.dart';
import '../../../utils/app_env.dart';
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
  String? _offeringError;
  String? _purchaseFeedback;
  bool _purchaseFeedbackIsError = true;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    setState(() {
      _loadingOffering = true;
      _offeringError = null;
      _purchaseFeedback = null;
    });

    try {
      final service = ref.read(subscriptionServiceProvider);
      final offering = await service.getOfferings();
      if (mounted) {
        setState(() {
          _offering = offering;
          _syncSelection(offering);
          _offeringError = _hasPackages(offering)
              ? null
              : 'Los planes no están disponibles ahora mismo.';
          _loadingOffering = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingOffering = false;
          _offeringError =
              'No pudimos cargar los planes. Intenta de nuevo en un momento.';
        });
      }
    }
  }

  String _monthlyEquiv(double monthly) => '\$${monthly.toStringAsFixed(2)}';

  String _unitLabel(PeriodUnit unit, int quantity) {
    return switch (unit) {
      PeriodUnit.day => quantity == 1 ? 'día' : 'días',
      PeriodUnit.week => quantity == 1 ? 'semana' : 'semanas',
      PeriodUnit.month => quantity == 1 ? 'mes' : 'meses',
      PeriodUnit.year => quantity == 1 ? 'año' : 'años',
      _ => 'periodo',
    };
  }

  String? _introSummary(Package? package) {
    final intro = package?.storeProduct.introductoryPrice;
    if (intro == null) return null;

    final unit = _unitLabel(intro.periodUnit, intro.periodNumberOfUnits);
    final duration = intro.cycles == 1
        ? '${intro.periodNumberOfUnits} $unit'
        : '${intro.cycles * intro.periodNumberOfUnits} $unit';

    if (intro.price == 0) return '$duration gratis';
    return '${intro.priceString} por $duration';
  }

  String _selectedPlanLabel() {
    return switch (_selected) {
      _Plan.annual => 'plan anual',
      _Plan.monthly => 'plan mensual',
      _Plan.lifetime => 'acceso de por vida',
    };
  }

  String _trustMessage() {
    final intro = _introSummary(_selectedPackage);
    if (intro != null) {
      return '$intro — cancelas cuando quieras';
    }
    if (_selected == _Plan.lifetime) {
      return 'Compra segura desde tu iPhone';
    }
    return 'El cobro sigue el plan que elijas';
  }

  String _planDetail(_Plan plan, Package package) {
    final intro = _introSummary(package);

    return switch (plan) {
      _Plan.annual =>
        package.storeProduct.pricePerMonthString != null
            ? 'Solo ${package.storeProduct.pricePerMonthString}/mes'
            : 'Solo ${_monthlyEquiv(package.storeProduct.price / 12)}/mes',
      _Plan.monthly =>
        intro != null ? 'Incluye $intro' : 'Plan flexible mes a mes',
      _Plan.lifetime => 'Pago único — acceso permanente',
    };
  }

  String _ctaLabel(bool isLifetime) {
    if (_purchasing) return 'Procesando...';
    if (_loadingOffering) return 'Cargando planes...';
    if (_selectedPackage == null) return 'Planes no disponibles';
    if (isLifetime) return 'Obtener acceso de por vida';

    final intro = _introSummary(_selectedPackage);
    if (intro != null) return 'Continuar con ${_selectedPlanLabel()}';
    return 'Activar ${_selectedPlanLabel()}';
  }

  String? _ctaHelper(bool isLifetime) {
    if (_loadingOffering ||
        _offeringError != null ||
        _selectedPackage == null) {
      return null;
    }
    if (isLifetime) return null;

    final intro = _introSummary(_selectedPackage);
    if (intro != null) {
      return 'Empiezas con $intro y luego sigue el plan seleccionado.';
    }
    return 'El cobro se hará con el plan que selecciones.';
  }

  bool _hasPackages(Offering? offering) =>
      offering?.monthly != null ||
      offering?.annual != null ||
      offering?.lifetime != null;

  Package? _packageForPlan(Offering offering, _Plan plan) {
    return switch (plan) {
      _Plan.monthly => offering.monthly,
      _Plan.annual => offering.annual,
      _Plan.lifetime => offering.lifetime,
    };
  }

  void _syncSelection(Offering? offering) {
    if (offering == null) return;
    if (_packageForPlan(offering, _selected) != null) return;

    _selected = offering.annual != null
        ? _Plan.annual
        : offering.monthly != null
        ? _Plan.monthly
        : _Plan.lifetime;
  }

  Package? get _selectedPackage {
    if (_offering == null) return null;
    return switch (_selected) {
      _Plan.monthly => _offering!.monthly,
      _Plan.annual => _offering!.annual,
      _Plan.lifetime => _offering!.lifetime,
    };
  }

  Future<void> _purchase() async {
    final pkg = _selectedPackage;
    if (pkg == null) {
      _showFeedback(
        _offeringError ?? 'Todavia no tenemos un plan disponible para ti.',
      );
      return;
    }

    setState(() {
      _purchasing = true;
      _purchaseFeedback = null;
    });
    try {
      final service = ref.read(subscriptionServiceProvider);
      final result = await service.purchasePackage(pkg);
      if (result == null) {
        _showFeedback(
          'Las compras todavía no están configuradas en esta build.',
        );
        return;
      }
      await ref.read(subscriptionProvider.notifier).refresh();
    } on PurchasesError catch (e) {
      _showFeedback(_purchaseErrorMessage(e));
    } on PlatformException catch (error) {
      _showFeedback(_platformPurchaseErrorMessage(error));
    } catch (error) {
      _showFeedback(
        presentError(
          error,
          fallback:
              'No pudimos procesar la compra ahora mismo. Intenta de nuevo.',
        ),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _purchasing = true;
      _purchaseFeedback = null;
    });
    try {
      final service = ref.read(subscriptionServiceProvider);
      final info = await service.restorePurchases();
      if (info == null) {
        _showFeedback(
          'Las compras todavía no están configuradas en esta build.',
        );
        return;
      }
      await ref.read(subscriptionProvider.notifier).refresh();
      if (!mounted) return;
      final restored = info.entitlements.active.containsKey(kEntitlementId);
      _showFeedback(
        restored
            ? 'Recuperamos tu acceso de Menudo Pro.'
            : 'No encontramos compras para restaurar con esta cuenta.',
        isError: !restored,
      );
    } on PurchasesError catch (e) {
      _showFeedback(_purchaseErrorMessage(e, isRestore: true));
    } on PlatformException catch (error) {
      _showFeedback(_platformPurchaseErrorMessage(error, isRestore: true));
    } catch (error) {
      _showFeedback(
        presentError(
          error,
          fallback:
              'No pudimos restaurar tus compras ahora mismo. Intenta de nuevo.',
        ),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  String _purchaseErrorMessage(PurchasesError error, {bool isRestore = false}) {
    final code = error.code.toString().split('.').last;

    return switch (code) {
      'purchaseCancelledError' =>
        isRestore
            ? 'La restauración fue cancelada.'
            : 'La compra fue cancelada antes de completarse.',
      'networkError' =>
        'No pudimos conectarnos para completar la compra. Revisa tu conexión.',
      'purchaseNotAllowedError' =>
        'Este dispositivo no tiene compras habilitadas ahora mismo.',
      'storeProblemError' =>
        'La tienda no pudo procesar la compra. Intenta de nuevo en un momento.',
      'productAlreadyPurchasedError' =>
        'Ese plan ya está comprado con esta cuenta. Usa “Restaurar compras anteriores”.',
      'purchaseInvalidError' =>
        'La compra no es válida en este momento. Vuelve a intentarlo.',
      'paymentPendingError' =>
        'Tu compra quedó pendiente de aprobación. Te avisaremos cuando se confirme.',
      'operationAlreadyInProgressError' =>
        'Ya hay una compra en proceso. Espera un momento antes de intentar otra vez.',
      _ => presentError(
        error.message,
        fallback: isRestore
            ? 'No pudimos restaurar tus compras. Intenta de nuevo.'
            : 'No pudimos procesar la compra. Intenta de nuevo.',
      ),
    };
  }

  String _platformPurchaseErrorMessage(
    PlatformException error, {
    bool isRestore = false,
  }) {
    final details = error.details;
    final detailsMap = details is Map
        ? Map<String, dynamic>.from(details.cast<Object?, Object?>())
        : const <String, dynamic>{};

    final rawValues = <String>[
      error.code,
      error.message ?? '',
      detailsMap['readableErrorCode']?.toString() ?? '',
      detailsMap['readable_error_code']?.toString() ?? '',
      detailsMap['underlyingErrorMessage']?.toString() ?? '',
      detailsMap['message']?.toString() ?? '',
    ];

    final normalized = rawValues
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .join(' | ');

    final userCancelled =
        detailsMap['userCancelled'] == true ||
        normalized.contains('cancel') ||
        normalized.contains('purchasecancelled');

    if (userCancelled) {
      return isRestore
          ? 'La restauración fue cancelada.'
          : 'La compra fue cancelada antes de completarse.';
    }

    if (normalized.contains('test_store_simulated_purchase_error') ||
        normalized.contains(
          'purchase failure simulated successfully in test store',
        )) {
      return isRestore
          ? 'Test Store simuló un fallo de restauración. El manejo del error sí respondió correctamente.'
          : 'Test Store simuló un fallo de compra. El pago no se realizó; este mensaje confirma que la app ya detectó el error.';
    }

    if (normalized.contains('network')) {
      return isRestore
          ? 'No pudimos conectarnos para restaurar tus compras. Revisa tu conexión.'
          : 'No pudimos conectarnos para completar la compra. Revisa tu conexión.';
    }

    if (normalized.contains('already purchased')) {
      return 'Ese plan ya está comprado con esta cuenta. Usa “Restaurar compras anteriores”.';
    }

    if (normalized.contains('pending')) {
      return isRestore
          ? 'La restauración quedó pendiente de confirmación.'
          : 'Tu compra quedó pendiente de aprobación. Te avisaremos cuando se confirme.';
    }

    if (normalized.contains('not allowed')) {
      return 'Este dispositivo no tiene compras habilitadas ahora mismo.';
    }

    return presentError(
      detailsMap['message'] ?? error.message ?? error,
      fallback: isRestore
          ? 'No pudimos restaurar tus compras. Intenta de nuevo.'
          : 'No pudimos procesar la compra. Intenta de nuevo.',
    );
  }

  void _showFeedback(String message, {bool isError = true}) {
    if (!mounted) return;
    setState(() {
      _purchaseFeedback = message;
      _purchaseFeedbackIsError = isError;
    });
    _showSnack(message, isError: isError);
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? null : AppColors.e8,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.g2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.e8,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cerrar sesión',
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
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/settings');
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.g2),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.e8,
                      size: 18,
                    ),
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
          ).animate().scale(
            delay: 100.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),

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
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.e6,
                  size: 14,
                ),
                const SizedBox(width: 7),
                Text(
                  _trustMessage(),
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
      (
        Icons.account_balance_wallet_outlined,
        'Billeteras ilimitadas',
        'Registra todas tus cuentas y efectivo',
      ),
      (
        Icons.pie_chart_outline_rounded,
        'Presupuestos avanzados',
        'Con metas, límites y seguimiento real',
      ),
      (
        Icons.repeat_rounded,
        'Pagos recurrentes',
        'Automatiza tus gastos fijos',
      ),
      (
        Icons.group_outlined,
        'Espacios compartidos',
        'Gestiona finanzas en pareja o familia',
      ),
      (
        Icons.bar_chart_rounded,
        'Reportes detallados',
        'Visualiza tus patrones de gasto',
      ),
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
          Text(
            'Todo lo que necesitas',
            style: MenudoTextStyles.h3,
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 2),
          Text(
            'Una herramienta completa para tu salud financiera.',
            style: MenudoTextStyles.bodySmall.copyWith(color: AppColors.g5),
          ).animate().fadeIn(delay: 550.ms),
          const SizedBox(height: 16),
          ...items.asMap().entries.map(
            (e) => _BenefitRow(
              icon: e.value.$1,
              title: e.value.$2,
              subtitle: e.value.$3,
              delay: 600 + e.key * 70,
            ),
          ),
        ],
      ),
    );
  }

  // ── Plans ─────────────────────────────────────────────────────────────────

  Widget _buildPlans() {
    if (_loadingOffering) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: _StatusCard(
          icon: Icons.sync_rounded,
          title: 'Cargando planes',
          message: 'Estamos preparando las opciones disponibles para ti.',
          isLoading: true,
        ),
      );
    }

    if (_offeringError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: _StatusCard(
          icon: Icons.wifi_tethering_error_rounded,
          title: 'No pudimos mostrar los planes',
          message: _offeringError!,
          actionLabel: 'Intentar de nuevo',
          onTap: _loadOffering,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elige tu plan',
            style: MenudoTextStyles.h3,
          ).animate().fadeIn(delay: 950.ms),
          const SizedBox(height: 4),
          Text(
            'Empieza gratis. Sin compromiso.',
            style: MenudoTextStyles.bodySmall.copyWith(color: AppColors.g5),
          ).animate().fadeIn(delay: 1000.ms),
          const SizedBox(height: 16),

          if (_offering?.annual != null) ...[
            _PlanCard(
              selected: _selected == _Plan.annual,
              title: 'Anual',
              price: _offering!.annual!.storeProduct.priceString,
              period: r'/ año',
              detail: _planDetail(_Plan.annual, _offering!.annual!),
              badge: 'MÁS POPULAR',
              badgeColor: AppColors.o5,
              onTap: () => setState(() => _selected = _Plan.annual),
            ).animate().fadeIn(delay: 1050.ms).slideY(begin: 0.1),
            const SizedBox(height: 10),
          ],

          if (_offering?.monthly != null) ...[
            _PlanCard(
              selected: _selected == _Plan.monthly,
              title: 'Mensual',
              price: _offering!.monthly!.storeProduct.priceString,
              period: r'/ mes',
              detail: _planDetail(_Plan.monthly, _offering!.monthly!),
              badge: null,
              badgeColor: null,
              onTap: () => setState(() => _selected = _Plan.monthly),
            ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1),
            const SizedBox(height: 10),
          ],

          if (_offering?.lifetime != null)
            _PlanCard(
              selected: _selected == _Plan.lifetime,
              title: 'De por vida',
              price: _offering!.lifetime!.storeProduct.priceString,
              period: '',
              detail: _planDetail(_Plan.lifetime, _offering!.lifetime!),
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
    final canPurchase =
        !_purchasing &&
        !_loadingOffering &&
        _offeringError == null &&
        _selectedPackage != null;
    final helper = _ctaHelper(isLifetime);
    final label = _ctaLabel(isLifetime);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          if (_purchaseFeedback != null) ...[
            _InlinePurchaseFeedback(
              message: _purchaseFeedback!,
              isError: _purchaseFeedbackIsError,
            ),
            const SizedBox(height: 12),
          ],
          MenudoPrimaryButton(
            label: label,
            onTap: canPurchase ? _purchase : null,
            isDisabled: !canPurchase,
          ),
          if (helper != null) ...[
            const SizedBox(height: 10),
            Text(
              helper,
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: [
              Text(
                'Al continuar aceptas',
                style: MenudoTextStyles.labelCaps.copyWith(
                  color: AppColors.g4,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () =>
                    ExternalLinks.openUrlOrNotify(context, AppEnv.termsUrl),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.g5,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Términos'),
              ),
              Text(
                'y',
                style: MenudoTextStyles.labelCaps.copyWith(
                  color: AppColors.g4,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
              TextButton(
                onPressed: () => ExternalLinks.openUrlOrNotify(
                  context,
                  AppEnv.privacyPolicyUrl,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.g5,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Privacidad'),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(delay: 1300.ms),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.isLoading = false,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.g2),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.e0,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Icon(icon, color: AppColors.e7, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: MenudoTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            style: MenudoTextStyles.bodyMedium.copyWith(color: AppColors.g5),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.e8,
                side: const BorderSide(color: AppColors.g2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlinePurchaseFeedback extends StatelessWidget {
  const _InlinePurchaseFeedback({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bgColor = isError ? AppColors.r1 : AppColors.e1;
    final borderColor = isError ? AppColors.r5 : AppColors.e6;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    final textColor = isError ? AppColors.r5 : AppColors.e8;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: MenudoTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
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
      child:
          Row(
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
                          style: MenudoTextStyles.bodySmall.copyWith(
                            color: AppColors.g5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.e6,
                    size: 20,
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: delay))
              .slideX(begin: -0.05),
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
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
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
