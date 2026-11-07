import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WorshipLearningRepository {
  static const _progressKey = 'worship_lesson_progress_v1';
  static const _quizAttemptKey = 'worship_prayer_quiz_attempt_v1';

  Future<Map<String, dynamic>?> quizAttempt([String lessonId = 'prayer']) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_quizAttemptKeyFor(lessonId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveQuizAttempt(Map<String, dynamic> attempt, [String lessonId = 'prayer']) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_quizAttemptKeyFor(lessonId), jsonEncode(attempt));
  }

  Future<void> clearQuizAttempt([String lessonId = 'prayer']) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_quizAttemptKeyFor(lessonId));
  }

  String _quizAttemptKeyFor(String lessonId) =>
      lessonId == 'prayer' ? _quizAttemptKey : 'worship_${lessonId}_quiz_attempt_v1';

  Future<int> progress(String lessonId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt('${_progressKey}_$lessonId') ?? 0;
  }

  Future<void> saveProgress(String lessonId, int stepIndex) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('${_progressKey}_$lessonId', stepIndex);
  }

  Future<bool> isComplete(String lessonId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('${_progressKey}_${lessonId}_complete') ?? false;
  }

  Future<void> setComplete(String lessonId, bool complete) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('${_progressKey}_${lessonId}_complete', complete);
  }
}
