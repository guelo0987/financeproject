import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/external_links.dart';
import '../../../core/utils/menudo_haptics.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_toast.dart';
import '../../../utils/app_env.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  void _copyEmail() {
    Clipboard.setData(ClipboardData(text: AppEnv.feedbackEmail));
    MenudoHaptics.success();
    MenudoToast.success(context, title: 'Correo copiado');
  }

  void _openEmail() {
    ExternalLinks.openUrlOrNotify(context, 'mailto:${AppEnv.feedbackEmail}');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: context.menudo.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
          children: [
            Row(
              children: [
                _CircleActionButton(
                  icon: MenudoCupertinoIcons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                ),
                SizedBox(width: (14)),
                Text('Contacto', style: MenudoTextStyles.h1),
              ],
            ),
            SizedBox(height: (20)),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [context.menudo.hero, context.menudo.heroElevated],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      MenudoCupertinoIcons.chat_bubble_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: (16)),
                  Text(
                    'Estamos aquí para ayudarte.',
                    style: MenudoTextStyles.h2.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Escríbenos si tienes dudas, encontraste un problema o tienes una sugerencia de mejora.',
                    style: MenudoTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: (32)),
            const _SectionTitle('Correo de contacto'),
            MenudoCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.menudo.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      MenudoCupertinoIcons.mail_outline_rounded,
                      color: AppColors.o5,
                    ),
                  ),
                  SizedBox(width: (14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppEnv.feedbackEmail,
                          style: MenudoTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nuestro equipo te responderá pronto.',
                          style: MenudoTextStyles.bodySmall.copyWith(
                            color: context.menudo.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _copyEmail, child: Text('Copiar')),
                ],
              ),
            ),
            SizedBox(height: (32)),
            MenudoButton(
              label: 'Escribir correo',
              icon: MenudoCupertinoIcons.mail_outline_rounded,
              isFullWidth: true,
              onTap: _openEmail,
            ),
            SizedBox(height: (12)),
            MenudoSecondaryButton(
              label: 'Abrir ayuda',
              onTap: () =>
                  ExternalLinks.openUrlOrNotify(context, AppEnv.supportUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

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

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.menudo.surface,
          shape: BoxShape.circle,
          border: Border.all(color: context.menudo.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: (18), color: context.menudo.textMain),
      ),
    );
  }
}
