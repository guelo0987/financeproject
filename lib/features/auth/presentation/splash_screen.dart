import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: MenudoColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 10,
                        bottom: 10,
                        right: -10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: MenudoColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text(
              'Menudo',
              style: MenudoTextStyles.h1.copyWith(
                fontSize: 32,
                letterSpacing: -1,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Tu dinero en orden.',
              style: MenudoTextStyles.bodyMedium.copyWith(
                color: MenudoColors.textMuted,
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
