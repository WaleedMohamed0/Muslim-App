import 'package:shared_preferences/shared_preferences.dart';

/// Local, offline configuration for the number of pages in the daily Wird.
class DailyWirdConfigurationRepository {
  static const _pagesKey = 'daily_wird_pages_per_day_v1';

  Future<int?> loadPagesPerDay() async {
    final prefs = await SharedPreferences.getInstance();
    final pages = prefs.getInt(_pagesKey);
    return pages != null && pages >= 1 && pages <= 604 ? pages : null;
  }

  Future<void> savePagesPerDay(int pages) async {
    if (pages < 1 || pages > 604) {
      throw ArgumentError.value(pages, 'pages', 'Must be between 1 and 604');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pagesKey, pages);
  }
}
