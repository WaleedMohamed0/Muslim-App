import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the counter hint state shared by every azkar and dua screen.
class AzkarCounterHintPreferences {
  AzkarCounterHintPreferences._();

  static final AzkarCounterHintPreferences instance =
      AzkarCounterHintPreferences._();

  static const String _shownKey = 'azkar_counter_hint_shown_v2';
  static const List<String> _legacyShownKeys = [
    'azkar_counter_hint_shown_v1_0',
    'azkar_counter_hint_shown_v1_1',
  ];

  final ValueNotifier<bool> shouldShow = ValueNotifier(false);
  Future<void>? _loadOperation;
  bool _dismissed = false;

  Future<void> load() => _loadOperation ??= _load();

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final alreadyShown = preferences.getBool(_shownKey) ??
        _legacyShownKeys.any((key) => preferences.getBool(key) ?? false);
    if (_dismissed) return;
    shouldShow.value = !alreadyShown;
    if (alreadyShown && preferences.getBool(_shownKey) != true) {
      await preferences.setBool(_shownKey, true);
    }
  }

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    shouldShow.value = false;
    SharedPreferences.getInstance().then(
      (preferences) => preferences.setBool(_shownKey, true),
    );
  }
}
