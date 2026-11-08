import 'package:flutter/material.dart';

/// App-wide switch colors, tuned for light and dark themes.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      thumbColor: isLight
          ? WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? colors.onPrimary
                  : colors.surface)
          : null,
      trackColor: isLight
          ? WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? colors.primary
                  : colors.onSurfaceVariant)
          : null,
      trackOutlineColor: isLight
          ? WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? colors.primary
                  : colors.onSurfaceVariant)
          : null,
    );
  }
}

/// List tile with the app's shared switch control and consistent tap behavior.
class AppSwitchListTile extends StatelessWidget {
  const AppSwitchListTile({
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.leading,
    this.controlAffinity = ListTileControlAffinity.trailing,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final ListTileControlAffinity controlAffinity;

  @override
  Widget build(BuildContext context) {
    final switchWidget = AppSwitch(value: value, onChanged: onChanged);
    final leadingControl = controlAffinity == ListTileControlAffinity.leading;
    return ListTile(
      leading: leadingControl ? switchWidget : leading,
      trailing: leadingControl ? null : switchWidget,
      title: title,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}
