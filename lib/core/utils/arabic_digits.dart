/// Converts Western digits in a display string to Arabic-Indic digits.
String toArabicIndicDigits(Object value) => value.toString().replaceAllMapped(
  RegExp(r'[0-9]'),
  (match) => String.fromCharCode(match[0]!.codeUnitAt(0) + 0x0660 - 0x0030),
);
