import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/utils/arabic_digits.dart';
import 'package:untitled8/features/prayer_times/data/services/prayer_adhan_service.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/use_cases/get_prayer_times.dart';
import '../../data/data_sources/prayer_location_data_source.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import 'prayer_times_state.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({GetPrayerTimes? getPrayerTimes})
      : _getPrayerTimes = getPrayerTimes ?? GetPrayerTimes(PrayerTimesRepositoryImpl(PrayerLocationDataSource())),
        super(const PrayerTimesState());

  final GetPrayerTimes _getPrayerTimes;

  PrayerTimes? prayerTimesModel;
  bool gotPrayerTimes = false;
  bool isOnline = false;
  bool _isLoadingPrayerTimes = false;

  void setConnectivity(bool connected) {
    final justConnected = connected && !isOnline;
    isOnline = connected;
    if (justConnected &&
        !gotPrayerTimes &&
        state.status != PrayerTimesStatus.loading) {
      unawaited(getPrayerTime());
    }
    if (!connected && state.status == PrayerTimesStatus.initial) {
      emit(const PrayerTimesState(
        error: 'Internet connection required',
        status: PrayerTimesStatus.failure,
      ));
    }
  }
  Future<void> getPrayerTime() async {
    if (_isLoadingPrayerTimes) return;
    try {
      if (!isOnline) {
        emit(const PrayerTimesState(error: 'Internet connection required', status: PrayerTimesStatus.failure));
        return;
      }
      _isLoadingPrayerTimes = true;
      emit(const PrayerTimesState(status: PrayerTimesStatus.loading));
      final times = await _getPrayerTimes(DateTime.now());
      prayerTimesModel = times;
      unawaited(
        PrayerAdhanService.instance
            .updateSchedule(times.alarmTimes)
            .catchError((Object _) {}),
      );
      gotPrayerTimes = true;
      emit(PrayerTimesState(prayerTimes: times, status: PrayerTimesStatus.loaded, displayTimes: [
        _display('الفَجرِ', times.fajr, true),
        _display('الظُّهرِ', times.dhuhr, true),
        _display('العَصرِ', times.asr, false),
        _display('المغرِب', times.maghrib, false),
        _display('العِشَاءِ', times.isha, false),
      ]));
    } catch (error) {
      emit(PrayerTimesState(error: error.toString(), status: PrayerTimesStatus.failure));
    } finally {
      _isLoadingPrayerTimes = false;
    }
  }

  PrayerDisplayTime _display(String name, DateTime time, bool morning) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return PrayerDisplayTime(
      name: name,
      time: toArabicIndicDigits('$hour:$minute'),
      period: morning ? 'ص' : 'م',
    );
  }
}
