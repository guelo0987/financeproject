import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../alerts/providers/alert_providers.dart';
import '../../auth/auth_state.dart';
import '../../subscription/subscription_provider.dart';
import '../../subscription/subscription_state.dart';
import '../../../core/localization/app_copy.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/display_utils.dart';
import '../../../core/utils/error_presenter.dart';
import '../../../core/utils/external_links.dart';
import '../../../core/utils/formatters.dart';
import '../../../model/user_profile.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_chip.dart';
import '../../../utils/app_env.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  bool get _showsIosShortcuts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _openShortcutInstaller(BuildContext context) async {
    MenudoHaptics.medium();
    if (context.mounted) context.push('/shortcuts');
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppPreferencesState preferences,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PreferencesSheet<String>(
        title: tr(context, es: 'Idioma de la app', en: 'App language'),
        selectedValue: preferences.languageCode,
        options: supportedAppLanguages
            .map(
              (language) => _PreferenceOption<String>(
                value: language.code,
                title: language.label(isEnglishLocale(context)),
                subtitle: language.code.toUpperCase(),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || selected == preferences.languageCode) return;
    await ref.read(appPreferencesProvider.notifier).setLanguage(selected);
  }

  Future<void> _pickMarket(
    BuildContext context,
    WidgetRef ref,
    AppPreferencesState preferences,
    UserProfile? profile,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PreferencesSheet<String>(
        title: tr(context, es: 'País y moneda', en: 'Country and currency'),
        selectedValue: preferences.marketCode,
        options: supportedAppMarkets
            .map(
              (market) => _PreferenceOption<String>(
                value: market.code,
                title: market.label(isEnglishLocale(context)),
                subtitle: market.currencyCode,
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || selected == preferences.marketCode) return;

    final market = marketFromCode(selected);
    try {
      if (profile != null) {
        await ref
            .read(authProvider.notifier)
            .updateProfile(
              name: profile.name,
              currency: market.currencyCode,
              avatarEmoji: profile.avatarEmoji,
              financialGoal: profile.financialGoal,
              goalAmount: profile.goalAmount,
              goalDate: profile.goalDate,
            );
      }
      await ref.read(appPreferencesProvider.notifier).setMarket(selected);
      if (!context.mounted) return;
      MenudoHaptics.success();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(presentError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAlerts = ref
        .watch(unreadAlertsCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);
    final profile = ref.watch(authProvider).profile;
    final subscription = ref.watch(subscriptionProvider);
    final preferences = ref.watch(appPreferencesProvider).valueOrNull;
    final currentMarket =
        preferences?.market ?? marketFromCurrency(profile?.baseCurrency);
    final currentLanguage =
        preferences?.language ??
        languageFromCode(defaultLanguageForMarket(currentMarket));
    final displayName = shortDisplayName(profile?.name);
    final initials = (displayName.isEmpty ? 'M' : displayName)
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final avatarEmoji = profile?.avatarEmoji?.trim();

    return Scaffold(
      backgroundColor: context.menudo.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    Text(
                      tr(context, es: 'Ajustes', en: 'Settings'),
                      style: MenudoTextStyles.h1,
                    ),
                    SizedBox(height: (24)),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: context.menudo.hero,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: context.menudo.surface.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.center,
                            child: avatarEmoji != null && avatarEmoji.isNotEmpty
                                ? Text(
                                    avatarEmoji,
                                    style: TextStyle(fontSize: 32),
                                  )
                                : Text(
                                    initials.isEmpty ? 'M' : initials,
                                    style: MenudoTextStyles.h2.copyWith(
                                      color: context.menudo.textOnDark,
                                    ),
                                  ),
                          ),
                          SizedBox(width: (16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.isEmpty
                                      ? tr(
                                          context,
                                          es: 'Tu cuenta',
                                          en: 'Your account',
                                        )
                                      : displayName,
                                  style: MenudoTextStyles.h3.copyWith(
                                    color: context.menudo.textOnDark,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  profile?.email ??
                                      tr(
                                        context,
                                        es: 'Sesión activa',
                                        en: 'Active session',
                                      ),
                                  style: MenudoTextStyles.bodyMedium.copyWith(
                                    color: context.menudo.textOnDarkSub,
                                  ),
                                ),
                                SizedBox(height: (10)),
                                MenudoChip.custom(
                                  label: currentMarket.currencyCode,
                                  color: context.menudo.textOnDark,
                                  bgColor: context.menudo.surface.withValues(
                                    alpha: 0.12,
                                  ),
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
                    _SectionHeader(tr(context, es: 'Cuenta', en: 'Account')),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: MenudoCupertinoIcons.person_outline_rounded,
                            title: tr(
                              context,
                              es: 'Mi perfil',
                              en: 'My profile',
                            ),
                            subtitle: tr(
                              context,
                              es: 'Nombre, meta y seguridad',
                              en: 'Name, goals and security',
                            ),
                            onTap: () => context.push('/profile'),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: context.menudo.divider,
                          ),
                          _SettingsTile(
                            icon:
                                MenudoCupertinoIcons.notifications_none_rounded,
                            title: tr(context, es: 'Alertas', en: 'Alerts'),
                            subtitle: unreadAlerts > 0
                                ? tr(
                                    context,
                                    es: '$unreadAlerts sin leer',
                                    en: '$unreadAlerts unread',
                                  )
                                : tr(
                                    context,
                                    es: 'Todo al día',
                                    en: 'All caught up',
                                  ),
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
                    SizedBox(height: (24)),
                    _SectionHeader(
                      tr(context, es: 'Preferencias', en: 'Preferences'),
                    ),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: MenudoCupertinoIcons.language_rounded,
                            title: tr(context, es: 'Idioma', en: 'Language'),
                            subtitle: currentLanguage.label(
                              isEnglishLocale(context),
                            ),
                            onTap: preferences == null
                                ? null
                                : () =>
                                      _pickLanguage(context, ref, preferences),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: context.menudo.divider,
                          ),
                          _SettingsTile(
                            icon: MenudoCupertinoIcons.public_rounded,
                            title: tr(
                              context,
                              es: 'País y moneda',
                              en: 'Country and currency',
                            ),
                            subtitle: currentMarket.label(
                              isEnglishLocale(context),
                            ),
                            onTap: preferences == null
                                ? null
                                : () => _pickMarket(
                                    context,
                                    ref,
                                    preferences,
                                    profile,
                                  ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.04),
                    SizedBox(height: (24)),
                    _SectionHeader(
                      tr(context, es: 'Herramientas', en: 'Tools'),
                    ),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: MenudoCupertinoIcons.repeat_rounded,
                            title: tr(
                              context,
                              es: 'Transacciones automáticas',
                              en: 'Automatic transactions',
                            ),
                            subtitle: tr(
                              context,
                              es: 'Cobros y pagos recurrentes',
                              en: 'Recurring payments and income',
                            ),
                            onTap: () => context.push('/recurring'),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: context.menudo.divider,
                          ),
                          _SettingsTile(
                            icon: MenudoCupertinoIcons.grid_view_rounded,
                            title: tr(
                              context,
                              es: 'Herramientas de categorías',
                              en: 'Category tools',
                            ),
                            subtitle: tr(
                              context,
                              es: 'Organiza y ajusta tus categorías',
                              en: 'Organize and refine categories',
                            ),
                            onTap: () => context.push('/tools'),
                          ),
                          if (_showsIosShortcuts) ...[
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: context.menudo.divider,
                            ),
                            _SettingsTile(
                              icon: MenudoCupertinoIcons.zap,
                              title: tr(
                                context,
                                es: 'Atajo de Apple Pay',
                                en: 'Apple Pay shortcut',
                              ),
                              subtitle: tr(
                                context,
                                es: 'App Shortcut listo para enlazar',
                                en: 'App Shortcut ready to connect',
                              ),
                              onTap: () => _openShortcutInstaller(context),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.04),
                    SizedBox(height: (24)),
                    _SectionHeader(
                      tr(context, es: 'Suscripción', en: 'Subscription'),
                    ),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: _subscriptionIcon(subscription.estado),
                            title: 'Menudo Pro',
                            subtitle: _subscriptionSubtitle(
                              context,
                              subscription,
                            ),
                            trailing: subscription.hasVerificationIssue
                                ? const MenudoChip(
                                    'REVISAR',
                                    variant: MenudoChipVariant.neutral,
                                  )
                                : subscription.isActive
                                ? MenudoChip(
                                    subscription.estado == 'prueba'
                                        ? 'TRIAL'
                                        : 'PRO',
                                    variant: MenudoChipVariant.primary,
                                  )
                                : subscription.estado == 'vencida'
                                ? const MenudoChip(
                                    'VENCIDO',
                                    variant: MenudoChipVariant.danger,
                                  )
                                : null,
                            onTap: () => context.push('/subscription'),
                          ),
                          if (subscription.expiresAt != null &&
                              !subscription.hasVerificationIssue &&
                              subscription.isActive) ...[
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: context.menudo.divider,
                            ),
                            _SettingsTile(
                              icon: MenudoCupertinoIcons.calendar_today_rounded,
                              title: subscription.estado == 'prueba'
                                  ? tr(
                                      context,
                                      es: 'Trial hasta',
                                      en: 'Trial until',
                                    )
                                  : subscription.estado == 'cancelada'
                                  ? tr(
                                      context,
                                      es: 'Acceso hasta',
                                      en: 'Access until',
                                    )
                                  : tr(
                                      context,
                                      es: 'Se renueva',
                                      en: 'Renews on',
                                    ),
                              subtitle: formatDateByPattern(
                                subscription.expiresAt!,
                              ),
                              trailing: subscription.estado == 'cancelada'
                                  ? const MenudoChip(
                                      'NO RENUEVA',
                                      variant: MenudoChipVariant.neutral,
                                    )
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.04),
                    SizedBox(height: (24)),
                    _SectionHeader(tr(context, es: 'Contacto', en: 'Contact')),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: _SettingsTile(
                        icon: MenudoCupertinoIcons.chat_bubble_outline_rounded,
                        title: tr(
                          context,
                          es: 'Reportes y sugerencias',
                          en: 'Reports and suggestions',
                        ),
                        subtitle: tr(
                          context,
                          es: 'Bugs, mejoras y ayuda',
                          en: 'Bugs, ideas and support',
                        ),
                        onTap: () => context.push('/contact'),
                      ),
                    ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.04),
                    SizedBox(height: (24)),
                    _SectionHeader(
                      tr(context, es: 'Ayuda y legal', en: 'Help and legal'),
                    ),
                    MenudoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: MenudoCupertinoIcons.support_agent_rounded,
                            title: tr(
                              context,
                              es: 'Centro de ayuda',
                              en: 'Help center',
                            ),
                            subtitle: tr(
                              context,
                              es: 'Soporte, contacto y seguimiento',
                              en: 'Support, contact and follow-up',
                            ),
                            onTap: () => ExternalLinks.openUrlOrNotify(
                              context,
                              AppEnv.supportUrl,
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: context.menudo.divider,
                          ),
                          _SettingsTile(
                            icon: MenudoCupertinoIcons.privacy_tip_outlined,
                            title: tr(
                              context,
                              es: 'Política de privacidad',
                              en: 'Privacy policy',
                            ),
                            subtitle: tr(
                              context,
                              es: 'Cómo manejamos tus datos',
                              en: 'How we handle your data',
                            ),
                            onTap: () => ExternalLinks.openUrlOrNotify(
                              context,
                              AppEnv.privacyPolicyUrl,
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: context.menudo.divider,
                          ),
                          _SettingsTile(
                            icon: MenudoCupertinoIcons.description_outlined,
                            title: tr(
                              context,
                              es: 'Términos de servicio',
                              en: 'Terms of service',
                            ),
                            subtitle: tr(
                              context,
                              es: 'Condiciones de uso de Menudo',
                              en: 'Conditions for using Menudo',
                            ),
                            onTap: () => ExternalLinks.openUrlOrNotify(
                              context,
                              AppEnv.termsUrl,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.04),
                    SizedBox(height: 40),
                    MenudoSecondaryButton(
                      label: tr(context, es: 'Cerrar sesión', en: 'Sign out'),
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                    ).animate().fadeIn(delay: 340.ms),
                    SizedBox(height: (120)),
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
          color: context.menudo.textMuted,
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
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return MenudoInkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.menudo.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: (20),
                color: context.menudo.textSecondary,
              ),
            ),
            SizedBox(width: (14)),
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
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MenudoTextStyles.bodySmall.copyWith(
                      color: context.menudo.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, SizedBox(width: (10))],
            if (onTap != null)
              Icon(
                MenudoCupertinoIcons.chevron_right_rounded,
                color: context.menudo.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

IconData _subscriptionIcon(String? estado) {
  return switch (estado) {
    'prueba' => MenudoCupertinoIcons.access_time_rounded,
    'activa' => MenudoCupertinoIcons.star_rounded,
    'cancelada' => MenudoCupertinoIcons.cancel_outlined,
    'vencida' => MenudoCupertinoIcons.error_outline_rounded,
    _ => MenudoCupertinoIcons.star_outline_rounded,
  };
}

String _subscriptionSubtitle(BuildContext context, SubscriptionState sub) {
  if (sub.hasVerificationIssue) {
    return tr(
      context,
      es: 'No pudimos comprobar tu acceso ahora mismo',
      en: 'We could not verify your access right now',
    );
  }

  final planLabel = switch (sub.plan) {
    'annual' => tr(context, es: 'Plan anual', en: 'Annual plan'),
    'lifetime' => tr(context, es: 'De por vida', en: 'Lifetime'),
    'monthly' => tr(context, es: 'Plan mensual', en: 'Monthly plan'),
    _ => '',
  };

  return switch (sub.estado) {
    'prueba' =>
      '$planLabel · ${tr(context, es: 'Prueba gratuita', en: 'Free trial')}',
    'activa' =>
      sub.plan == 'lifetime'
          ? tr(context, es: 'Acceso permanente', en: 'Permanent access')
          : '$planLabel ${tr(context, es: 'activo', en: 'active')}',
    'cancelada' =>
      '$planLabel · ${tr(context, es: 'Cancelado', en: 'Canceled')}',
    'vencida' => tr(
      context,
      es: 'Suscripción vencida',
      en: 'Subscription expired',
    ),
    _ => tr(context, es: 'Activar suscripción', en: 'Activate subscription'),
  };
}

class _PreferencesSheet<T> extends StatelessWidget {
  const _PreferencesSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<_PreferenceOption<T>> options;
  final T selectedValue;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.menudo.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + safeBottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.menudo.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(height: (18)),
              Text(title, style: MenudoTextStyles.h3),
              SizedBox(height: (18)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: context.menudo.divider,
                  ),
                  itemBuilder: (context, index) => _PreferenceRow<T>(
                    option: options[index],
                    selected: options[index].value == selectedValue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceOption<T> {
  const _PreferenceOption({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final T value;
  final String title;
  final String subtitle;
}

class _PreferenceRow<T> extends StatelessWidget {
  const _PreferenceRow({required this.option, required this.selected});

  final _PreferenceOption<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return MenudoInkWell(
      onTap: () => Navigator.of(context).pop(option.value),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MenudoTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    option.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MenudoTextStyles.bodySmall.copyWith(
                      color: context.menudo.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                MenudoCupertinoIcons.check_rounded,
                color: context.menudo.textMain,
              ),
          ],
        ),
      ),
    );
  }
}
