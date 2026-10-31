import 'package:geolocator/geolocator.dart';

import '../../../../core/network/dio_client.dart';
import '../models/prayer_times_dto.dart';

class PrayerLocationDataSource {
  Future<PrayerTimesDto> fetch(DateTime date) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    final response = await DioHelper.getData(endPoint: 'calendar', query: {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'month': date.month,
      'year': date.year,
    });
    return PrayerTimesDto.fromCalendar(response.data, date);
  }
}
