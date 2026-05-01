import 'dart:async';

import 'package:flutter/material.dart';
import 'package:financeproject/core/theme/menudo_cupertino_icons.dart';

import '../../core/navigation/root_navigator.dart';
import '../../core/theme/app_colors.dart';

enum MenudoToastTone { success, error, info }

class MenudoToast {
  MenudoToast._();

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    MenudoToastTone tone = MenudoToastTone.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = _resolveOverlay(context);
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fallbackOverlay = rootNavigatorKey.currentState?.overlay;
        if (fallbackOverlay != null) {
          _insertOverlayEntry(
            fallbackOverlay,
            title: title,
            message: message,
            tone: tone,
            actionLabel: actionLabel,
            onAction: onAction,
            duration: duration,
          );
        }
      });
      return;
    }

    _insertOverlayEntry(
      overlay,
      title: title,
      message: message,
      tone: tone,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static OverlayState? _resolveOverlay(BuildContext context) {
    return Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context) ??
        rootNavigatorKey.currentState?.overlay ??
        Navigator.maybeOf(context, rootNavigator: true)?.overlay ??
        Navigator.maybeOf(context)?.overlay;
  }

  static void _insertOverlayEntry(
    OverlayState overlay, {
    required String title,
    String? message,
    MenudoToastTone tone = MenudoToastTone.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MenudoToastEntry(
        title: title,
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        duration: duration,
        onAction: onAction,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );
    overlay.insert(entry);
  }

  static void success(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    show(context, title: title, message: message);
  }

  static void error(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    show(context, title: title, message: message, tone: MenudoToastTone.error);
  }

  static void undo(
    BuildContext context, {
    required String title,
    String? message,
    required VoidCallback onUndo,
  }) {
    show(
      context,
      title: title,
      message: message,
      tone: MenudoToastTone.info,
      actionLabel: 'Deshacer',
      duration: const Duration(seconds: 6),
      onAction: onUndo,
    );
  }
}

class _MenudoToastEntry extends StatefulWidget {
  const _MenudoToastEntry({
    required this.title,
    required this.tone,
    required this.duration,
    required this.onDismissed,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final MenudoToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_MenudoToastEntry> createState() => _MenudoToastEntryState();
}

class _MenudoToastEntryState extends State<_MenudoToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _offset;
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 220),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curved);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  void _runAction() {
    widget.onAction?.call();
    unawaited(_dismiss());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.menudo;
    final topPadding = MediaQuery.paddingOf(context).top + 12;
    final style = _styleFor(context, widget.tone);

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          top: false,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _offset,
              child: ScaleTransition(
                scale: _scale,
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: colors.glassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: style.background,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              style.icon,
                              color: style.color,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textMain,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (widget.message != null &&
                                    widget.message!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.message!.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.actionLabel != null &&
                              widget.onAction != null) ...[
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: _runAction,
                              style: TextButton.styleFrom(
                                foregroundColor: colors.primary,
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child: Text(
                                widget.actionLabel!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastStyle _styleFor(BuildContext context, MenudoToastTone tone) {
    final colors = context.menudo;
    return switch (tone) {
      MenudoToastTone.success => _ToastStyle(
        icon: MenudoCupertinoIcons.check,
        color: colors.success,
        background: colors.successLight,
      ),
      MenudoToastTone.error => _ToastStyle(
        icon: MenudoCupertinoIcons.alertCircle,
        color: colors.danger,
        background: colors.dangerLight,
      ),
      MenudoToastTone.info => _ToastStyle(
        icon: MenudoCupertinoIcons.refresh_rounded,
        color: colors.primary,
        background: colors.primaryLight,
      ),
    };
  }
}

class _ToastStyle {
  const _ToastStyle({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}
