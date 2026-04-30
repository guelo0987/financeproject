import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Builds an [AppBar.flexibleSpace] with a frosted-glass backdrop blur.
///
/// Usage:
/// ```dart
/// AppBar(
///   backgroundColor: Colors.transparent,
///   flexibleSpace: const MenudoBlurredBar(),
///   ...
/// )
/// ```
class MenudoBlurredBar extends StatelessWidget {
  const MenudoBlurredBar({super.key, this.sigma = 15});

  /// Gaussian blur radius. Apple standard ≈ 10–20.
  final double sigma;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          color: colors.navBar,
        ),
      ),
    );
  }
}
