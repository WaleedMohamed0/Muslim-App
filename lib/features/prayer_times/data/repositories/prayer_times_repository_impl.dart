import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../data_sources/prayer_location_data_source.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl(this.dataSource);
  final PrayerLocationDataSource dataSource;

  @override
  Future<PrayerTimes> getForCurrentLocation(DateTime date) async =>
      (await dataSource.fetch(date)).toEntity(date);
}
