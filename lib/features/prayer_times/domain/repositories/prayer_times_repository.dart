import '../entities/prayer_times.dart';

abstract interface class PrayerTimesRepository {
  Future<void> verifyLocationAccess();
  Future<PrayerTimes?> getCached(DateTime date);
  Future<PrayerTimes> getForCurrentLocation(DateTime date, {bool forceRefresh = false});
}
