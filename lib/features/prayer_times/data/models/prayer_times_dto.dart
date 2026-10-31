import '../../domain/entities/prayer_times.dart';
import '../../domain/entities/prayer_alarm_time.dart';

class PrayerTimesDto {
  const PrayerTimesDto({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.alarmTimes = const [],
  });

  final String fajr, dhuhr, asr, maghrib, isha;
  final List<PrayerAlarmTime> alarmTimes;

  factory PrayerTimesDto.fromCalendar(Map<String, dynamic> json, DateTime date) {
    final entries = json['data'] as List;
    final day = entries.firstWhere((entry) => int.parse(entry['date']['gregorian']['day']) == date.day);
    final timings = day['timings'] as Map<String, dynamic>;
    String time(String key) => (timings[key] as String).split(' ').first;
    return PrayerTimesDto(
      fajr: time('Fajr'),
      dhuhr: time('Dhuhr'),
      asr: time('Asr'),
      maghrib: time('Maghrib'),
      isha: time('Isha'),
      alarmTimes: _readAlarmTimes(entries, date),
    );
  }

  PrayerTimesDto addAlarmTimes(Iterable<PrayerAlarmTime> additional) =>
      PrayerTimesDto(
        fajr: fajr,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        alarmTimes: [...alarmTimes, ...additional],
      );

  static List<PrayerAlarmTime> _readAlarmTimes(
    List<dynamic> entries,
    DateTime month,
  ) {
    const prayerKeys = {
      'Fajr': 'fajr',
      'Dhuhr': 'dhuhr',
      'Asr': 'asr',
      'Maghrib': 'maghrib',
      'Isha': 'isha',
    };
    final alarms = <PrayerAlarmTime>[];
    for (final entry in entries) {
      final dayInfo = (entry as Map<String, dynamic>)['date']['gregorian'];
      final day = int.parse(dayInfo['day'] as String);
      final date = DateTime(month.year, month.month, day);
      final timings = entry['timings'] as Map<String, dynamic>;
      for (final prayer in prayerKeys.entries) {
        final value = (timings[prayer.key] as String).split(' ').first;
        final parts = value.split(':');
        alarms.add(PrayerAlarmTime(
          prayerId: prayer.value,
          at: DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          ),
        ));
      }
    }
    return alarms;
  }

  PrayerTimes toEntity(DateTime date) {
    DateTime at(String value) {
      final parts = value.split(':');
      return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
    }
    return PrayerTimes(
      fajr: at(fajr),
      dhuhr: at(dhuhr),
      asr: at(asr),
      maghrib: at(maghrib),
      isha: at(isha),
      alarmTimes: alarmTimes,
    );
  }
}
