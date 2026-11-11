import '../../../prayer_times/domain/entities/prayer_times.dart';

/// A stable identifier for the prayer period currently in progress.
String? prayerWirdPeriodKey(PrayerTimes? times, DateTime now) {
  if (times == null) return null;
  final prayers = <(String, DateTime)>[
    ('fajr', times.fajr),
    ('dhuhr', times.dhuhr),
    ('asr', times.asr),
    ('maghrib', times.maghrib),
    ('isha', times.isha),
  ];
  for (var index = prayers.length - 1; index >= 0; index--) {
    final prayer = prayers[index];
    final at = DateTime(now.year, now.month, now.day, prayer.$2.hour, prayer.$2.minute);
    if (!at.isAfter(now)) return '${_dateKey(now)}:${prayer.$1}';
  }
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  return '${_dateKey(yesterday)}:isha';
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
