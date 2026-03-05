import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _baseCurrency = 'DOP';
  bool _biometricEnabled = true;
  bool _notificationsEnabled = true;
  int _themeIndex = 2; // 0=Light, 1=Dark, 2=Auto

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ──
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accentBright],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('MC', style: TextStyle(
                        color: AppColors.background,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      )),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Miguel Cruz', style: AppTextStyles.headlineLarge),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.flag, size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Alcanzar \$1M para 2030',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined,
                      color: AppColors.textTertiary, size: 20),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // ── Currency ──
            Text('MONEDA', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _CurrencyOption(
                    label: 'DOP (RD\$)',
                    isSelected: _baseCurrency == 'DOP',
                    onTap: () => setState(() => _baseCurrency = 'DOP'),
                  ),
                  _CurrencyOption(
                    label: 'USD (\$)',
                    isSelected: _baseCurrency == 'USD',
                    onTap: () => setState(() => _baseCurrency = 'USD'),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 24),

            // ── Preferences ──
            Text('PREFERENCIAS', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsToggle(
                    icon: Icons.notifications_outlined,
                    label: 'Notificaciones',
                    subtitle: 'Alertas de variación y recordatorios',
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsToggle(
                    icon: Icons.fingerprint,
                    label: 'Face ID / Touch ID',
                    subtitle: 'Acceso biométrico',
                    value: _biometricEnabled,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 24),

            // ── Theme ──
            Text('TEMA', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode,
                    label: 'Claro',
                    isSelected: _themeIndex == 0,
                    onTap: () => setState(() => _themeIndex = 0),
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode,
                    label: 'Oscuro',
                    isSelected: _themeIndex == 1,
                    onTap: () => setState(() => _themeIndex = 1),
                  ),
                  _ThemeOption(
                    icon: Icons.brightness_auto,
                    label: 'Auto',
                    isSelected: _themeIndex == 2,
                    onTap: () => setState(() => _themeIndex = 2),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 24),

            // ── About ──
            Text('ACERCA DE', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsItem(
                    icon: Icons.info_outline,
                    label: 'Versión',
                    trailing: Text('1.0.0', style: AppTextStyles.bodySmall),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    label: 'Términos y condiciones',
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textTertiary, size: 20),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.shield_outlined,
                    label: 'Política de privacidad',
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textTertiary, size: 20),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Currency Option ─────────────────────────────

class _CurrencyOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Theme Option ────────────────────────────────

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 20,
                  color: isSelected ? AppColors.accent : AppColors.textTertiary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.accent : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings Toggle ─────────────────────────────

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// ── Settings Item ───────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTextStyles.labelLarge),
          ),
          trailing,
        ],
      ),
    );
  }
}
