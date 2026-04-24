import 'package:flutter/material.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/external_links.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../utils/app_env.dart';
import '../../auth/auth_state.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _topic = 'Bug';

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _copyEmail() {
    Clipboard.setData(ClipboardData(text: AppEnv.feedbackEmail));
    _showMessage('Listo. El correo ya está copiado.');
  }

  void _copyDraft() {
    final formatted = _buildMessageBody();
    if (formatted == null) {
      _showMessage('Escribe un asunto y cuéntanos qué pasó.');
      return;
    }

    final subject = _titleController.text.trim().isEmpty
        ? 'Mensaje desde Menudo'
        : '[${_topic.toUpperCase()}] ${_titleController.text.trim()}';

    final draft = [
      'Para: ${AppEnv.feedbackEmail}',
      'Asunto: $subject',
      '',
      formatted,
    ].join('\n');

    Clipboard.setData(ClipboardData(text: draft));
    _showMessage(
      'Listo. Copiamos tu mensaje. Envíalo a ${AppEnv.feedbackEmail}.',
    );
  }

  String? _buildMessageBody() {
    final profile = ref.read(authProvider).profile;
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      return null;
    }

    final details = <String>[
      if (profile?.email.trim().isNotEmpty == true) 'Cuenta: ${profile!.email}',
      if (profile?.name.trim().isNotEmpty == true) 'Nombre: ${profile!.name}',
      '',
      'Detalle:',
      message,
    ];

    final formatted =
        '''
Tipo: $_topic
Asunto: $title
${details.join('\n')}
''';

    return formatted.trim();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: MenudoColors.appBg,
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
                      color: context.menudo.textOnDark.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      MenudoCupertinoIcons.chat_bubble_outline_rounded,
                      color: context.menudo.textOnDark,
                    ),
                  ),
                  SizedBox(height: (16)),
                  Text(
                    'Cuéntanos qué podemos mejorar.',
                    style: MenudoTextStyles.h2.copyWith(
                      color: context.menudo.textOnDark,
                      fontSize: 26,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Escribe tu mensaje, copia el borrador y envíalo al correo indicado.',
                    style: MenudoTextStyles.bodyMedium.copyWith(
                      color: context.menudo.textOnDark.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: (20)),
            const _SectionTitle('Qué quieres contarnos'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TopicCard(
                    label: 'Bug',
                    subtitle: 'Algo no salió bien',
                    icon: MenudoCupertinoIcons.bug_report_outlined,
                    selected: _topic == 'Bug',
                    onTap: () => setState(() => _topic = 'Bug'),
                  ),
                ),
                SizedBox(width: (12)),
                Expanded(
                  child: _TopicCard(
                    label: 'Mejora',
                    subtitle: 'Una idea útil',
                    icon: MenudoCupertinoIcons.auto_awesome_outlined,
                    selected: _topic == 'Mejora',
                    onTap: () => setState(() => _topic = 'Mejora'),
                  ),
                ),
                SizedBox(width: (12)),
                Expanded(
                  child: _TopicCard(
                    label: 'Ayuda',
                    subtitle: 'Necesito apoyo',
                    icon: MenudoCupertinoIcons.favorite_border_rounded,
                    selected: _topic == 'Ayuda',
                    onTap: () => setState(() => _topic = 'Ayuda'),
                  ),
                ),
              ],
            ),
            SizedBox(height: (20)),
            const _SectionTitle('Tu mensaje'),
            MenudoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactField(
                    controller: _titleController,
                    label: 'Asunto',
                    hintText: 'Cuéntanos en una línea',
                  ),
                  SizedBox(height: (16)),
                  _ContactField(
                    controller: _messageController,
                    label: 'Detalle',
                    hintText: 'Describe qué pasó o qué te gustaría mejorar',
                    maxLines: 6,
                  ),
                  if (profile != null) ...[
                    SizedBox(height: (16)),
                    Text(
                      'Añadiremos tu correo para que podamos responderte mejor.',
                      style: MenudoTextStyles.bodySmall.copyWith(
                        color: MenudoColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: (20)),
            const _SectionTitle('Correo de contacto'),
            MenudoCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.o1,
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
                          'Si lo prefieres, también puedes escribirnos directo aquí.',
                          style: MenudoTextStyles.bodySmall.copyWith(
                            color: MenudoColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _copyEmail, child: Text('Copiar')),
                ],
              ),
            ),
            SizedBox(height: (20)),
            Row(
              children: [
                Expanded(
                  child: MenudoSecondaryButton(
                    label: 'Abrir ayuda',
                    onTap: () => ExternalLinks.openUrlOrNotify(
                      context,
                      AppEnv.supportUrl,
                    ),
                  ),
                ),
                SizedBox(width: (12)),
                Expanded(
                  child: MenudoButton(
                    label: 'Copiar mensaje',
                    isFullWidth: true,
                    onTap: _copyDraft,
                  ),
                ),
              ],
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
          color: MenudoColors.textMuted,
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenudoGestureDetector(
      onTap: () {
        MenudoHaptics.selection();
        onTap();
      },
      child: SizedBox(
        height: (124),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.o1 : context.menudo.textOnDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.o5 : context.menudo.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.o5 : context.menudo.textMain,
              ),
              SizedBox(height: (12)),
              Text(
                label,
                style: MenudoTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: MenudoTextStyles.bodySmall.copyWith(
                  color: MenudoColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MenudoTextStyles.labelCaps),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: MenudoTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: MenudoTextStyles.bodyLarge.copyWith(
              color: MenudoColors.textMuted,
            ),
            filled: true,
            fillColor: context.menudo.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: MenudoColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: MenudoColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: MenudoColors.borderActive,
                width: 2,
              ),
            ),
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
    return MenudoGestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.menudo.textOnDark,
          shape: BoxShape.circle,
          border: Border.all(color: MenudoColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: (18), color: MenudoColors.textMain),
      ),
    );
  }
}
