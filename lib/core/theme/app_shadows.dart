import 'package:flutter/material.dart';

abstract class MenudoShadows {
  // Primary button shadow (orange glow)
  static const BoxShadow primaryShadow = BoxShadow(
    color: Color(0x40F97316),
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  // Card shadow
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 24,
    offset: Offset(0, 4),
  );

  // Hero card inner shadow — subtle depth
  static const BoxShadow heroShadow = BoxShadow(
    color: Color(0x30000000),
    blurRadius: 40,
    offset: Offset(0, 12),
  );
}
