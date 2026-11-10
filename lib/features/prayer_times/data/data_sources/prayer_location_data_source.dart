import 'package:geolocator/geolocator.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/prayer_times.dart';
import '../cache/prayer_times_cache.dart';
import '../cache/prayer_location_cache.dart';
import '../models/prayer_times_dto.dart';

class PrayerLocationDataSource {
  PrayerLocationDataSource({PrayerTimesCache? cache, PrayerLocationCache? locationCache})
      : _cache = cache ?? PrayerTimesCache(),
        _locationCache = locationCache ?? PrayerLocationCache();

  final PrayerTimesCache _cache;
  final PrayerLocationCache _locationCache;

  Future<PrayerTimes?> getCached(DateTime date) async {
    CachedPrayerTimes? cached;
    try {
      cached = await _cache.read(date);
    } catch (_) {
      return null;
    }
    if (cached == null) return null;
    // Migrate coordinates persisted alongside older daily schedules into the
    // durable standalone location cache without consulting device services.
    try {
      if (await _locationCache.read() == null) {
        await _locationCache.write(cached.latitude, cached.longitude);
      }
    } catch (_) {
      // The cached schedule remains usable if this optional migration fails.
    }
    return cached.times;
  }

  /// Refreshes Android's current service and permission status without using
  /// a stale cached grant or requesting any network data.
  Future<void> verifyLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const PrayerLocationException(PrayerLocationFailure.servicesDisabled);
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw const PrayerLocationException(
        PrayerLocationFailure.permissionPermanentlyDenied,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const PrayerLocationException(PrayerLocationFailure.permissionDenied);
    }
  }

  Future<PrayerTimesDto> fetch(DateTime date, {bool forceRefresh = false}) async {
    var location = await _locationCache.read();
    if (forceRefresh || location == null) {
      // First-launch permission is requested by StartupCubit after onboarding.
      // A later OS prompt is only appropriate after an explicit refresh tap.
      location = await _readDeviceLocation(requestPermission: forceRefresh);
      // Coordinates are written only after a valid successful device fix.
      try {
        await _locationCache.write(location.latitude, location.longitude);
      } catch (_) {
        // A storage issue must not discard a location that was just obtained.
      }
    }
    CachedPrayerTimes? cached;
    try {
      cached = await _cache.read(date);
    } catch (_) {
      // Continue with the API if local storage is temporarily unavailable.
    }
    if (!forceRefresh &&
        cached != null &&
        cached.matchesLocation(location.latitude, location.longitude)) {
      return PrayerTimesDto.fromEntity(cached.times);
    }
    final response = await _fetchCalendar(location.latitude, location.longitude, date);
    var result = PrayerTimesDto.fromCalendar(response, date);

    final nextMonth = DateTime(date.year, date.month + 1, 1);
    try {
      final nextResponse = await _fetchCalendar(
        location.latitude,
        location.longitude,
        nextMonth,
      );
      result = result.addAlarmTimes(
        PrayerTimesDto.fromCalendar(nextResponse, nextMonth).alarmTimes,
      );
    } catch (_) {
      // Today's times remain usable if the optional next-month request fails.
    }
    try {
      await _cache.write(
        date,
        location.latitude,
        location.longitude,
        result.toEntity(date),
      );
    } catch (_) {
      // Prayer times remain usable even if the device cannot persist the cache.
    }
    return result;
  }

  Future<CachedLocation> _readDeviceLocation({required bool requestPermission}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const PrayerLocationException(PrayerLocationFailure.servicesDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (requestPermission && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const PrayerLocationException(PrayerLocationFailure.permissionPermanentlyDenied);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        throw const PrayerLocationException(PrayerLocationFailure.permissionDenied);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final location = CachedLocation(position.latitude, position.longitude);
      if (!location.isValid) {
        throw const PrayerLocationException(PrayerLocationFailure.unavailable);
      }
      return location;
    } on LocationServiceDisabledException {
      throw const PrayerLocationException(PrayerLocationFailure.servicesDisabled);
    } on PermissionDeniedException {
      final currentPermission = await Geolocator.checkPermission();
      throw PrayerLocationException(
        currentPermission == LocationPermission.deniedForever
            ? PrayerLocationFailure.permissionPermanentlyDenied
            : PrayerLocationFailure.permissionDenied,
      );
    } on PrayerLocationException {
      rethrow;
    } catch (_) {
      throw const PrayerLocationException(PrayerLocationFailure.unavailable);
    }
  }

  Future<Map<String, dynamic>> _fetchCalendar(
    double latitude,
    double longitude,
    DateTime month,
  ) async {
    final response = await DioHelper.getData(
      endPoint: 'calendar',
      query: {
        'latitude': latitude,
        'longitude': longitude,
        'month': month.month,
        'year': month.year,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}

enum PrayerLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class PrayerLocationException implements Exception {
  const PrayerLocationException(this.failure);

  final PrayerLocationFailure failure;
}
