import 'package:financeproject/core/theme/app_colors.dart';
import 'package:financeproject/core/theme/app_spacing.dart';
import 'package:financeproject/core/utils/menudo_haptics.dart';
import 'package:financeproject/shared/widgets/menudo_tap_target.dart';
import 'package:flutter/cupertino.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.avatarEmoji,
    required this.avatarLabel,
    required this.title,
    required this.unreadAlerts,
    required this.onProfileTap,
    required this.onAlertsTap,
    required this.onSettingsTap,
  });

  final String? avatarEmoji;
  final String avatarLabel;
  final String title;
  final int unreadAlerts;
  final VoidCallback onProfileTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: MenudoGestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.menudo.successLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.e6.withValues(alpha: 0.12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: avatarEmoji != null && avatarEmoji!.isNotEmpty
                      ? Text(avatarEmoji!, style: TextStyle(fontSize: 24))
                      : Text(
                          avatarLabel,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colors.textMain,
                          ),
                        ),
                ),
                SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: colors.textMain,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacing.p12),
        Row(
          children: [
            _HeaderCircleButton(
              icon: CupertinoIcons.bell_fill,
              label: 'Alertas',
              badgeCount: unreadAlerts,
              onTap: onAlertsTap,
            ),
            SizedBox(width: AppSpacing.p10),
            _HeaderCircleButton(
              icon: CupertinoIcons.gear_solid,
              label: 'Ajustes',
              onTap: onSettingsTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;

    return Semantics(
      button: true,
      label: label,
      child: MenudoGestureDetector(
        onTap: () {
          MenudoHaptics.light();
          onTap();
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border, width: 0.5),
              ),
              child: Icon(icon, size: (20), color: colors.textMain),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.p6,
                    vertical: AppSpacing.p2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.o5,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 9 ? '9+' : badgeCount.toString(),
                    style: TextStyle(
                      color: context.menudo.surface,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
