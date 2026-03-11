import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Maps icon key strings (stored in DB) to LucideIcons IconData.
/// Used when deserializing categories and wallet accounts from the HTTP API.
IconData iconFromKey(String key) {
  final trimmed = key.trim();
  final normalized = _normalizeIconKey(trimmed);
  return _iconMap[trimmed] ??
      _normalizedIconMap[normalized] ??
      _fallbackIconFor(normalized) ??
      LucideIcons.tag;
}

/// Converts LucideIcons IconData to its string key for DB storage.
/// Since LucideIcons are static fields, we use the reverse lookup map.
String iconToKey(IconData icon) {
  return _iconMap.entries
      .firstWhere(
        (e) => e.value == icon,
        orElse: () => const MapEntry('circle', LucideIcons.circle),
      )
      .key;
}

final Map<String, IconData> _iconMap = {
  'home': LucideIcons.home,
  'utensils': LucideIcons.utensils,
  'car': LucideIcons.car,
  'sparkles': LucideIcons.sparkles,
  'pill': LucideIcons.pill,
  'bookOpen': LucideIcons.bookOpen,
  'music': LucideIcons.music,
  'shoppingCart': LucideIcons.shoppingCart,
  'tv': LucideIcons.tv,
  'wifi': LucideIcons.wifi,
  'zap': LucideIcons.zap,
  'phone': LucideIcons.phone,
  'heart': LucideIcons.heart,
  'plane': LucideIcons.plane,
  'creditCard': LucideIcons.creditCard,
  'landmark': LucideIcons.landmark,
  'banknote': LucideIcons.banknote,
  'piggyBank': LucideIcons.piggyBank,
  'shieldAlert': LucideIcons.shieldAlert,
  'wallet': LucideIcons.wallet,
  'arrowLeftRight': LucideIcons.arrowLeftRight,
  'trendingUp': LucideIcons.trendingUp,
  'trendingDown': LucideIcons.trendingDown,
  'dollarSign': LucideIcons.dollarSign,
  'tag': LucideIcons.tag,
  'gift': LucideIcons.gift,
  'graduationCap': LucideIcons.graduationCap,
  'dumbbell': LucideIcons.dumbbell,
  'scissors': LucideIcons.scissors,
  'bus': LucideIcons.bus,
  'fuel': LucideIcons.fuel,
  'wine': LucideIcons.wine,
  'monitor': LucideIcons.monitor,
  'monitorPlay': LucideIcons.monitorPlay,
  'wrench': LucideIcons.wrench,
  'fileText': LucideIcons.fileText,
  'briefcase': LucideIcons.briefcase,
  'briefcaseBusiness': LucideIcons.briefcase,
  'laptop': LucideIcons.laptop,
  'barChart2': LucideIcons.barChart2,
  'store': LucideIcons.store,
  'keySquare': LucideIcons.keySquare,
  'droplets': LucideIcons.droplets,
  'shield': LucideIcons.shield,
  'coffee': LucideIcons.coffee,
  'package': LucideIcons.package,
  'shirt': LucideIcons.shirt,
  'stethoscope': LucideIcons.stethoscope,
  'smile': LucideIcons.smile,
  'book': LucideIcons.book,
  'film': LucideIcons.film,
  'gamepad2': LucideIcons.gamepad2,
  'map': LucideIcons.map,
  'ticket': LucideIcons.ticket,
  'circle': LucideIcons.circle,
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
  'home': LucideIcons.home,
  'house': LucideIcons.home,
  'rent': LucideIcons.home,
  'salary': LucideIcons.briefcase,
  'briefcase': LucideIcons.briefcase,
  'freelance': LucideIcons.laptop,
  'business': LucideIcons.store,
  'store': LucideIcons.store,
  'food': LucideIcons.utensils,
  'restaurant': LucideIcons.utensils,
  'grocery': LucideIcons.shoppingCart,
  'shopping': LucideIcons.shoppingCart,
  'transport': LucideIcons.car,
  'fuel': LucideIcons.fuel,
  'internet': LucideIcons.wifi,
  'phone': LucideIcons.phone,
  'water': LucideIcons.droplets,
  'light': LucideIcons.zap,
  'electric': LucideIcons.zap,
  'health': LucideIcons.heart,
  'medical': LucideIcons.stethoscope,
  'education': LucideIcons.graduationCap,
  'movie': LucideIcons.film,
  'game': LucideIcons.gamepad2,
  'gift': LucideIcons.gift,
};
