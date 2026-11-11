import 'package:shared_preferences/shared_preferences.dart';

class PrayerWirdProgressRepository {
  static const _periodKey = 'home_prayer_wird_period_v1';
  static const _completedKey = 'home_prayer_wird_completed_v1';
  static const _firstAzanFinishedKey = 'home_first_azan_finished_v1';
  static const _firstRunKey = 'quran_widget_intro_eligible_v1';

  Future<bool> isPostAzanEligible() async {
    final prefs = await SharedPreferences.getInstance();
    // Existing installations predate this gate and must retain their current
    // post-Azan behavior. New onboarding installs carry the first-run marker.
    return prefs.getBool(_firstAzanFinishedKey) ??
        !(prefs.getBool(_firstRunKey) ?? false);
  }

  Future<void> markFirstAzanFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstAzanFinishedKey, true);
  }

  Future<Set<String>> completedFor(String period) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_periodKey) != period) {
      await prefs.setString(_periodKey, period);
      await prefs.setStringList(_completedKey, const []);
      return <String>{};
    }
    return (prefs.getStringList(_completedKey) ?? const <String>[]).toSet();
  }

  Future<void> markCompleted(String period, String cardId) async {
    final completed = await completedFor(period)..add(cardId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_periodKey, period);
    await prefs.setStringList(_completedKey, completed.toList(growable: false));
  }
}
