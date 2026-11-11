import 'package:shared_preferences/shared_preferences.dart';

class QuranWidgetIntroPreferences {
  const QuranWidgetIntroPreferences();

  static const _shownKey = 'quran_widget_intro_shown_v1';

  Future<bool> hasBeenShown() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_shownKey) ?? false;
    } catch (_) {
      // If local storage is unavailable, avoid interrupting the user.
      return true;
    }
  }

  Future<void> markShown() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_shownKey, true);
    } catch (_) {
      // The in-memory guard still prevents duplicates for this app session.
    }
  }
}
