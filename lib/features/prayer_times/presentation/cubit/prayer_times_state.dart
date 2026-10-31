import '../../domain/entities/prayer_times.dart';

class PrayerDisplayTime {
  const PrayerDisplayTime({required this.name, required this.time, required this.period});
  final String name;
  final String time;
  final String period;
}

enum PrayerTimesStatus { initial, loading, loaded, failure }

class PrayerTimesState {
  const PrayerTimesState({this.error, this.prayerTimes, this.status = PrayerTimesStatus.initial, this.azanPrayer, this.displayTimes = const []});
  final String? error;
  final PrayerTimes? prayerTimes;
  final PrayerTimesStatus status;
  final String? azanPrayer;
  final List<PrayerDisplayTime> displayTimes;
  bool get isAzanTime => azanPrayer != null;
}
