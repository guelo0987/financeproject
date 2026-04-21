import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_env.dart';

class ExternalLinks {
  static Future<bool> openUrl(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  static Future<bool> composeSupportEmail({String? subject}) {
    final email = AppEnv.supportEmail;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null && subject.trim().isNotEmpty) 'subject': subject,
      },
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openUrlOrNotify(
    BuildContext context,
    String url, {
    String? fallbackMessage,
  }) async {
    final launched = await openUrl(url);
    if (launched || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fallbackMessage ??
              'No pudimos abrir ese enlace ahora mismo. Inténtalo otra vez.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> composeSupportOrNotify(
    BuildContext context, {
    String? subject,
  }) async {
    final launched = await composeSupportEmail(subject: subject);
    if (launched || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No pudimos abrir tu app de correo. Copia el email de soporte e inténtalo desde allí.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
