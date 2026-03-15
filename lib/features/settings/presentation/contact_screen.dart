import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../auth/auth_state.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  static const _supportEmail = 'notificaciones@bot.dlcsoft.dev';

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
    Clipboard.setData(const ClipboardData(text: _supportEmail));
    _showMessage('Correo copiado.');
  }

  void _copyMessage() {
    final profile = ref.read(authProvider).profile;
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      _showMessage('Escribe un asunto y un mensaje.');
      return;
    }

    final formatted =
        '''
Tipo: $_topic
Asunto: $title
Cuenta: ${profile?.email ?? 'Sin correo'}
Nombre: ${profile?.name ?? 'Sin nombre'}

Detalle:
$message
''';

    Clipboard.setData(ClipboardData(text: formatted.trim()));
    _showMessage('Mensaje copiado. Ya puedes enviarlo.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;

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
                    Text('Contacto', style: MenudoTextStyles.h1),
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
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [AppColors.e8, AppColors.e6],
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
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cuéntanos cómo va tu experiencia.',
                        style: MenudoTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Puedes reportar un bug, pedir una mejora o escribirnos una idea.',
                        style: MenudoTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _SectionTitle('Qué quieres enviar'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _TopicCard(
                        label: 'Bug',
                        subtitle: 'Algo no salió bien',
                        icon: Icons.bug_report_outlined,
                        selected: _topic == 'Bug',
                        onTap: () => setState(() => _topic = 'Bug'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TopicCard(
                        label: 'Mejora',
                        subtitle: 'Una idea útil',
                        icon: Icons.auto_awesome_outlined,
                        selected: _topic == 'Mejora',
                        onTap: () => setState(() => _topic = 'Mejora'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TopicCard(
                        label: 'Ayuda',
                        subtitle: 'Necesito apoyo',
                        icon: Icons.favorite_border_rounded,
                        selected: _topic == 'Ayuda',
                        onTap: () => setState(() => _topic = 'Ayuda'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _SectionTitle('Tu mensaje'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: MenudoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContactField(
                        controller: _titleController,
                        label: 'Asunto',
                        hintText: 'Cuéntanos en una línea',
                      ),
                      const SizedBox(height: 16),
                      _ContactField(
                        controller: _messageController,
                        label: 'Detalle',
                        hintText: 'Describe qué pasó o qué te gustaría mejorar',
                        maxLines: 6,
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Se añadirá tu correo: ${profile.email}',
                          style: MenudoTextStyles.bodySmall.copyWith(
                            color: MenudoColors.textMuted,
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
                child: _SectionTitle('Correo de contacto'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: MenudoCard(
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
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          color: AppColors.o5,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _supportEmail,
                              style: MenudoTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Copia el mensaje y envíalo a este correo.',
                              style: MenudoTextStyles.bodySmall.copyWith(
                                color: MenudoColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _copyEmail,
                        child: const Text('Copiar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Row(
                  children: [
                    Expanded(
                      child: MenudoSecondaryButton(
                        label: 'Copiar correo',
                        onTap: _copyEmail,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MenudoButton(
                        label: 'Copiar mensaje',
                        isFullWidth: true,
                        onTap: _copyMessage,
                      ),
                    ),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.o1 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.o5 : AppColors.g2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.o5 : AppColors.e8),
            const SizedBox(height: 12),
            Text(
              label,
              style: MenudoTextStyles.bodyMedium.copyWith(
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
        const SizedBox(height: 8),
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
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MenudoColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MenudoColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
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
