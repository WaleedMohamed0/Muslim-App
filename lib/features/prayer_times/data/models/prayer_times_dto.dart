import '../../domain/entities/prayer_times.dart';

class PrayerTimesDto {
  const PrayerTimesDto({required this.fajr, required this.dhuhr, required this.asr, required this.maghrib, required this.isha});
  final String fajr, dhuhr, asr, maghrib, isha;

  factory PrayerTimesDto.fromCalendar(Map<String, dynamic> json, DateTime date) {
    final entries = json['data'] as List;
    final day = entries.firstWhere((entry) => int.parse(entry['date']['gregorian']['day']) == date.day);
    final timings = day['timings'] as Map<String, dynamic>;
    String time(String key) => (timings[key] as String).split(' ').first;
    return PrayerTimesDto(fajr: time('Fajr'), dhuhr: time('Dhuhr'), asr: time('Asr'), maghrib: time('Maghrib'), isha: time('Isha'));
  }

  PrayerTimes toEntity(DateTime date) {
    DateTime at(String value) {
      final parts = value.split(':');
      return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
    }
    return PrayerTimes(fajr: at(fajr), dhuhr: at(dhuhr), asr: at(asr), maghrib: at(maghrib), isha: at(isha));
  }
}
