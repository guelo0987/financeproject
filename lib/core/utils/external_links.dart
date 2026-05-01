import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_env.dart';
import '../../shared/widgets/menudo_toast.dart';

class ExternalLinks {
  static Future<bool> openUrl(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  static Future<bool> composeEmail({
    required String email,
    String? subject,
    String? body,
  }) {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null && subject.trim().isNotEmpty) 'subject': subject,
        if (body != null && body.trim().isNotEmpty) 'body': body,
      },
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> composeSupportEmail({String? subject, String? body}) {
    return composeEmail(
      email: AppEnv.supportEmail,
      subject: subject,
      body: body,
    );
  }

  static Future<void> openUrlOrNotify(
    BuildContext context,
    String url, {
    String? fallbackMessage,
  }) async {
    final launched = await openUrl(url);
    if (launched || !context.mounted) return;

    MenudoToast.error(
      context,
      title: 'No se pudo abrir',
      message: fallbackMessage ?? 'Inténtalo otra vez en un momento.',
    );
  }

  static Future<void> composeSupportOrNotify(
    BuildContext context, {
    String? recipient,
    String? subject,
    String? body,
  }) async {
    final resolvedRecipient = recipient?.trim().isNotEmpty == true
        ? recipient!.trim()
        : AppEnv.supportEmail;
    final launched = await composeEmail(
      email: resolvedRecipient,
      subject: subject,
      body: body,
    );
    if (launched || !context.mounted) return;

    final fallbackParts = <String>[
      'Para: $resolvedRecipient',
      if (subject != null && subject.trim().isNotEmpty) 'Asunto: $subject',
      if (body != null && body.trim().isNotEmpty) '',
      if (body != null && body.trim().isNotEmpty) body.trim(),
    ];
    await Clipboard.setData(ClipboardData(text: fallbackParts.join('\n')));
    if (!context.mounted) return;

    MenudoToast.show(
      context,
      title: 'Mensaje copiado',
      message: 'Abre tu correo y pégalo manualmente.',
      tone: MenudoToastTone.info,
    );
  }
}
