import 'package:shared_preferences/shared_preferences.dart';

class CachedLocation {
  const CachedLocation(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
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

  static const _cityKey = 'prayer_location_city_v3';
  static const _countryKey = 'prayer_location_country_v1';
  static const _countryCodeKey = 'prayer_location_country_code_v1';
  static const _regionKey = 'prayer_location_region_v1';
  static const _referenceLatitudeKey = 'prayer_location_reference_latitude_v1';
  static const _referenceLongitudeKey =
      'prayer_location_reference_longitude_v1';
  static const _cityLatitudeKey = 'prayer_location_city_latitude_v3';
  static const _cityLongitudeKey = 'prayer_location_city_longitude_v3';

  Future<String?> readCity(CachedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getDouble(_cityLatitudeKey) != _coordinate(location.latitude) ||
        prefs.getDouble(_cityLongitudeKey) != _coordinate(location.longitude)) {
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
    await prefs.setDouble(_cityLatitudeKey, _coordinate(location.latitude));
    await prefs.setDouble(_cityLongitudeKey, _coordinate(location.longitude));
  }

  Future<CachedRegion?> readRegionForLocation(CachedLocation location) async {
    final city = await readCity(location);
    if (city == null) return null;
    return readRegion();
  }

  Future<CachedRegion?> readRegion() async {
    final prefs = await SharedPreferences.getInstance();
    final region = prefs.getString(_regionKey)?.trim();
    final city = prefs.getString(_cityKey)?.trim();
    final country = prefs.getString(_countryKey)?.trim();
    final countryCode = prefs.getString(_countryCodeKey)?.trim();
    final latitude = prefs.getDouble(_referenceLatitudeKey);
    final longitude = prefs.getDouble(_referenceLongitudeKey);
    if (region == null ||
        region.isEmpty ||
        city == null ||
        city.isEmpty ||
        country == null ||
        country.isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }
    final reference = CachedLocation(latitude, longitude);
    return reference.isValid
        ? CachedRegion(
          region: region,
          city: city,
          country: country,
          countryCode: countryCode,
          reference: reference,
        )
        : null;
  }

  Future<void> writeRegion({
    required String region,
    required String city,
    required String country,
    String? countryCode,
    required CachedLocation reference,
  }) async {
    if (region.trim().isEmpty ||
        city.trim().isEmpty ||
        country.trim().isEmpty ||
        !reference.isValid) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, region.trim());
    await prefs.setString(_cityKey, city.trim());
    await prefs.setString(_countryKey, country.trim());
    if (countryCode == null || countryCode.trim().isEmpty) {
      await prefs.remove(_countryCodeKey);
    } else {
      await prefs.setString(_countryCodeKey, countryCode.trim().toUpperCase());
    }
    await prefs.setDouble(_referenceLatitudeKey, reference.latitude);
    await prefs.setDouble(_referenceLongitudeKey, reference.longitude);
  }

  double _coordinate(double value) => (value * 10000).roundToDouble() / 10000;
}

class CachedRegion {
  const CachedRegion({
    required this.region,
    required this.city,
    required this.country,
    this.countryCode,
    required this.reference,
  });

  final String region;
  final String city;
  final String country;
  final String? countryCode;
  final CachedLocation reference;
}
