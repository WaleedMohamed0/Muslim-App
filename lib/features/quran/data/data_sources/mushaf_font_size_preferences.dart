import 'package:shared_preferences/shared_preferences.dart';

/// Stores the reader's selected Mushaf text size.
class MushafFontSizePreferences {
  const MushafFontSizePreferences();

  static const _fontSizeKey = 'mushaf_font_size_v1';

  Future<double> load({required double defaultValue}) async {
    try {
      return (await SharedPreferences.getInstance()).getDouble(_fontSizeKey) ??
          defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  Future<void> save(double value) async {
    try {
      await (await SharedPreferences.getInstance()).setDouble(_fontSizeKey, value);
    } catch (_) {
      // Keep the current selection for this reader session if storage fails.
    }
  }
}
