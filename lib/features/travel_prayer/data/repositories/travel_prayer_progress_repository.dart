import 'package:shared_preferences/shared_preferences.dart';

class TravelPrayerProgressRepository {
  static const _completedKey = 'travel_prayer_completed_lessons_v1';
  static const _answersKey = 'travel_prayer_quiz_answers_v1';

  Future<Set<String>> loadCompleted() async =>
      (await SharedPreferences.getInstance()).getStringList(_completedKey)?.toSet() ?? {};

  Future<void> saveCompleted(Set<String> completed) async =>
      (await SharedPreferences.getInstance()).setStringList(_completedKey, completed.toList());

  Future<List<int>> loadAnswers() async =>
      (await SharedPreferences.getInstance()).getStringList(_answersKey)?.map(int.parse).toList() ?? [];

  Future<void> saveAnswers(List<int> answers) async =>
      (await SharedPreferences.getInstance()).setStringList(_answersKey, answers.map((e) => '$e').toList());
}
