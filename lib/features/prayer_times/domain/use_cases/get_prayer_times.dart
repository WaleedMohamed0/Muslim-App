import '../entities/prayer_times.dart';
import '../repositories/prayer_times_repository.dart';

class GetPrayerTimes {
  const GetPrayerTimes(this.repository);
  final PrayerTimesRepository repository;
  Future<void> verifyLocationAccess() => repository.verifyLocationAccess();
  Future<PrayerTimes?> getCached(DateTime date) => repository.getCached(date);
  Future<String?> getCurrentCity({bool forceRefresh = false}) =>
      repository.getCurrentCity(forceRefresh: forceRefresh);
  Future<PrayerTimes> call(DateTime date, {bool forceRefresh = false}) =>
      repository.getForCurrentLocation(date, forceRefresh: forceRefresh);
}
