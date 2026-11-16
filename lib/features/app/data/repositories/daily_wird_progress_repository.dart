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

class DailyWirdStreakStats {
  const DailyWirdStreakStats({required this.currentStreak, required this.bestStreak, required this.totalCompletedDays, required this.completedDates, required this.completedToday, this.newMilestone});
  final int currentStreak;
  final int bestStreak;
  final int totalCompletedDays;
  final Set<String> completedDates;
  final bool completedToday;
  final int? newMilestone;
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
  static const _bestStreakKey = 'daily_wird_best_streak_v1';
  static const _milestonesKey = 'daily_wird_shown_milestones_v1';

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
      // Continue the Daily Wird's own sequence across days. If yesterday was
      // completed, begin after its target; otherwise resume its last page.
      final previousEnd = prefs.getInt(_endPageKey) ?? checkpointPage;
      final previousPage = prefs.getInt(_pageKey) ?? checkpointPage;
      start = prefs.getString(_completedKey) == savedDay
          ? (previousEnd >= 604 ? 1 : previousEnd + 1)
          : previousPage;
      start = start.clamp(1, 604).toInt();
      assignNewRange = true;
      await prefs.setInt(_pageKey, start);
      await prefs.remove(_surahKey);
      await prefs.remove(_ayahKey);
    }

    if (assignNewRange) {
      end = _endFor(start, pagesPerDay);
    }
    await prefs.setString(_dayKey, today);
    await prefs.setInt(_startPageKey, start);
    await prefs.setInt(_endPageKey, end);

    final checkpoint = savedDay == today
        ? (prefs.getInt(_pageKey) ?? checkpointPage)
        : checkpointPage;
    final first = MushafLineLayoutData.pageData(checkpoint).first;
    final surah = savedDay == today
        ? (prefs.getInt(_surahKey) ?? checkpointSurah)
        : (checkpointPage == 1 ? 1 : checkpointSurah);
    final ayah = savedDay == today
        ? (prefs.getInt(_ayahKey) ?? checkpointAyah)
        : (checkpointPage == 1 ? 1 : checkpointAyah);
    return DailyWirdSession(
      startPage: start,
      endPage: end,
      checkpointPage: checkpoint.clamp(start, end).toInt(),
      checkpointSurah: surah,
      checkpointAyah: ayah,
      completed: prefs.getString(_completedKey) == today,
    );
  }

  Future<void> recordPage({
    required int page,
    required int surah,
    required int ayah,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();
    if (prefs.getString(_dayKey) != today) return;
    final start = prefs.getInt(_startPageKey) ?? 1;
    final end = prefs.getInt(_endPageKey) ?? start;
    if (page < start || page > end) return;
    await prefs.setInt(_pageKey, page);
    await prefs.setInt(_surahKey, surah);
    await prefs.setInt(_ayahKey, ayah);
  }

  Future<bool> completeToday() async {
    final result = await completeTodayWithStats();
    return result.completedToday;
  }

  Future<DailyWirdStreakStats> loadStreakStats() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = (prefs.getStringList(_completedDaysKey) ?? <String>[]).toSet();
    final today = _dateKey();
    return _stats(prefs, dates, today, completedToday: dates.contains(today));
  }

  Future<DailyWirdStreakStats> completeTodayWithStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();
    final completedDays = (prefs.getStringList(_completedDaysKey) ?? <String>[]).toSet();
    if (completedDays.contains(today)) return _stats(prefs, completedDays, today, completedToday: false);
    await prefs.setString(_completedKey, today);
    completedDays.add(today);
    await prefs.setStringList(_completedDaysKey, completedDays.toList()..sort());
    final oldBest = prefs.getInt(_bestStreakKey) ?? 0;
    final computed = _currentStreak(completedDays, today);
    final best = computed > oldBest ? computed : oldBest;
    await prefs.setInt(_bestStreakKey, best);
    final shown = prefs.getStringList(_milestonesKey) ?? <String>[];
    const milestones = <int>[7, 14, 30, 60, 100];
    final reached = milestones.where((m) => computed == m && !shown.contains('$m')).toList();
    if (reached.isNotEmpty) {
      shown.add('${reached.first}');
      await prefs.setStringList(_milestonesKey, shown);
    }
    return DailyWirdStreakStats(currentStreak: computed, bestStreak: best, totalCompletedDays: completedDays.length, completedDates: completedDays, completedToday: true, newMilestone: reached.isEmpty ? null : reached.first);
  }

  DailyWirdStreakStats _stats(SharedPreferences prefs, Set<String> dates, String today, {required bool completedToday}) {
    final current = _currentStreak(dates, today);
    final storedBest = prefs.getInt(_bestStreakKey) ?? 0;
    final historicalBest = _bestHistoricalStreak(dates);
    final best = [storedBest, historicalBest, current].reduce((a, b) => a > b ? a : b);
    return DailyWirdStreakStats(currentStreak: current, bestStreak: best, totalCompletedDays: dates.length, completedDates: dates, completedToday: completedToday);
  }

  int _bestHistoricalStreak(Set<String> dates) {
    final sorted = dates.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final key in sorted) {
      final date = DateTime.tryParse(key);
      if (date == null) continue;
      run = previous != null && date.difference(previous).inDays == 1 ? run + 1 : 1;
      if (run > best) best = run;
      previous = date;
    }
    return best;
  }

  int _currentStreak(Set<String> dates, String today) {
    var cursor = DateTime.tryParse(today)!;
    if (!dates.contains(today)) cursor = cursor.subtract(const Duration(days: 1));
    var count = 0;
    while (dates.contains(_dateKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  Future<bool> isCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_completedKey) == _dateKey();
  }

  Future<bool> hasStartedToday() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_dayKey) != _dateKey()) return false;
    final start = prefs.getInt(_startPageKey);
    final page = prefs.getInt(_pageKey);
    return start != null && page != null && page > start;
  }

  int _endFor(int start, int pages) =>
      (start + pages - 1).clamp(start, 604).toInt();
}
