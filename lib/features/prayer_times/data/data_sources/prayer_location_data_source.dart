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
    final response = await _fetchCalendar(position.latitude, position.longitude, date);
    var result = PrayerTimesDto.fromCalendar(response, date);

    final nextMonth = DateTime(date.year, date.month + 1, 1);
    try {
      final nextResponse = await _fetchCalendar(
        position.latitude,
        position.longitude,
        nextMonth,
      );
      result = result.addAlarmTimes(
        PrayerTimesDto.fromCalendar(nextResponse, nextMonth).alarmTimes,
      );
    } catch (_) {
      // Today's times remain usable if the optional next-month request fails.
    }
    return result;
  }

  Future<Map<String, dynamic>> _fetchCalendar(
    double latitude,
    double longitude,
    DateTime month,
  ) async {
    final response = await DioHelper.getData(
      endPoint: 'calendar',
      query: {
        'latitude': latitude,
        'longitude': longitude,
        'month': month.month,
        'year': month.year,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
