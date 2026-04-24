import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/auth_state.dart';
import '../../../features/categories/providers/category_providers.dart';
import '../../../features/wallet/providers/wallet_providers.dart';
import '../../../utils/app_env.dart';
import '../data/ios_shortcuts_bridge.dart';
import 'quick_expense_shortcut_sheet.dart';

class IosShortcutsCoordinator extends ConsumerStatefulWidget {
  final Widget child;

  const IosShortcutsCoordinator({super.key, required this.child});

  @override
  ConsumerState<IosShortcutsCoordinator> createState() =>
      _IosShortcutsCoordinatorState();
}

class _IosShortcutsCoordinatorState
    extends ConsumerState<IosShortcutsCoordinator>
    with WidgetsBindingObserver {
  MenudoShortcutPayload? _pendingPayload;
  bool _isPresenting = false;
  BuildContext? _navigatorContext;
  String? _lastShortcutContextSignature;

  bool get _supportsShortcuts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_supportsShortcuts) return;
    WidgetsBinding.instance.addObserver(this);
    final bridge = ref.read(iosShortcutsBridgeProvider);
    bridge.setShortcutHandler((payload) async {
      _pendingPayload = payload;
      _maybePresentPendingShortcut();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restorePendingShortcut();
    });
  }

  @override
  void dispose() {
    if (_supportsShortcuts) {
      WidgetsBinding.instance.removeObserver(this);
      ref.read(iosShortcutsBridgeProvider).setShortcutHandler(null);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restorePendingShortcut();
    }
  }

  Future<void> _restorePendingShortcut() async {
    if (!_supportsShortcuts) return;
    final payload = await ref
        .read(iosShortcutsBridgeProvider)
        .consumePendingShortcut();
    if (!mounted || payload == null) return;
    _pendingPayload = payload;
    _maybePresentPendingShortcut();
  }

  Future<void> _syncShortcutContext() async {
    if (!_supportsShortcuts || !mounted) return;

    final bridge = ref.read(iosShortcutsBridgeProvider);
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.token == null || auth.token!.isEmpty) {
      _lastShortcutContextSignature = null;
      await bridge.clearQuickExpenseContext();
      return;
    }

    final wallet = ref.read(defaultWalletProvider);
    final categories = ref
        .read(effectiveCategoriesProvider)
        .where((item) => item.tipo == 'gasto' && !item.esParent)
        .toList(growable: false);

    if (wallet == null || categories.isEmpty) {
      _lastShortcutContextSignature = null;
      await bridge.clearQuickExpenseContext();
      return;
    }

    final payload = <String, dynamic>{
      'apiBaseUrl': AppEnv.apiBaseUrl,
      'authToken': auth.token,
      'defaultWallet': <String, dynamic>{
        'id': wallet.id,
        'name': wallet.nombre,
        'currency': wallet.moneda,
      },
      'categories': categories
          .map(
            (item) => <String, dynamic>{
              'slug': item.slug,
              'name': item.nombre,
              'icon': item.toJson()['icono'],
            },
          )
          .toList(growable: false),
    };

    final signature = jsonEncode(payload);
    if (signature == _lastShortcutContextSignature) return;

    await bridge.syncQuickExpenseContext(payload);
    _lastShortcutContextSignature = signature;
  }

  void _maybePresentPendingShortcut() {
    if (!mounted || _pendingPayload == null || _isPresenting) return;
    final navigatorContext = _navigatorContext;
    if (navigatorContext == null ||
        Navigator.maybeOf(navigatorContext) == null) {
      return;
    }

    final auth = ref.read(authProvider);
    final canUseApp = auth.isAuthenticated && !auth.isBootstrapping;

    if (!canUseApp) return;

    final payload = _pendingPayload!;
    _pendingPayload = null;
    _isPresenting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showModalBottomSheet<bool>(
        context: navigatorContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => QuickExpenseShortcutSheet(source: payload.source),
      );
      if (!mounted) return;
      _isPresenting = false;
      _restorePendingShortcut();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    ref.watch(defaultWalletProvider);
    ref.watch(effectiveCategoriesProvider);
    ref.listen(
      authProvider,
      (previous, next) => _maybePresentPendingShortcut(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncShortcutContext();
    });
    return Builder(
      builder: (navigatorContext) {
        _navigatorContext = navigatorContext;
        return widget.child;
      },
    );
  }
}
