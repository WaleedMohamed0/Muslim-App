import 'dart:async';

import 'package:dio/dio.dart';
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

  Future<void> loadCachedPrayerTimes() async {
    if (state.prayerTimes != null) return;
    try {
      final cached = await _getPrayerTimes.getCached(DateTime.now());
      if (cached != null && !isClosed && state.prayerTimes == null) {
        _publishPrayerTimes(cached);
      }
    } catch (_) {
      // The Adhan experience remains available if the optional cache fails.
    }
  }

  void setConnectivity(bool connected) {
    final justConnected = connected && !isOnline;
    isOnline = connected;
    if (justConnected &&
        !gotPrayerTimes &&
        state.status != PrayerTimesStatus.loading) {
      unawaited(getPrayerTime());
    }
    if (!connected && state.status == PrayerTimesStatus.initial) {
      unawaited(getPrayerTime());
    }
  }
  Future<void> getPrayerTime({bool forceRefresh = false}) async {
    if (_isLoadingPrayerTimes) return;
    _isLoadingPrayerTimes = true;
    try {
      final today = DateTime.now();
      final cached = await _getPrayerTimes.getCached(today);
      if (cached != null) {
        _publishPrayerTimes(cached);
        if (!isOnline) return;
      } else if (!isOnline) {
        emit(const PrayerTimesState(
          error: 'لا يوجد اتصال بالإنترنت',
          status: PrayerTimesStatus.failure,
        ));
        return;
      }
      if (cached == null || forceRefresh) {
        if (cached == null) {
          emit(const PrayerTimesState(status: PrayerTimesStatus.loading));
        }
        final times = await _getPrayerTimes(today, forceRefresh: forceRefresh);
        _publishPrayerTimes(times);
      } else {
        // Cache is already visible. This background check validates the current
        // location and fetches only if today's cache belongs to another place.
        final times = await _getPrayerTimes(today);
        _publishPrayerTimes(times);
      }
    } catch (error) {
      // Keep a valid cached day visible when refresh/location lookup fails.
      if (state.status != PrayerTimesStatus.loaded) {
        emit(PrayerTimesState(
          error: _localizedError(error),
          status: PrayerTimesStatus.failure,
        ));
      }
    } finally {
      _isLoadingPrayerTimes = false;
    }
  }

  String _localizedError(Object error) {
    final details = error.toString().toLowerCase();
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'لا يوجد اتصال بالإنترنت';
      }
      return 'تعذر تحميل مواقيت الصلاة. يرجى المحاولة مرة أخرى.';
    }
    if (details.contains('location permission denied') ||
        details.contains('permission denied')) {
      return 'يرجى السماح بالوصول إلى الموقع لعرض مواقيت الصلاة.';
    }
    if (details.contains('location services are disabled') ||
        details.contains('location service')) {
      return 'يرجى تفعيل خدمات الموقع لعرض مواقيت الصلاة.';
    }
    if (!isOnline ||
        details.contains('socketexception') ||
        details.contains('failed host lookup') ||
        details.contains('network is unreachable')) {
      return 'لا يوجد اتصال بالإنترنت';
    }
    return 'تعذر تحميل مواقيت الصلاة. يرجى المحاولة مرة أخرى.';
  }

  void _publishPrayerTimes(PrayerTimes times) {
    prayerTimesModel = times;
    unawaited(
      PrayerAdhanService.instance
          .updateSchedule(times.alarmTimes)
          .catchError((Object _) {}),
    );
    gotPrayerTimes = true;
    emit(PrayerTimesState(
      prayerTimes: times,
      status: PrayerTimesStatus.loaded,
      displayTimes: [
        _display('الفَجرِ', times.fajr, true),
        _display('الظُّهرِ', times.dhuhr, true),
        _display('العَصرِ', times.asr, false),
        _display('المغرِب', times.maghrib, false),
        _display('العِشَاءِ', times.isha, false),
      ],
    ));
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
