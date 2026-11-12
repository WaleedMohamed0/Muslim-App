import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the first-visit Mushaf gesture hint has been dismissed.
class MushafLongPressHintPreferences {
  const MushafLongPressHintPreferences();

  static const _shownKey = 'mushaf_long_press_hint_shown_v1';

  Future<bool> hasBeenShown() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_shownKey) ?? false;
    } catch (_) {
      // If storage is unavailable, skip the hint rather than interrupt reading.
      return true;
    }
  }

  Future<void> markShown() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_shownKey, true);
    } catch (_) {
      // The screen's in-memory guard still prevents repeats this session.
    }
  }
}
