import 'prayer_alarm_time.dart';

class PrayerTimes {
  const PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.alarmTimes = const [],
  });

  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final List<PrayerAlarmTime> alarmTimes;
}
