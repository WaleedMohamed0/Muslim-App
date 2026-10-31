import '../entities/prayer_times.dart';

abstract interface class PrayerTimesRepository {
  Future<PrayerTimes> getForCurrentLocation(DateTime date);
}
