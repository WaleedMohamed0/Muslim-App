import '../entities/prayer_times.dart';
import '../repositories/prayer_times_repository.dart';

class GetPrayerTimes {
  const GetPrayerTimes(this.repository);
  final PrayerTimesRepository repository;
  Future<PrayerTimes?> getCached(DateTime date) => repository.getCached(date);
  Future<PrayerTimes> call(DateTime date, {bool forceRefresh = false}) =>
      repository.getForCurrentLocation(date, forceRefresh: forceRefresh);
}
