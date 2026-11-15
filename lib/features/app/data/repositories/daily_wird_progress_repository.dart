import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';

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
  static const _completedDaysKey = 'daily_wird_completed_days_v1';

  String _dateKey([DateTime? value]) {
    final date = value ?? DateTime.now();
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<DailyWirdSession> prepareSession(int pagesPerDay, {int checkpointPage = 1, int checkpointSurah = 1, int checkpointAyah = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();
    final savedDay = prefs.getString(_dayKey);
    var start = checkpointPage.clamp(1, 604).toInt();
    var end = prefs.getInt(_endPageKey) ?? _endFor(start, pagesPerDay);
    var assignNewRange = savedDay == null;

    if (savedDay == null) {
      start = checkpointPage.clamp(1, 604).toInt();
      end = _endFor(start, pagesPerDay);
      await prefs.setInt(_pageKey, start);
      await prefs.remove(_surahKey);
      await prefs.remove(_ayahKey);
    } else if (savedDay != today) {
      // A new calendar day always gets a new range. Carrying yesterday's
      // checkpoint forward can leave the reader stuck in yesterday's Wird.
      start = checkpointPage.clamp(1, 604).toInt();
      assignNewRange = true;
      await prefs.setInt(_pageKey, start);
      await prefs.remove(_surahKey);
      await prefs.remove(_ayahKey);
    } else if (savedDay == today && prefs.getString(_completedKey) != today) {
      // Updating the pages-per-day setting adjusts today's unfinished target.
      assignNewRange = true;
    }

    if (assignNewRange) {
      end = _endFor(start, pagesPerDay);
    }
    await prefs.setString(_dayKey, today);
    await prefs.setInt(_startPageKey, start);
    await prefs.setInt(_endPageKey, end);

    final checkpoint = checkpointPage;
    final first = MushafLineLayoutData.pageData(checkpoint).first;
    final surah = checkpointPage == 1 ? 1 : checkpointSurah;
    final ayah = checkpointPage == 1 ? 1 : checkpointAyah;
    return DailyWirdSession(
      startPage: start,
      endPage: end,
      checkpointPage: checkpoint.clamp(start, end).toInt(),
      checkpointSurah: surah,
      checkpointAyah: ayah,
      completed: prefs.getString(_completedKey) == today,
    );
  }

  Future<bool> completeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();
    if (prefs.getString(_completedKey) == today) return false;
    await prefs.setString(_completedKey, today);
    final completedDays = prefs.getStringList(_completedDaysKey) ?? <String>[];
    if (!completedDays.contains(today)) {
      completedDays.add(today);
      await prefs.setStringList(_completedDaysKey, completedDays);
    }
    return true;
  }

  Future<bool> isCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_completedKey) == _dateKey();
  }

  int _endFor(int start, int pages) =>
      (start + pages - 1).clamp(start, 604).toInt();
}
