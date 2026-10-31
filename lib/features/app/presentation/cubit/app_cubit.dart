import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../hadeeth/presentation/cubit/hadeeth_cubit.dart';
import '../../../prayer_times/presentation/cubit/prayer_times_cubit.dart';
import '../../../quran/presentation/cubit/quran_cubit.dart';
import '../../../azkar/presentation/cubit/azkar_cubit.dart';
import 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit({
    required ConnectivityService connectivity,
    required HadeethCubit hadeeth,
    required PrayerTimesCubit prayerTimes,
    required QuranCubit quran,
    required AzkarCubit azkar,
  }) : _connectivity = connectivity,
       _hadeeth = hadeeth,
       _prayerTimes = prayerTimes,
       _quran = quran,
       _azkar = azkar,
       super(const AppState()) {
    _subscription = _connectivity.changes.listen(_onConnectivityChanged);
    _themeLoad = _restoreThemeMode();
    refreshConnectivity();
  }
  final ConnectivityService _connectivity;
  final HadeethCubit _hadeeth;
  final PrayerTimesCubit _prayerTimes;
  final QuranCubit _quran;
  final AzkarCubit _azkar;
  late final StreamSubscription<bool> _subscription;
  late final Future<void> _themeLoad;
  Future<void> _themeWrite = Future<void>.value();
  ThemeMode _requestedThemeMode = ThemeMode.light;
  bool _hasRequestedThemeMode = false;

  Future<void> refreshConnectivity() async {
    try {
      _emitConnectivity(await _connectivity.hasConnection);
    } catch (_) {
      _emitConnectivity(false);
    }
  }

  Future<void> _restoreThemeMode() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (isClosed) return;
      final isDark =
          _hasRequestedThemeMode
              ? _requestedThemeMode == ThemeMode.dark
              : preferences.getBool('isDarkMode') ?? false;
      emit(
        AppState(
          isConnected: state.isConnected,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        ),
      );
    } catch (_) {
      // Keep the light default if local preferences are temporarily unavailable.
    }
  }

  Future<void> toggleThemeMode() async {
    await _themeLoad;
    final current =
        _hasRequestedThemeMode ? _requestedThemeMode : state.themeMode;
    await setThemeMode(
      current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _themeLoad;
    _hasRequestedThemeMode = true;
    _requestedThemeMode = themeMode;
    if (state.themeMode == themeMode) {
      await _writeThemeMode(themeMode);
      return;
    }
    emit(AppState(isConnected: state.isConnected, themeMode: themeMode));
    await _writeThemeMode(themeMode);
  }

  Future<void> _writeThemeMode(ThemeMode themeMode) async {
    _themeWrite = _themeWrite.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool('isDarkMode', themeMode == ThemeMode.dark);
      } catch (_) {
        // Keep the in-memory preference if local storage is unavailable.
      }
    });
    await _themeWrite;
  }

  void _emitConnectivity(bool connected) {
    if (isClosed) return;
    if (connected == state.isConnected) return;
    emit(AppState(isConnected: connected, themeMode: state.themeMode));
    _prayerTimes.setConnectivity(connected);
    _quran.setConnectivity(connected);
    _azkar.setConnectivity(connected);
    if (connected) {
      _hadeeth.getHadeeth();
      _prayerTimes.getPrayerTime();
    }
  }

  void _onConnectivityChanged(bool connected) => _emitConnectivity(connected);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
