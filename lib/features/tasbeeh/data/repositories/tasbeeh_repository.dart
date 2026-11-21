import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/core/storage/cache_helper.dart';
import 'package:muslim/features/tasbeeh/domain/entities/tasbeeh_item.dart';
import 'package:muslim/features/tasbeeh/domain/entities/tasbeeh_state.dart';

class TasbeehRepository {
  static const _countKey = 'electronic_tasbeeh_count';
  static const _dhikrCountPrefix = 'electronic_tasbeeh_count_';
  static const _dhikrKey = 'electronic_tasbeeh_dhikr';
  static const _targetKey = 'electronic_tasbeeh_target';
  static const _targetPrefix = 'electronic_tasbeeh_target_';
  static const _dailyDateKey = 'electronic_tasbeeh_daily_date';
  static const _dailyTotalKey = 'electronic_tasbeeh_daily_total';

  static const dhikrs = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'أَسْتَغْفِرُ اللَّهَ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  ];

  String get _today => DateTime.now().toIso8601String().substring(0, 10);
  String _countKeyFor(String dhikr) => '$_dhikrCountPrefix${Uri.encodeComponent(dhikr)}';
  String _targetKeyFor(String dhikr) => '$_targetPrefix${Uri.encodeComponent(dhikr)}';

  TasbeehState? get cachedState {
    final prefs = CacheHelper.sharedPreferences;
    if (prefs == null) return null;

    final savedDhikr = prefs.getString(_dhikrKey);
    final selectedDhikr = dhikrs.contains(savedDhikr) ? savedDhikr! : dhikrs.first;
    final legacyCount = prefs.getInt(_countKey) ?? 0;
    final legacyTarget = prefs.getInt(_targetKey) ?? 33;
    final items = [
      for (final dhikr in dhikrs)
        TasbeehItem(
          dhikr: dhikr,
          count: prefs.getInt(_countKeyFor(dhikr)) ??
              (dhikr == selectedDhikr ? legacyCount : 0),
          target: prefs.getInt(_targetKeyFor(dhikr)) ??
              (dhikr == selectedDhikr ? legacyTarget : 33),
        ),
    ];
    final dailyTotal = prefs.getString(_dailyDateKey) == _today
        ? prefs.getInt(_dailyTotalKey) ?? 0
        : 0;

    return TasbeehState(
      items: items,
      selectedDhikr: selectedDhikr,
      dailyTotal: dailyTotal,
    );
  }

  Future<TasbeehState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDhikr = prefs.getString(_dhikrKey);
    // Older builds displayed all four phrases as one combined label. Keep that
    // saved counter attached to the first phrase when migrating it.
    final selectedDhikr = dhikrs.contains(savedDhikr) ? savedDhikr! : dhikrs.first;
    final legacyCount = prefs.getInt(_countKey) ?? 0;
    final legacyTarget = prefs.getInt(_targetKey) ?? 33;
    final items = <TasbeehItem>[];

    for (final dhikr in dhikrs) {
      final countKey = _countKeyFor(dhikr);
      final targetKey = _targetKeyFor(dhikr);
      final count = prefs.getInt(countKey) ?? (dhikr == selectedDhikr ? legacyCount : 0);
      final target = prefs.getInt(targetKey) ?? (dhikr == selectedDhikr ? legacyTarget : 33);
      // Seed per-item values once while preserving the legacy selected item's progress.
      await prefs.setInt(countKey, count);
      await prefs.setInt(targetKey, target);
      items.add(TasbeehItem(dhikr: dhikr, count: count, target: target));
    }

    final total = prefs.getString(_dailyDateKey) == _today ? (prefs.getInt(_dailyTotalKey) ?? 0) : 0;
    if (prefs.getString(_dailyDateKey) != _today) {
      await prefs.setString(_dailyDateKey, _today);
      await prefs.setInt(_dailyTotalKey, 0);
    }
    await prefs.setString(_dhikrKey, selectedDhikr);
    return TasbeehState(items: items, selectedDhikr: selectedDhikr, dailyTotal: total, isLoading: false);
  }

  Future<void> save(TasbeehState state) async {
    final prefs = await SharedPreferences.getInstance();
    for (final item in state.items) {
      await prefs.setInt(_countKeyFor(item.dhikr), item.count);
      await prefs.setInt(_targetKeyFor(item.dhikr), item.target);
    }
    // Keep legacy keys in sync with the active item for downgrade compatibility.
    await prefs.setInt(_countKey, state.count);
    await prefs.setString(_dhikrKey, state.selectedDhikr);
    await prefs.setInt(_targetKey, state.target);
    await prefs.setString(_dailyDateKey, _today);
    await prefs.setInt(_dailyTotalKey, state.dailyTotal);
  }
}
