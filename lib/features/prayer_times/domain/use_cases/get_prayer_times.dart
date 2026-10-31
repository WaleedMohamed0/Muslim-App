import '../entities/prayer_times.dart';
import '../repositories/prayer_times_repository.dart';

class GetPrayerTimes {
  const GetPrayerTimes(this.repository);
  final PrayerTimesRepository repository;
  Future<PrayerTimes> call(DateTime date) => repository.getForCurrentLocation(date);
}
