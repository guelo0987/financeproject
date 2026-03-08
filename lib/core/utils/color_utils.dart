import 'package:flutter/material.dart';

/// Converts a hex string like '#4F46E5' or '4F46E5' to a Flutter Color.
Color colorFromHex(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  } else if (h.length == 8) {
    return Color(int.parse(h, radix: 16));
  }
  return const Color(0xFF4F46E5); // fallback
}

/// Converts a Flutter Color to a hex string like '#4F46E5'.
String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
