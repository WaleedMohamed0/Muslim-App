import 'package:flutter/material.dart';

/// One styled, RTL-aware message surface shared by UI actions and cubits.
class AppSnackBar {
  AppSnackBar._();

  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show({
    required String message,
    Color? backgroundColor,
    bool success = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null || !messenger.mounted) return;

    final theme = Theme.of(messenger.context);
    final colorScheme = theme.colorScheme;
    final background =
        backgroundColor ??
        (success
            ? theme.brightness == Brightness.dark
                ? Colors.green
                : colorScheme.primary
            : colorScheme.inverseSurface);
    final foreground =
        success || backgroundColor != null
            ? Colors.white
            : colorScheme.onInverseSurface;

    // Treat messages as replacements so quick events never queue duplicate notices.
    messenger.removeCurrentSnackBar();
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 4,
        backgroundColor: background,
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 13, 18, 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 21, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
