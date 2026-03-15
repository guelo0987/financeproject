import 'package:flutter/material.dart';

class MenudoLogo extends StatelessWidget {
  const MenudoLogo({
    super.key,
    this.size = 88,
    this.hero = false,
    this.fit = BoxFit.contain,
  });

  static const heroTag = 'app_logo';
  static const _assetPath = 'assets/images/Menudo_Logotipo.png';

  final double size;
  final bool hero;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
    );

    if (!hero) return image;
    return Hero(tag: heroTag, child: image);
  }
}
