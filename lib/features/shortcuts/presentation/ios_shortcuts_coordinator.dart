import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/auth_state.dart';
import '../../../features/categories/providers/category_providers.dart';
import '../../../features/transactions/providers/transaction_providers.dart';
import '../../../features/wallet/providers/wallet_providers.dart';
import '../../../model/models.dart';
import '../../../utils/app_env.dart';
import '../data/ios_shortcuts_bridge.dart';

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
  String? _lastShortcutContextSignature;
  bool _syncScheduled = false;

  bool get _supportsShortcuts =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (!_supportsShortcuts) return;
    WidgetsBinding.instance.addObserver(this);
    final bridge = ref.read(iosShortcutsBridgeProvider);
    bridge.setShortcutHandler((_) async {
      await bridge.clearPendingShortcut();
      await bridge.flushQueuedQuickExpenses();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iosShortcutsBridgeProvider).clearPendingShortcut();
      _scheduleShortcutContextSync();
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
      _scheduleShortcutContextSync();
    }
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
    final transactions = ref.read(effectiveTransactionsProvider);

    if (wallet == null || categories.isEmpty) {
      _lastShortcutContextSignature = null;
      await bridge.clearQuickExpenseContext();
      return;
    }

    final frequentCategories = _frequentCategories(categories, transactions);
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
      'frequentCategories': frequentCategories
          .map(
            (item) => <String, dynamic>{
              'slug': item.slug,
              'name': item.nombre,
              'icon': item.toJson()['icono'],
            },
          )
          .toList(growable: false),
      'merchantHints': _merchantHints(categories, transactions),
    };

    final signature = jsonEncode(payload);
    if (signature == _lastShortcutContextSignature) return;

    await bridge.syncQuickExpenseContext(payload);
    await bridge.flushQueuedQuickExpenses();
    _lastShortcutContextSignature = signature;
  }

  void _scheduleShortcutContextSync() {
    if (!_supportsShortcuts || _syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _syncScheduled = false;
      await _syncShortcutContext();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      _scheduleShortcutContextSync();
    });
    ref.listen(
      defaultWalletProvider,
      (previous, next) => _scheduleShortcutContextSync(),
    );
    ref.listen(
      effectiveCategoriesProvider,
      (previous, next) => _scheduleShortcutContextSync(),
    );
    ref.listen(
      effectiveTransactionsProvider,
      (previous, next) => _scheduleShortcutContextSync(),
    );
    return widget.child;
  }

  List<MenudoCategory> _frequentCategories(
    List<MenudoCategory> categories,
    List<MenudoTransaction> transactions,
  ) {
    final counts = <String, int>{};
    for (final transaction in transactions) {
      if (transaction.tipo != 'gasto' || transaction.catKey.trim().isEmpty) {
        continue;
      }
      counts.update(
        transaction.catKey,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final sorted = [...categories];
    sorted.sort((a, b) {
      final byCount = (counts[b.slug] ?? 0).compareTo(counts[a.slug] ?? 0);
      if (byCount != 0) return byCount;
      return a.nombre.compareTo(b.nombre);
    });
    return sorted.take(5).toList(growable: false);
  }

  List<Map<String, dynamic>> _merchantHints(
    List<MenudoCategory> categories,
    List<MenudoTransaction> transactions,
  ) {
    final categoriesBySlug = {for (final item in categories) item.slug: item};
    final merchantCounts = <String, Map<String, int>>{};
    final merchantNames = <String, String>{};

    for (final transaction in transactions) {
      if (transaction.tipo != 'gasto' || transaction.catKey.trim().isEmpty) {
        continue;
      }
      if (!categoriesBySlug.containsKey(transaction.catKey)) continue;

      final merchantName = _merchantNameFrom(transaction);
      final merchantKey = _normalizeMerchantKey(merchantName);
      if (merchantKey.length < 3) continue;

      merchantNames.putIfAbsent(merchantKey, () => merchantName);
      final categoryCounts = merchantCounts.putIfAbsent(
        merchantKey,
        () => <String, int>{},
      );
      categoryCounts.update(
        transaction.catKey,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final hints = <Map<String, dynamic>>[];
    for (final entry in merchantCounts.entries) {
      final total = entry.value.values.fold<int>(0, (sum, item) => sum + item);
      if (total <= 0) continue;

      final topCategory = entry.value.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final category = categoriesBySlug[topCategory.first.key];
      if (category == null) continue;

      hints.add({
        'merchantKey': entry.key,
        'merchantName': merchantNames[entry.key] ?? entry.key,
        'categorySlug': category.slug,
        'categoryName': category.nombre,
        'confidence': topCategory.first.value / total,
        'count': topCategory.first.value,
      });
    }

    hints.sort((a, b) {
      final byCount = (b['count'] as int).compareTo(a['count'] as int);
      if (byCount != 0) return byCount;
      return (b['confidence'] as double).compareTo(a['confidence'] as double);
    });

    return hints.take(80).toList(growable: false);
  }

  String _merchantNameFrom(MenudoTransaction transaction) {
    final note = transaction.nota?.trim();
    if (note != null && note.isNotEmpty && note.length <= 80) {
      return note;
    }
    return transaction.desc.trim();
  }

  String _normalizeMerchantKey(String raw) {
    final normalized = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized;
  }
}
