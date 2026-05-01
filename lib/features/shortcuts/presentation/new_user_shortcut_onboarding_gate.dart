import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/menudo_cupertino_icons.dart';
import '../../../core/utils/menudo_haptics.dart';
import '../../../features/auth/auth_state.dart';
import '../../../features/subscription/subscription_provider.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../utils/storage_keys.dart';

class NewUserShortcutOnboardingGate extends ConsumerStatefulWidget {
  final Widget child;

  const NewUserShortcutOnboardingGate({super.key, required this.child});

  @override
  ConsumerState<NewUserShortcutOnboardingGate> createState() =>
      _NewUserShortcutOnboardingGateState();
}

class _NewUserShortcutOnboardingGateState
    extends ConsumerState<NewUserShortcutOnboardingGate> {
  static const _storage = FlutterSecureStorage();

  bool _checkScheduled = false;

  bool get _supportsShortcuts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) => _scheduleCheck());
    ref.listen(subscriptionProvider, (previous, next) => _scheduleCheck());
    _scheduleCheck();
    return widget.child;
  }

  void _scheduleCheck() {
    if (!_supportsShortcuts || _checkScheduled) return;
    _checkScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkScheduled = false;
      await _maybeOpenSetup();
    });
  }

  Future<void> _maybeOpenSetup() async {
    if (!mounted) return;

    final auth = ref.read(authProvider);
    final subscription = ref.read(subscriptionProvider);
    final userId = auth.userId?.trim();
    if (!auth.isAuthenticated ||
        auth.isBootstrapping ||
        userId == null ||
        userId.isEmpty ||
        (!subscription.isActive && !subscription.hasVerificationIssue)) {
      return;
    }

    final location = GoRouterState.of(context).matchedLocation;
    if (location != '/') return;

    if (!_looksLikeNewUser(auth)) return;

    final key = '${StorageKeys.shortcutOnboardingSeen}_$userId';
    final alreadySeen = await _storage.read(key: key);
    if (alreadySeen == 'true' || !mounted) return;

    await _storage.write(key: key, value: 'true');
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ShortcutPromptSheet(
        onOpenShortcuts: () {
          MenudoHaptics.medium();
          Navigator.of(sheetContext).pop();
          context.push('/shortcuts?firstRun=true');
        },
      ),
    );
  }

  bool _looksLikeNewUser(AuthState auth) {
    if (auth.needsPaywall) return true;

    final createdAt = auth.profile?.createdAt;
    if (createdAt == null) return false;

    final now = DateTime.now();
    final age = now.difference(createdAt);
    return !age.isNegative && age <= const Duration(days: 14);
  }
}

class _ShortcutPromptSheet extends StatelessWidget {
  final VoidCallback onOpenShortcuts;

  const _ShortcutPromptSheet({required this.onOpenShortcuts});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomPadding),
        decoration: BoxDecoration(
          color: context.menudo.background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: context.menudo.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: context.menudo.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.o5.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(
                MenudoCupertinoIcons.zap,
                color: AppColors.o5,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Sabías que puedes registrar gastos sin abrir Menudo?',
              style: TextStyle(
                fontSize: 22,
                height: 1.08,
                fontWeight: FontWeight.w900,
                color: context.menudo.textMain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Activa el App Shortcut nativo y enlázalo a Apple Pay o Double Tap. Cuando pagues, Menudo puede preparar el gasto y pedir lo mínimo.',
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: context.menudo.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ShortcutBenefitChip(
                    icon: MenudoCupertinoIcons.creditCard,
                    label: 'Apple Pay',
                    color: AppColors.e6,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShortcutBenefitChip(
                    icon: MenudoCupertinoIcons.sparkles,
                    label: 'Siri',
                    color: AppColors.b5,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShortcutBenefitChip(
                    icon: MenudoCupertinoIcons.checkCircle,
                    label: 'Listo',
                    color: context.menudo.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MenudoButton(
              label: 'Configurar atajo',
              isFullWidth: true,
              icon: MenudoCupertinoIcons.zap,
              onTap: onOpenShortcuts,
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  MenudoHaptics.light();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Después',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: context.menudo.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutBenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ShortcutBenefitChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.menudo.textMain,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
