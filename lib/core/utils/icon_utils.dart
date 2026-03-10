import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Maps icon key strings (stored in DB) to LucideIcons IconData.
/// Used when deserializing categories and wallet accounts from the HTTP API.
IconData iconFromKey(String key) {
  return _iconMap[key] ?? LucideIcons.circle;
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
  'fileText': LucideIcons.fileText,
  'circle': LucideIcons.circle,
};
