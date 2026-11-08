import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/features/tasbeeh/domain/entities/tasbeeh_state.dart';

class TasbeehRepository {
  static const _countKey = 'electronic_tasbeeh_count';
  static const _dhikrCountPrefix = 'electronic_tasbeeh_count_';
  static const _dhikrKey = 'electronic_tasbeeh_dhikr';
  static const _targetKey = 'electronic_tasbeeh_target';
  static const _dailyDateKey = 'electronic_tasbeeh_daily_date';
  static const _dailyTotalKey = 'electronic_tasbeeh_daily_total';

  String get _today => DateTime.now().toIso8601String().substring(0, 10);
  String _countKeyFor(String dhikr) => '$_dhikrCountPrefix${Uri.encodeComponent(dhikr)}';

  Future<TasbeehState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getString(_dailyDateKey) == _today ? (prefs.getInt(_dailyTotalKey) ?? 0) : 0;
    if (prefs.getString(_dailyDateKey) != _today) {
      await prefs.setString(_dailyDateKey, _today);
      await prefs.setInt(_dailyTotalKey, 0);
    }
    final dhikr = prefs.getString(_dhikrKey) ?? 'سُبْحَانَ اللَّهِ';
    final dhikrCountKey = _countKeyFor(dhikr);
    // Migrate the existing shared count to the saved dhikr the first time it loads.
    final count = prefs.getInt(dhikrCountKey) ?? prefs.getInt(_countKey) ?? 0;
    await prefs.setInt(dhikrCountKey, count);
    return TasbeehState(
      count: count,
      dhikr: dhikr,
      target: prefs.getInt(_targetKey) ?? 33,
      dailyTotal: total,
      isLoading: false,
    );
  }

  Future<int> loadCountForDhikr(String dhikr) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKeyFor(dhikr)) ?? 0;
  }

  Future<void> save(TasbeehState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKeyFor(state.dhikr), state.count);
    // Keep the legacy key in sync for older app versions.
    await prefs.setInt(_countKey, state.count);
    await prefs.setString(_dhikrKey, state.dhikr);
    await prefs.setInt(_targetKey, state.target);
    if (prefs.getString(_dailyDateKey) != _today) {
      await prefs.setString(_dailyDateKey, _today);
      await prefs.setInt(_dailyTotalKey, state.dailyTotal);
    } else {
      await prefs.setInt(_dailyTotalKey, state.dailyTotal);
    }
  }
}
