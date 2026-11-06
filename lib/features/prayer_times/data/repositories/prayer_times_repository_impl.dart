import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../data_sources/prayer_location_data_source.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl(this.dataSource);
  final PrayerLocationDataSource dataSource;

  @override
  Future<void> verifyLocationAccess() => dataSource.verifyLocationAccess();

  @override
  Future<PrayerTimes?> getCached(DateTime date) => dataSource.getCached(date);

  @override
  Future<PrayerTimes> getForCurrentLocation(
    DateTime date, {
    bool forceRefresh = false,
  }) async =>
      (await dataSource.fetch(date, forceRefresh: forceRefresh)).toEntity(date);
}
