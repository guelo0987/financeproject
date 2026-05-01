import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/menudo_cupertino_icons.dart';

class MenudoSliverRefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const MenudoSliverRefreshControl({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: 96,
      refreshIndicatorExtent: 84,
      onRefresh: onRefresh,
      builder:
          (
            context,
            refreshState,
            pulledExtent,
            refreshTriggerPullDistance,
            refreshIndicatorExtent,
          ) {
            final colors = context.menudo;
            final progress = (pulledExtent / refreshTriggerPullDistance).clamp(
              0.0,
              1.0,
            );
            final refreshing =
                refreshState == RefreshIndicatorMode.refresh ||
                refreshState == RefreshIndicatorMode.armed ||
                refreshState == RefreshIndicatorMode.done;
            final label = switch (refreshState) {
              RefreshIndicatorMode.refresh => 'Actualizando',
              RefreshIndicatorMode.done => 'Listo',
              RefreshIndicatorMode.armed => 'Suelta para actualizar',
              _ => 'Tira para actualizar',
            };

            if (refreshState == RefreshIndicatorMode.inactive &&
                pulledExtent <= 0) {
              return const SizedBox.shrink();
            }

            return SizedBox.expand(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: refreshing
                            ? SizedBox(
                                key: const ValueKey('spinner'),
                                width: 18,
                                height: 18,
                                child: CupertinoActivityIndicator(
                                  color: colors.primary,
                                  radius: 9,
                                ),
                              )
                            : Transform.rotate(
                                key: const ValueKey('icon'),
                                angle: progress * math.pi * 1.2,
                                child: Icon(
                                  MenudoCupertinoIcons.sync,
                                  color: colors.primary,
                                  size: 18,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }
}
