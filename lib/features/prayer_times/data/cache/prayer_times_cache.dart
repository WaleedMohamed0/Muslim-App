import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer_alarm_time.dart';
import '../../domain/entities/prayer_times.dart';

class CachedPrayerTimes {
  const CachedPrayerTimes({
    required this.times,
    required this.dateKey,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  final PrayerTimes times;
  final String dateKey;
  final String? region;
  final double latitude;
  final double longitude;

  bool matchesLocation(double latitude, double longitude) {
    // Coordinates are normalized before writing so minor GPS jitter reuses
    // the same daily calculation cache.
    return this.latitude == latitude && this.longitude == longitude;
  }

  bool matchesCalculation(String calculationKey, String? timezone) =>
      region == calculationKey && times.timezone == timezone;

  bool coversThrough(DateTime date) => times.alarmTimes.any(
    (alarm) =>
        alarm.at.year == date.year &&
        alarm.at.month == date.month &&
        alarm.at.day == date.day &&
        alarm.prayerId == 'isha',
  );
}

class PrayerTimesCache {
  static const _storageKey = 'prayer_times_daily_cache_v1';
  static bool _timezonesInitialized = false;

  Future<CachedPrayerTimes?> read(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final dateKey = _dateKey(date);
      final timezone = json['timezone'] as String?;
      tz.Location? zone;
      if (timezone != null && timezone.isNotEmpty) {
        if (!_timezonesInitialized) {
          tz_data.initializeTimeZones();
          _timezonesInitialized = true;
        }
        try {
          zone = tz.getLocation(timezone);
        } catch (_) {
          zone = null;
        }
      }
      final alarms = (json['alarms'] as List<dynamic>? ?? const [])
          .map((item) {
            final alarm = item as Map<String, dynamic>;
            final value = alarm['at'] as String;
            final wallTime = DateTime.parse(value.substring(0, 16));
            return PrayerAlarmTime(
              prayerId: alarm['prayer'] as String,
              at:
                  zone == null
                      ? wallTime
                      : tz.TZDateTime(
                        zone,
                        wallTime.year,
                        wallTime.month,
                        wallTime.day,
                        wallTime.hour,
                        wallTime.minute,
                      ),
            );
          })
          .toList(growable: false);
      final latitude = (json['latitude'] as num).toDouble();
      final longitude = (json['longitude'] as num).toDouble();
      if (!latitude.isFinite ||
          !longitude.isFinite ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        return null;
      }
      final dayAlarms = alarms
          .where(
            (alarm) =>
                alarm.at.year == date.year &&
                alarm.at.month == date.month &&
                alarm.at.day == date.day,
          )
          .toList(growable: false);
      DateTime prayerTime(String key) {
        final matchingAlarm = dayAlarms.where((alarm) => alarm.prayerId == key);
        if (matchingAlarm.isNotEmpty) return matchingAlarm.first.at;
        if (json['date'] != dateKey) {
          throw const FormatException('No cached prayer times for this date');
        }
        final time = DateTime.parse('${dateKey}T${json[key] as String}:00');
        return zone == null
            ? time
            : tz.TZDateTime(
              zone,
              time.year,
              time.month,
              time.day,
              time.hour,
              time.minute,
            );
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
          timezone: timezone,
        ),
        dateKey: dateKey,
        region: json['region'] as String?,
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
    PrayerTimes times, {
    String? region,
  }) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final value = jsonEncode({
      'date': _dateKey(date),
      'latitude': latitude,
      'longitude': longitude,
      'region': region,
      'timezone': times.timezone,
      'fajr': _time(times.fajr),
      'dhuhr': _time(times.dhuhr),
      'asr': _time(times.asr),
      'maghrib': _time(times.maghrib),
      'isha': _time(times.isha),
      'alarms': times.alarmTimes
          .map((alarm) => {'prayer': alarm.prayerId, 'at': _dateTime(alarm.at)})
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

  String _dateTime(DateTime date) => '${_dateKey(date)}T${_time(date)}';
}
