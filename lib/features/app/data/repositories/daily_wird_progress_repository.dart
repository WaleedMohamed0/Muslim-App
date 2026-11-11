import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran;

class DailyWirdSession {
  const DailyWirdSession({
    required this.startPage,
    required this.endPage,
    required this.checkpointPage,
    required this.checkpointSurah,
    required this.checkpointAyah,
    required this.completed,
  });

  final int startPage;
  final int endPage;
  final int checkpointPage;
  final int checkpointSurah;
  final int checkpointAyah;
  final bool completed;
}

/// Persists a rolling Daily Wird checkpoint, independently from other readers.
class DailyWirdProgressRepository {
  static const _dayKey = 'daily_wird_progress_day_v1';
  static const _startPageKey = 'daily_wird_progress_start_page_v1';
  static const _endPageKey = 'daily_wird_progress_end_page_v1';
  static const _pageKey = 'daily_wird_progress_page_v1';
  static const _surahKey = 'daily_wird_progress_surah_v1';
  static const _ayahKey = 'daily_wird_progress_ayah_v1';
  static const _completedKey = 'daily_wird_completed_day_v1';

  String _dateKey([DateTime? value]) {
    final date = value ?? DateTime.now();
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<DailyWirdSession> prepareSession(int pagesPerDay) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();
    final savedDay = prefs.getString(_dayKey);
    var start = prefs.getInt(_startPageKey) ?? 1;
    var end = prefs.getInt(_endPageKey) ?? _endFor(start, pagesPerDay);
    var assignNewRange = savedDay == null;

    if (savedDay == null) {
      start = 1;
      end = _endFor(start, pagesPerDay);
      await prefs.setInt(_pageKey, start);
      await prefs.remove(_surahKey);
      await prefs.remove(_ayahKey);
    } else if (savedDay != today) {
      if (prefs.getString(_completedKey) == savedDay) {
        start = end == 604 ? 1 : end + 1;
        assignNewRange = true;
        await prefs.setInt(_pageKey, start);
        await prefs.remove(_surahKey);
        await prefs.remove(_ayahKey);
      }
      // An unfinished Wird keeps its original range and exact checkpoint.
    } else if (savedDay == today &&
        prefs.getString(_completedKey) != today) {
      // Updating the pages-per-day setting adjusts today's unfinished target.
      assignNewRange = true;
    }

    if (assignNewRange) {
      end = _endFor(start, pagesPerDay);
    }
    await prefs.setString(_dayKey, today);
    await prefs.setInt(_startPageKey, start);
    await prefs.setInt(_endPageKey, end);

    final checkpoint = prefs.getInt(_pageKey) ?? start;
    final first = quran.getPageData(checkpoint).first as Map;
    final surah = prefs.getInt(_surahKey) ?? (first['surah'] as num).toInt();
    final ayah = prefs.getInt(_ayahKey) ?? (first['start'] as num).toInt();
    return DailyWirdSession(
      startPage: start,
      endPage: end,
      checkpointPage: checkpoint.clamp(start, end).toInt(),
      checkpointSurah: surah,
      checkpointAyah: ayah,
      completed: prefs.getString(_completedKey) == today,
    );
  }

  Future<void> savePosition(int page, int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pageKey, page);
    await prefs.setInt(_surahKey, surah);
    await prefs.setInt(_ayahKey, ayah);
  }

  Future<bool> completeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();
    if (prefs.getString(_completedKey) == today) return false;
    await prefs.setString(_completedKey, today);
    return true;
  }

  Future<bool> isCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_completedKey) == _dateKey();
  }

  int _endFor(int start, int pages) =>
      (start + pages - 1).clamp(start, 604).toInt();

}
