import 'package:geolocator/geolocator.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/prayer_times.dart';
import '../cache/prayer_times_cache.dart';
import '../models/prayer_times_dto.dart';

class PrayerLocationDataSource {
  PrayerLocationDataSource({PrayerTimesCache? cache}) : _cache = cache ?? PrayerTimesCache();

  final PrayerTimesCache _cache;

  Future<PrayerTimes?> getCached(DateTime date) async {
    CachedPrayerTimes? cached;
    try {
      cached = await _cache.read(date);
    } catch (_) {
      return null;
    }
    if (cached == null) return null;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null &&
            !cached.matchesLocation(lastKnown.latitude, lastKnown.longitude)) {
          return null;
        }
      }
    } catch (_) {
      // Retain today's cache if Android cannot provide a last-known fix.
    }
    return cached.times;
  }

  Future<PrayerTimesDto> fetch(DateTime date, {bool forceRefresh = false}) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    CachedPrayerTimes? cached;
    try {
      cached = await _cache.read(date);
    } catch (_) {
      // Continue with the API if local storage is temporarily unavailable.
    }
    if (!forceRefresh &&
        cached != null &&
        cached.matchesLocation(position.latitude, position.longitude)) {
      return PrayerTimesDto.fromEntity(cached.times);
    }
    final response = await _fetchCalendar(position.latitude, position.longitude, date);
    var result = PrayerTimesDto.fromCalendar(response, date);

    final nextMonth = DateTime(date.year, date.month + 1, 1);
    try {
      final nextResponse = await _fetchCalendar(
        position.latitude,
        position.longitude,
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
        position.latitude,
        position.longitude,
        result.toEntity(date),
      );
    } catch (_) {
      // Prayer times remain usable even if the device cannot persist the cache.
    }
    return result;
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
