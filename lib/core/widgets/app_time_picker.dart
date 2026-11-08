import 'package:flutter/material.dart';

/// Opens the app's standard Arabic, right-to-left time picker.
///
/// Keeping the locale override here ensures pickers use the same Arabic labels,
/// AM/PM period format, direction, and inherited app theme across features.
abstract final class AppTimePicker {
  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) => showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: Localizations.override(
        context: context,
        locale: const Locale('ar', 'EG'),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
