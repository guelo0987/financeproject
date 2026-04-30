import 'package:flutter/cupertino.dart';

/// A Cupertino-native destructive confirmation dialog.
///
/// Use this for any action that permanently removes data (delete, leave, etc.).
/// The dialog follows Apple HIG with a native look and a prominent red
/// destructive button.
class MenudoDestructiveDialog {
  MenudoDestructiveDialog._();

  /// Shows a native iOS-style destructive confirmation dialog.
  ///
  /// Returns `true` when the user confirms, `false` or `null` otherwise.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String cancelLabel = 'Cancelar',
    String confirmLabel = 'Eliminar',
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ],
      ),
    );
  }
}
