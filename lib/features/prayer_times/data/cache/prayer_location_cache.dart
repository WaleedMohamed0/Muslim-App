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

  static const _cityKey = 'prayer_location_city_v2';
  static const _cityLatitudeKey = 'prayer_location_city_latitude_v2';
  static const _cityLongitudeKey = 'prayer_location_city_longitude_v2';

  Future<String?> readCity(CachedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getDouble(_cityLatitudeKey) != location.latitude ||
        prefs.getDouble(_cityLongitudeKey) != location.longitude) {
      return null;
    }
    final city = prefs.getString(_cityKey)?.trim();
    return city == null || city.isEmpty ? null : city;
  }

  Future<void> writeCity(CachedLocation location, String city) async {
    final value = city.trim();
    if (value.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, value);
    await prefs.setDouble(_cityLatitudeKey, location.latitude);
    await prefs.setDouble(_cityLongitudeKey, location.longitude);
  }
}
