import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the first-visit Mushaf zoom hint has been shown.
class MushafZoomHintPreferences {
  const MushafZoomHintPreferences();

  static const _shownKey = 'mushaf_zoom_hint_shown_v1';

  Future<bool> hasBeenShown() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_shownKey) ?? false;
    } catch (_) {
      // Avoid interrupting reading when local storage is unavailable.
      return true;
    }
  }

  Future<void> markShown() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_shownKey, true);
    } catch (_) {
      // The screen's in-memory state prevents repeats during this visit.
    }
  }
}
