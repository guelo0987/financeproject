import 'package:flutter/material.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

/// Maps icon key strings (stored in DB) to Cupertino IconData.
/// Used when deserializing categories and wallet accounts from the HTTP API.
IconData iconFromKey(String key) {
  final trimmed = key.trim();
  final normalized = _normalizeIconKey(trimmed);
  return _iconMap[trimmed] ??
      _normalizedIconMap[normalized] ??
      _fallbackIconFor(normalized) ??
      MenudoCupertinoIcons.tag;
}

/// Converts Cupertino IconData to its string key for DB storage.
/// Since the semantic icon constants are static fields, we use the reverse lookup map.
String iconToKey(IconData icon) {
  return _iconMap.entries
      .firstWhere(
        (e) => e.value == icon,
        orElse: () => const MapEntry('circle', MenudoCupertinoIcons.circle),
      )
      .key;
}

final Map<String, IconData> _iconMap = {
  'home': MenudoCupertinoIcons.home,
  'utensils': MenudoCupertinoIcons.utensils,
  'car': MenudoCupertinoIcons.car,
  'sparkles': MenudoCupertinoIcons.sparkles,
  'pill': MenudoCupertinoIcons.pill,
  'bookOpen': MenudoCupertinoIcons.bookOpen,
  'music': MenudoCupertinoIcons.music,
  'shoppingCart': MenudoCupertinoIcons.shoppingCart,
  'tv': MenudoCupertinoIcons.tv,
  'wifi': MenudoCupertinoIcons.wifi,
  'zap': MenudoCupertinoIcons.zap,
  'phone': MenudoCupertinoIcons.phone,
  'heart': MenudoCupertinoIcons.heart,
  'plane': MenudoCupertinoIcons.plane,
  'creditCard': MenudoCupertinoIcons.creditCard,
  'landmark': MenudoCupertinoIcons.landmark,
  'banknote': MenudoCupertinoIcons.banknote,
  'piggyBank': MenudoCupertinoIcons.piggyBank,
  'shieldAlert': MenudoCupertinoIcons.shieldAlert,
  'wallet': MenudoCupertinoIcons.wallet,
  'arrowLeftRight': MenudoCupertinoIcons.arrowLeftRight,
  'trendingUp': MenudoCupertinoIcons.trendingUp,
  'trendingDown': MenudoCupertinoIcons.trendingDown,
  'dollarSign': MenudoCupertinoIcons.dollarSign,
  'tag': MenudoCupertinoIcons.tag,
  'gift': MenudoCupertinoIcons.gift,
  'graduationCap': MenudoCupertinoIcons.graduationCap,
  'dumbbell': MenudoCupertinoIcons.dumbbell,
  'scissors': MenudoCupertinoIcons.scissors,
  'bus': MenudoCupertinoIcons.bus,
  'fuel': MenudoCupertinoIcons.fuel,
  'wine': MenudoCupertinoIcons.wine,
  'monitor': MenudoCupertinoIcons.monitor,
  'monitorPlay': MenudoCupertinoIcons.monitorPlay,
  'wrench': MenudoCupertinoIcons.wrench,
  'fileText': MenudoCupertinoIcons.fileText,
  'briefcase': MenudoCupertinoIcons.briefcase,
  'briefcaseBusiness': MenudoCupertinoIcons.briefcase,
  'laptop': MenudoCupertinoIcons.laptop,
  'barChart2': MenudoCupertinoIcons.barChart2,
  'store': MenudoCupertinoIcons.store,
  'keySquare': MenudoCupertinoIcons.keySquare,
  'droplets': MenudoCupertinoIcons.droplets,
  'shield': MenudoCupertinoIcons.shield,
  'coffee': MenudoCupertinoIcons.coffee,
  'package': MenudoCupertinoIcons.package,
  'shirt': MenudoCupertinoIcons.shirt,
  'stethoscope': MenudoCupertinoIcons.stethoscope,
  'smile': MenudoCupertinoIcons.smile,
  'book': MenudoCupertinoIcons.book,
  'film': MenudoCupertinoIcons.film,
  'gamepad2': MenudoCupertinoIcons.gamepad2,
  'map': MenudoCupertinoIcons.map,
  'ticket': MenudoCupertinoIcons.ticket,
  'circle': MenudoCupertinoIcons.circle,
};

final Map<String, IconData> _normalizedIconMap = {
  for (final entry in _iconMap.entries)
    _normalizeIconKey(entry.key): entry.value,
};

String _normalizeIconKey(String key) {
  return key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
}

IconData? _fallbackIconFor(String normalizedKey) {
  for (final entry in _iconFallbacks.entries) {
    if (normalizedKey.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}

final Map<String, IconData> _iconFallbacks = {
  'home': MenudoCupertinoIcons.home,
  'house': MenudoCupertinoIcons.home,
  'rent': MenudoCupertinoIcons.home,
  'salary': MenudoCupertinoIcons.briefcase,
  'briefcase': MenudoCupertinoIcons.briefcase,
  'freelance': MenudoCupertinoIcons.laptop,
  'business': MenudoCupertinoIcons.store,
  'store': MenudoCupertinoIcons.store,
  'food': MenudoCupertinoIcons.utensils,
  'restaurant': MenudoCupertinoIcons.utensils,
  'grocery': MenudoCupertinoIcons.shoppingCart,
  'shopping': MenudoCupertinoIcons.shoppingCart,
  'transport': MenudoCupertinoIcons.car,
  'fuel': MenudoCupertinoIcons.fuel,
  'internet': MenudoCupertinoIcons.wifi,
  'phone': MenudoCupertinoIcons.phone,
  'water': MenudoCupertinoIcons.droplets,
  'light': MenudoCupertinoIcons.zap,
  'electric': MenudoCupertinoIcons.zap,
  'health': MenudoCupertinoIcons.heart,
  'medical': MenudoCupertinoIcons.stethoscope,
  'education': MenudoCupertinoIcons.graduationCap,
  'movie': MenudoCupertinoIcons.film,
  'game': MenudoCupertinoIcons.gamepad2,
  'gift': MenudoCupertinoIcons.gift,
};
