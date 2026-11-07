import 'package:flutter/material.dart';

/// A compact, theme-aware confirmation dialog shared by app actions.
Future<void> showAppActionDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  required String primaryLabel,
  required IconData primaryIcon,
  required VoidCallback onPrimary,
  required String secondaryLabel,
  required VoidCallback onSecondary,
  String? tertiaryLabel,
  IconData? tertiaryIcon,
  VoidCallback? onTertiary,
}) async {
  await showDialog<void>(
      context: context,
      builder: (dialogContext) => AppActionDialog(
        icon: icon,
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        primaryIcon: primaryIcon,
        onPrimary: () {
          Navigator.of(dialogContext).pop();
          onPrimary();
        },
        secondaryLabel: secondaryLabel,
        onSecondary: () {
          Navigator.of(dialogContext).pop();
          onSecondary();
        },
        tertiaryLabel: tertiaryLabel,
        tertiaryIcon: tertiaryIcon,
        onTertiary: onTertiary == null
            ? null
            : () {
                Navigator.of(dialogContext).pop();
                onTertiary();
              },
      ),
    );
}

class AppActionDialog extends StatelessWidget {
  const AppActionDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.tertiaryLabel,
    this.tertiaryIcon,
    this.onTertiary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final String? tertiaryLabel;
  final IconData? tertiaryIcon;
  final VoidCallback? onTertiary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 26, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    size: 29,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  textDirection: TextDirection.rtl,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    FilledButton.icon(
                      onPressed: onPrimary,
                      icon: Icon(primaryIcon, size: 19),
                      label: Text(primaryLabel),
                    ),
                    TextButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel),
                    ),
                    if (tertiaryLabel != null && onTertiary != null)
                      OutlinedButton.icon(
                        onPressed: onTertiary,
                        icon: Icon(tertiaryIcon ?? Icons.play_arrow_rounded, size: 18),
                        label: Text(tertiaryLabel!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
