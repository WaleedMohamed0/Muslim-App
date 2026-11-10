import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
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
  PrayerTimesErrorType? lastRefreshErrorType;

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
  Future<bool> getPrayerTime({bool forceRefresh = false}) async {
    if (_isLoadingPrayerTimes) return state.status == PrayerTimesStatus.loaded;
    if (forceRefresh) lastRefreshErrorType = null;
    _isLoadingPrayerTimes = true;
    try {
      final today = DateTime.now();
      final cached = await _getPrayerTimes.getCached(today);
      if (cached != null) {
        _publishPrayerTimes(cached);
        if (!isOnline && !forceRefresh) return true;
        // A cached schedule is already the result for the persistent cached
        // location. Device location is read only on an explicit refresh.
        if (!forceRefresh) return true;
      }
      if (cached == null || forceRefresh) {
        if (cached == null) {
          emit(const PrayerTimesState(status: PrayerTimesStatus.loading));
        }
        final times = await _getPrayerTimes(today, forceRefresh: forceRefresh);
        _publishPrayerTimes(times);
        return true;
      } else {
        // Cache is already visible. This background check validates the current
        // location and fetches only if today's cache belongs to another place.
        final times = await _getPrayerTimes(today);
        _publishPrayerTimes(times);
        return true;
      }
    } catch (error) {
      if (forceRefresh) lastRefreshErrorType = _errorType(error);
      // Keep a valid cached day visible when refresh/location lookup fails.
      if (state.status != PrayerTimesStatus.loaded) {
        final errorType = _errorType(error);
        emit(PrayerTimesState(
          error: _localizedError(error),
          errorType: errorType,
          status: PrayerTimesStatus.failure,
        ));
      }
      return false;
    } finally {
      _isLoadingPrayerTimes = false;
    }
  }

  String _localizedError(Object error) {
    if (error is PrayerLocationException) {
      return switch (error.failure) {
        PrayerLocationFailure.servicesDisabled =>
          'يرجى تفعيل الموقع (Location) لعرض مواقيت الصَّلَاة.',
        PrayerLocationFailure.permissionDenied =>
          'يرجى السماح للتطبيق بالوصول إلى الموقع لعرض مواقيت الصَّلَاة.',
        PrayerLocationFailure.permissionPermanentlyDenied =>
          'تم رفض إذن الموقع نهائيًا. افتح إعدادات التطبيق للسماح بالوصول إلى الموقع.',
        PrayerLocationFailure.unavailable =>
          'تعذر تحديد موقعك. تحقق من إعدادات الموقع وحاول مرة أخرى.',
      };
    }
    if (_isNetworkError(error)) return 'لا يوجد اتصال بالإنترنت';
    return 'تعذر تحميل مواقيت الصَّلَاة. يرجى المحاولة مرة أخرى.';
  }

  PrayerTimesErrorType _errorType(Object error) {
    if (error is PrayerLocationException) {
      return switch (error.failure) {
        PrayerLocationFailure.servicesDisabled =>
          PrayerTimesErrorType.locationServicesDisabled,
        PrayerLocationFailure.permissionDenied =>
          PrayerTimesErrorType.locationPermissionDenied,
        PrayerLocationFailure.permissionPermanentlyDenied =>
          PrayerTimesErrorType.locationPermissionPermanentlyDenied,
        PrayerLocationFailure.unavailable =>
          PrayerTimesErrorType.locationUnavailable,
      };
    }
    if (_isNetworkError(error)) return PrayerTimesErrorType.network;
    return PrayerTimesErrorType.general;
  }

  bool _isNetworkError(Object error) {
    if (error is DioException &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout)) {
      return true;
    }
    final cause = error is DioException ? error.error?.toString() ?? '' : '';
    final details = '${error.toString()} $cause'.toLowerCase();
    return details.contains('socketexception') ||
        details.contains('failed host lookup') ||
        details.contains('network is unreachable');
  }

  void _publishPrayerTimes(PrayerTimes times) {
    prayerTimesModel = times;
    // final testTime = DateTime.now().add(const Duration(seconds: 10));
    //
    // if (times.alarmTimes.length > 2) {
    //   unawaited(
    //     PrayerAdhanService.instance
    //         .updateSchedule([
    //       PrayerAlarmTime(
    //         prayerId: times.alarmTimes[1].prayerId,
    //         at: testTime,
    //       ),
    //     ])
    //         .catchError((Object _) {}),
    //   );
    // }

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
