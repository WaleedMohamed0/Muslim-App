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
  AppCubit({required ConnectivityService connectivity, required HadeethCubit hadeeth, required PrayerTimesCubit prayerTimes, required QuranCubit quran, required AzkarCubit azkar})
      : _connectivity = connectivity, _hadeeth = hadeeth, _prayerTimes = prayerTimes, _quran = quran, _azkar = azkar, super(const AppState()) {
    _subscription = _connectivity.changes.listen(_onConnectivityChanged);
    loadThemeMode();
  }
  final ConnectivityService _connectivity;
  final HadeethCubit _hadeeth;
  final PrayerTimesCubit _prayerTimes;
  final QuranCubit _quran;
  final AzkarCubit _azkar;
  late final StreamSubscription<bool> _subscription;

  Future<void> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final isDark = preferences.getBool('isDarkMode') ?? false;
    emit(AppState(isConnected: state.isConnected, themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
  }

  Future<void> toggleThemeMode() async {
    final themeMode = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('isDarkMode', themeMode == ThemeMode.dark);
    emit(AppState(isConnected: state.isConnected, themeMode: themeMode));
  }

  void _onConnectivityChanged(bool connected) {
    emit(AppState(isConnected: connected, themeMode: state.themeMode));
    _prayerTimes.setConnectivity(connected);
    _quran.setConnectivity(connected);
    _azkar.setConnectivity(connected);
    if (connected) {
      _hadeeth.getHadeeth();
      _prayerTimes.getPrayerTime();
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
