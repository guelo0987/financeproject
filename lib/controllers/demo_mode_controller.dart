import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/storage_keys.dart';

class DemoModeController extends StateNotifier<bool> {
  DemoModeController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      super(false) {
    _restore();
  }

  final FlutterSecureStorage _storage;

  Future<void> _restore() async {
    final raw = await _storage.read(key: StorageKeys.demoMode);
    state = raw == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _storage.write(key: StorageKeys.demoMode, value: '$enabled');
  }
}

final demoModeProvider =
    StateNotifierProvider<DemoModeController, bool>((ref) {
      return DemoModeController();
    });
