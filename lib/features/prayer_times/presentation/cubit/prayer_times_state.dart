import '../../domain/entities/prayer_times.dart';

class PrayerDisplayTime {
  const PrayerDisplayTime({required this.name, required this.time, required this.period});
  final String name;
  final String time;
  final String period;
}

enum PrayerTimesStatus { initial, loading, loaded, failure }

enum PrayerTimesErrorType {
  network,
  locationServicesDisabled,
  locationPermissionDenied,
  locationPermissionPermanentlyDenied,
  locationUnavailable,
  general,
}

class PrayerTimesState {
  const PrayerTimesState({
    this.error,
    this.errorType,
    this.prayerTimes,
    this.status = PrayerTimesStatus.initial,
    this.displayTimes = const [],
  });
  final String? error;
  final PrayerTimesErrorType? errorType;
  final PrayerTimes? prayerTimes;
  final PrayerTimesStatus status;
  final List<PrayerDisplayTime> displayTimes;
}
