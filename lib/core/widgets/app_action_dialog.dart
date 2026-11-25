import 'package:material_ui/material_ui.dart';

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

/// Shows a confirmation dialog using the shared app action dialog layout.
Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  IconData? confirmIcon,
  String cancelLabel = 'إلغاء',
  bool confirmIconAfterLabel = false,
  Color? confirmBackgroundColor,
  Color? confirmForegroundColor,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppConfirmationDialog(
      icon: icon,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      confirmIcon: confirmIcon,
      confirmIconAfterLabel: confirmIconAfterLabel,
      confirmBackgroundColor: confirmBackgroundColor,
      confirmForegroundColor: confirmForegroundColor,
      cancelLabel: cancelLabel,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return confirmed ?? false;
}

class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.confirmIcon,
    this.confirmIconAfterLabel = false,
    this.confirmBackgroundColor,
    this.confirmForegroundColor,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final IconData? confirmIcon;
  final bool confirmIconAfterLabel;
  final Color? confirmBackgroundColor;
  final Color? confirmForegroundColor;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => AppActionDialog(
    icon: icon,
    title: title,
    message: message,
    primaryLabel: confirmLabel,
    primaryIcon: confirmIcon,
    primaryIconAfterLabel: confirmIconAfterLabel,
    primaryBackgroundColor: confirmBackgroundColor,
    primaryForegroundColor: confirmForegroundColor,
    onPrimary: onConfirm,
    secondaryLabel: cancelLabel,
    onSecondary: onCancel,
  );
}

class AppActionDialog extends StatelessWidget {
  const AppActionDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.tertiaryLabel,
    this.tertiaryIcon,
    this.onTertiary,
    this.primaryIconAfterLabel = false,
    this.primaryBackgroundColor,
    this.primaryForegroundColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final String? tertiaryLabel;
  final IconData? tertiaryIcon;
  final VoidCallback? onTertiary;
  final bool primaryIconAfterLabel;
  final Color? primaryBackgroundColor;
  final Color? primaryForegroundColor;

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
            padding: const EdgeInsetsDirectional.fromSTEB(20, 26, 20, 20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: TextDirection.rtl,
                  children: [
                    TextButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel),
                    ),
                    FilledButton(
                      onPressed: onPrimary,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryBackgroundColor,
                        foregroundColor: primaryForegroundColor,
                      ),
                      child: primaryIconAfterLabel
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Text(primaryLabel),
                                if (primaryIcon != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(primaryIcon, size: 19),
                                ],
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                if (primaryIcon != null) ...[
                                  Icon(primaryIcon, size: 19),
                                  const SizedBox(width: 8),
                                ],
                                Text(primaryLabel),
                              ],
                            ),
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
