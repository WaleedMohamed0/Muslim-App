import 'package:shared_preferences/shared_preferences.dart';

class PrayerWirdProgressRepository {
  static const _periodKey = 'home_prayer_wird_period_v1';
  static const _completedKey = 'home_prayer_wird_completed_v1';
  static const _periodCompletionsKey =
      'home_prayer_wird_period_completions_v1';
  static const _firstAzanFinishedKey = 'home_first_azan_finished_v1';
  static const _firstPrayerPeriodKey = 'home_first_prayer_period_v1';
  static const _firstRunKey = 'quran_widget_intro_eligible_v1';

  Future<bool> isPostAzanEligible(String currentPeriod) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_firstAzanFinishedKey) == true ||
        !(prefs.getBool(_firstRunKey) ?? false)) {
      return true;
    }

    // On a new installation, wait until a prayer period changes. This means
    // the first scheduled prayer time after install unlocks the Home card,
    // even if the user is not currently playing Adhan audio.
    final firstPeriod = prefs.getString(_firstPrayerPeriodKey);
    if (firstPeriod == null) {
      await prefs.setString(_firstPrayerPeriodKey, currentPeriod);
      return false;
    }
    if (firstPeriod == currentPeriod) return false;

    await prefs.setBool(_firstAzanFinishedKey, true);
    return true;
  }

  Future<void> markFirstAzanFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstAzanFinishedKey, true);
  }

  Future<Set<String>> completedFor(String period) async {
    final prefs = await SharedPreferences.getInstance();
    final completions =
        (prefs.getStringList(_periodCompletionsKey) ?? const <String>[])
            .toSet();
    final prefix = '$period|';
    final saved = completions
        .where((entry) => entry.startsWith(prefix))
        .map((entry) => entry.substring(prefix.length))
        .toSet();

    // Migrate completion from the previous single-period storage format.
    if (prefs.getString(_periodKey) == period) {
      saved.addAll(prefs.getStringList(_completedKey) ?? const <String>[]);
      completions.addAll(saved.map((id) => '$period|$id'));
      await prefs.setStringList(
        _periodCompletionsKey,
        completions.toList(growable: false),
      );
    }
    return saved;
  }

  Future<void> markCompleted(String period, String cardId) async {
    final prefs = await SharedPreferences.getInstance();
    final completions =
        (prefs.getStringList(_periodCompletionsKey) ?? const <String>[])
            .toSet();
    completions.add('$period|$cardId');
    await prefs.setStringList(
      _periodCompletionsKey,
      completions.toList(growable: false),
    );

    // Keep the previous keys updated for compatibility with older app builds.
    final completed = prefs.getString(_periodKey) == period
        ? (prefs.getStringList(_completedKey) ?? const <String>[]).toSet()
        : <String>{};
    completed.add(cardId);
    await prefs.setString(_periodKey, period);
    await prefs.setStringList(_completedKey, completed.toList(growable: false));
  }
}
