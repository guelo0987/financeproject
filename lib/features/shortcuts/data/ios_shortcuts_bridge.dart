import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MenudoShortcutAction { quickExpense }

class MenudoShortcutPayload {
  final MenudoShortcutAction action;
  final String source;
  final DateTime? createdAt;

  const MenudoShortcutPayload({
    required this.action,
    required this.source,
    this.createdAt,
  });

  factory MenudoShortcutPayload.fromMap(Map<dynamic, dynamic> raw) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final action = switch (map['action']) {
      'quick_expense' => MenudoShortcutAction.quickExpense,
      _ => MenudoShortcutAction.quickExpense,
    };

    return MenudoShortcutPayload(
      action: action,
      source: map['source']?.toString() ?? 'shortcut',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }
}

class IosShortcutsBridge {
  IosShortcutsBridge();

  static const MethodChannel _channel = MethodChannel('menudo/shortcuts');

  Future<void> presentShortcutSetup() async {
    if (!_supportsShortcuts) return;
    await _channel.invokeMethod<void>('presentShortcutSetup');
  }

  Future<MenudoShortcutPayload?> consumePendingShortcut() async {
    if (!_supportsShortcuts) return null;
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>?>(
      'consumePendingShortcut',
    );
    if (raw == null) return null;
    return MenudoShortcutPayload.fromMap(raw);
  }

  Future<void> clearPendingShortcut() async {
    if (!_supportsShortcuts) return;
    await _channel.invokeMethod<void>('clearPendingShortcut');
  }

  Future<void> syncQuickExpenseContext(Map<String, dynamic> payload) async {
    if (!_supportsShortcuts) return;
    await _channel.invokeMethod<void>('syncQuickExpenseContext', payload);
  }

  Future<void> clearQuickExpenseContext() async {
    if (!_supportsShortcuts) return;
    await _channel.invokeMethod<void>('clearQuickExpenseContext');
  }

  Future<void> flushQueuedQuickExpenses() async {
    if (!_supportsShortcuts) return;
    await _channel.invokeMethod<void>('flushQueuedQuickExpenses');
  }

  void setShortcutHandler(
    FutureOr<void> Function(MenudoShortcutPayload payload)? handler,
  ) {
    if (!_supportsShortcuts) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'shortcutTriggered' || handler == null) {
        return null;
      }
      final args = call.arguments;
      if (args is! Map) return null;
      await handler(MenudoShortcutPayload.fromMap(args));
      return null;
    });
  }

  bool get _supportsShortcuts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

final iosShortcutsBridgeProvider = Provider<IosShortcutsBridge>(
  (_) => IosShortcutsBridge(),
);
