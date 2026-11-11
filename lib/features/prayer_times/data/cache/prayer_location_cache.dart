import 'package:shared_preferences/shared_preferences.dart';

class CachedLocation {
  const CachedLocation(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  bool get isValid => latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 && latitude <= 90 &&
      longitude >= -180 && longitude <= 180;
}

class PrayerLocationCache {
  static const _latitudeKey = 'prayer_location_latitude_v1';
  static const _longitudeKey = 'prayer_location_longitude_v1';

  Future<CachedLocation?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) return null;
    final location = CachedLocation(latitude, longitude);
    return location.isValid ? location : null;
  }

  Future<void> write(double latitude, double longitude) async {
    final location = CachedLocation(latitude, longitude);
    if (!location.isValid) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, latitude);
    await prefs.setDouble(_longitudeKey, longitude);
  }
}
