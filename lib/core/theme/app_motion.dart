import 'package:flutter/animation.dart';

/// Centralised motion tokens for Menudo following Apple's HIG spring standards.
///
/// Apple's default interactive spring:
///   mass 1, stiffness 100, damping 20  →  approximated by `Curves.easeOutCubic`
///
/// For **overshooting** transitions (tab switches, hero entries) use [springBack].
/// For **smooth settling** transitions (slides, fades) use [spring].
abstract class MenudoMotion {
  // ── Curves ──────────────────────────────────────────────────
  /// Standard spring curve — smooth, natural deceleration.
  /// Maps to Apple's default UISpring behaviour without overshoot.
  static const Curve spring = Curves.easeOutCubic;

  /// Spring with slight overshoot — use for elements that "bounce in".
  static const Curve springBack = Curves.easeOutBack;

  /// Quick ease for micro-interactions (e.g. opacity toggles).
  static const Curve quick = Curves.easeOut;

  // ── Durations ───────────────────────────────────────────────
  /// Ultra-fast for colour/opacity transitions (100ms).
  static const Duration micro = Duration(milliseconds: 100);

  /// Default interactive transition (220ms).
  static const Duration standard = Duration(milliseconds: 220);

  /// Slide-in / expand transitions (320ms).
  static const Duration medium = Duration(milliseconds: 320);

  /// Full-screen transitions (420ms).
  static const Duration slow = Duration(milliseconds: 420);
}
