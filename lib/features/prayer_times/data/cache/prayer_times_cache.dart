import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/prayer_alarm_time.dart';
import '../../domain/entities/prayer_times.dart';

class CachedPrayerTimes {
  const CachedPrayerTimes({
    required this.times,
    required this.dateKey,
    required this.latitude,
    required this.longitude,
  });

  final PrayerTimes times;
  final String dateKey;
  final double latitude;
  final double longitude;

  bool matchesLocation(double latitude, double longitude) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = this.latitude * 3.141592653589793 / 180;
    final lat2 = latitude * 3.141592653589793 / 180;
    final deltaLat = (latitude - this.latitude) * 3.141592653589793 / 180;
    final deltaLon = (longitude - this.longitude) * 3.141592653589793 / 180;
    final sinLat = math.sin(deltaLat / 2);
    final sinLon = math.sin(deltaLon / 2);
    final a = sinLat * sinLat +
        math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
    final bounded = a.clamp(0.0, 1.0);
    final distance = earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(bounded), math.sqrt(1 - bounded));
    return distance <= 1000;
  }
}

class PrayerTimesCache {
  static const _storageKey = 'prayer_times_daily_cache_v1';

  Future<CachedPrayerTimes?> read(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final dateKey = _dateKey(date);
      final alarms = (json['alarms'] as List<dynamic>? ?? const [])
          .map((item) {
            final alarm = item as Map<String, dynamic>;
            return PrayerAlarmTime(
              prayerId: alarm['prayer'] as String,
              at: DateTime.parse(alarm['at'] as String),
            );
          })
          .toList(growable: false);
      final latitude = (json['latitude'] as num).toDouble();
      final longitude = (json['longitude'] as num).toDouble();
      if (!latitude.isFinite || !longitude.isFinite ||
          latitude < -90 || latitude > 90 ||
          longitude < -180 || longitude > 180) {
        return null;
      }
      final dayAlarms = alarms.where((alarm) =>
          alarm.at.year == date.year &&
          alarm.at.month == date.month &&
          alarm.at.day == date.day).toList(growable: false);
      DateTime prayerTime(String key) {
        final matchingAlarm = dayAlarms.where((alarm) => alarm.prayerId == key);
        if (matchingAlarm.isNotEmpty) return matchingAlarm.first.at;
        if (json['date'] != dateKey) {
          throw const FormatException('No cached prayer times for this date');
        }
        return DateTime.parse('${dateKey}T${json[key] as String}:00');
      }
      if (json['date'] != dateKey && dayAlarms.length < 5) return null;
      return CachedPrayerTimes(
        times: PrayerTimes(
          fajr: prayerTime('fajr'),
          dhuhr: prayerTime('dhuhr'),
          asr: prayerTime('asr'),
          maghrib: prayerTime('maghrib'),
          isha: prayerTime('isha'),
          alarmTimes: alarms,
        ),
        dateKey: dateKey,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    DateTime date,
    double latitude,
    double longitude,
    PrayerTimes times,
  ) async {
    if (!latitude.isFinite || !longitude.isFinite ||
        latitude < -90 || latitude > 90 ||
        longitude < -180 || longitude > 180) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final value = jsonEncode({
      'date': _dateKey(date),
      'latitude': latitude,
      'longitude': longitude,
      'fajr': _time(times.fajr),
      'dhuhr': _time(times.dhuhr),
      'asr': _time(times.asr),
      'maghrib': _time(times.maghrib),
      'isha': _time(times.isha),
      'alarms': times.alarmTimes
          .map((alarm) => {
                'prayer': alarm.prayerId,
                'at': alarm.at.toIso8601String(),
              })
          .toList(growable: false),
    });
    await prefs.setString(_storageKey, value);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

