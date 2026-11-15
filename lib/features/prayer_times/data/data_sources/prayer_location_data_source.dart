import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/prayer_times.dart';
import '../../domain/entities/prayer_alarm_time.dart';
import '../cache/prayer_times_cache.dart';
import '../cache/prayer_location_cache.dart';

class PrayerLocationDataSource {
  PrayerLocationDataSource({
    PrayerTimesCache? cache,
    PrayerLocationCache? locationCache,
  }) : _cache = cache ?? PrayerTimesCache(),
       _locationCache = locationCache ?? PrayerLocationCache();

  final PrayerTimesCache _cache;
  final PrayerLocationCache _locationCache;
  final Geocoding _geocoding = Geocoding(locale: const Locale('ar'));
  static bool _timezonesInitialized = false;

  Future<String?> getCurrentCity({bool forceRefresh = false}) async {
    try {
      final location = await _locationCache.read();
      if (location == null) return null;
      final cachedRegion = await _locationCache.readRegionForLocation(location);
      if (!forceRefresh && cachedRegion != null) return cachedRegion.city;
      if (forceRefresh && cachedRegion != null) {
        try {
          final region = await _resolveRegion(location);
          if (region == null) return cachedRegion.city;
          await _locationCache.writeCity(location, region.city);
          await _locationCache.writeRegion(
            region: region.region,
            city: region.city,
            country: region.country,
            countryCode: region.countryCode,
            reference: region.reference,
          );
          return region.city;
        } catch (_) {
          return cachedRegion.city;
        }
      }
      if (!forceRefresh) {
        final cachedCity = await _locationCache.readCity(location);
        if (cachedCity != null) return cachedCity;
        // A location can be available before any city metadata has been
        // stored (for example, on the first launch). Resolve it here instead
        // of leaving the UI on its "city unavailable" fallback indefinitely.
        final region = await _resolveRegion(location);
        if (region == null) return null;
        await _locationCache.writeCity(location, region.city);
        await _locationCache.writeRegion(
          region: region.region,
          city: region.city,
          country: region.country,
          countryCode: region.countryCode,
          reference: region.reference,
        );
        return region.city;
      }
      final region = await _resolveRegion(location);
      if (region == null) return null;
      final city = region.city;
      await _locationCache.writeCity(location, city);
      await _locationCache.writeRegion(
        region: region.region,
        city: region.city,
        country: region.country,
        countryCode: region.countryCode,
        reference: region.reference,
      );
      return city;
    } catch (_) {
      return null;
    }
  }

  Future<PrayerTimes?> getCached(DateTime date) async {
    CachedPrayerTimes? cached;
    try {
      cached = await _cache.read(date);
    } catch (_) {
      return null;
    }
    if (cached == null) return null;
    // Migrate coordinates persisted alongside older daily schedules into the
    // durable standalone location cache without consulting device services.
    try {
      if (await _locationCache.read() == null) {
        await _locationCache.write(cached.latitude, cached.longitude);
      }
    } catch (_) {
      // The cached schedule remains usable if this optional migration fails.
    }
    return cached.times;
  }

  /// Refreshes Android's current service and permission status without using
  /// a stale cached grant or requesting any network data.
  Future<void> verifyLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const PrayerLocationException(
        PrayerLocationFailure.servicesDisabled,
      );
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw const PrayerLocationException(
        PrayerLocationFailure.permissionPermanentlyDenied,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const PrayerLocationException(
        PrayerLocationFailure.permissionDenied,
      );
    }
  }

  Future<PrayerTimes> fetch(DateTime date, {bool forceRefresh = false}) async {
    final deviceLocation = await _readDeviceLocation(
      requestPermission: forceRefresh,
    );
    try {
      await _locationCache.write(
        deviceLocation.latitude,
        deviceLocation.longitude,
      );
    } catch (_) {
      // Calculation does not depend on the optional location cache.
    }
    final zone = await _readTimezone();
    final timezone = zone?.name;
    final regionalData = await _regionalData(
      deviceLocation,
      forceRefresh: forceRefresh,
    );
    // The previous API received the raw GPS fix. Use that same coordinate for
    // local calculations; geocoded regional centroids can shift prayer times.
    final calculationLocation = deviceLocation;
    final cacheLatitude = _cacheCoordinate(calculationLocation.latitude);
    final cacheLongitude = _cacheCoordinate(calculationLocation.longitude);
    final calculation = _calculationForCountry(regionalData?.countryCode);
    final nowAtLocation =
        zone == null ? date : tz.TZDateTime.from(DateTime.now().toUtc(), zone);
    final calculationDate = DateTime(
      nowAtLocation.year,
      nowAtLocation.month,
      nowAtLocation.day,
    );
    CachedPrayerTimes? cached;
    try {
      cached = await _cache.read(calculationDate);
    } catch (_) {
      // Calculate locally if the optional cache is unavailable.
    }
    if (cached != null &&
        cached.matchesLocation(cacheLatitude, cacheLongitude) &&
        cached.matchesCalculation(calculation.cacheKey, timezone) &&
        cached.coversThrough(
          DateTime(calculationDate.year, calculationDate.month + 2, 0),
        )) {
      return cached.times;
    }
    final coordinates = adhan.Coordinates(
      calculationLocation.latitude,
      calculationLocation.longitude,
    );
    final parameters =
        calculation.parameters
          ..madhab = adhan.Madhab.shafi
          ..highLatitudeRule =
              calculation.parameters.ishaAngle == null
                  ? adhan.HighLatitudeRule.middle_of_the_night
                  : adhan.HighLatitudeRule.twilight_angle;
    // AlAdhan's default calendar responses do not include the +1 minute
    // Dhuhr adjustment built into several adhan package presets. Keep larger
    // method-specific adjustments (such as Turkey's) intact.
    if (parameters.methodAdjustments.dhuhr == 1) {
      parameters.methodAdjustments.dhuhr = 0;
    }
    final dayCount =
        DateTime(calculationDate.year, calculationDate.month + 2, 0)
            .difference(
              DateTime(
                calculationDate.year,
                calculationDate.month,
                calculationDate.day,
              ),
            )
            .inDays;
    DateTime calculate(DateTime day, adhan.Prayer prayer) {
      final components = adhan.DateComponents(day.year, day.month, day.day);
      final times =
          zone == null
              ? adhan.PrayerTimes(coordinates, components, parameters)
              : adhan.PrayerTimes.utc(coordinates, components, parameters);
      final instant = switch (prayer) {
        adhan.Prayer.fajr => times.fajr,
        adhan.Prayer.sunrise => times.sunrise,
        adhan.Prayer.dhuhr => times.dhuhr,
        adhan.Prayer.asr => times.asr,
        adhan.Prayer.maghrib => times.maghrib,
        adhan.Prayer.isha => times.isha,
        _ => throw ArgumentError.value(prayer, 'prayer'),
      };
      return zone == null ? instant : tz.TZDateTime.from(instant, zone);
    }

    const prayers = <(String, adhan.Prayer)>[
      ('fajr', adhan.Prayer.fajr),
      ('dhuhr', adhan.Prayer.dhuhr),
      ('asr', adhan.Prayer.asr),
      ('maghrib', adhan.Prayer.maghrib),
      ('isha', adhan.Prayer.isha),
    ];
    final alarms = <PrayerAlarmTime>[];
    for (var offset = 0; offset <= dayCount; offset++) {
      final day = DateTime(
        calculationDate.year,
        calculationDate.month,
        calculationDate.day + offset,
      );
      for (final (id, prayer) in prayers) {
        alarms.add(PrayerAlarmTime(prayerId: id, at: calculate(day, prayer)));
      }
    }
    final result = PrayerTimes(
      sunrise: calculate(calculationDate, adhan.Prayer.sunrise),
      fajr: calculate(calculationDate, adhan.Prayer.fajr),
      dhuhr: calculate(calculationDate, adhan.Prayer.dhuhr),
      asr: calculate(calculationDate, adhan.Prayer.asr),
      maghrib: calculate(calculationDate, adhan.Prayer.maghrib),
      isha: calculate(calculationDate, adhan.Prayer.isha),
      alarmTimes: alarms,
      timezone: timezone,
    );
    try {
      await _cache.write(
        calculationDate,
        cacheLatitude,
        cacheLongitude,
        result,
        region: calculation.cacheKey,
      );
    } catch (_) {
      // Prayer times remain usable even if the device cannot persist the cache.
    }
    return result;
  }

  Future<CachedRegion?> _regionalData(
    CachedLocation location, {
    required bool forceRefresh,
  }) async {
    CachedRegion? cached;
    try {
      cached = await _locationCache.readRegionForLocation(location);
    } catch (_) {
      // Continue with the global default if location metadata is unavailable.
    }
    if (cached?.countryCode != null && cached!.countryCode!.isNotEmpty) {
      if (!forceRefresh) return cached;
    }
    if (!forceRefresh) return cached;
    try {
      final region = await _resolveRegion(
        location,
      ).timeout(const Duration(seconds: 2));
      if (region == null) return cached;
      await _locationCache.writeCity(location, region.city);
      await _locationCache.writeRegion(
        region: region.region,
        city: region.city,
        country: region.country,
        countryCode: region.countryCode,
        reference: region.reference,
      );
      return region;
    } catch (_) {
      return cached;
    }
  }

  Future<tz.Location?> _readTimezone() async {
    try {
      if (!_timezonesInitialized) {
        tz_data.initializeTimeZones();
        _timezonesInitialized = true;
      }
      final info = await FlutterTimezone.getLocalTimezone();
      return tz.getLocation(info.identifier);
    } catch (_) {
      return null;
    }
  }

  _PrayerCalculation _calculationForCountry(String? countryCode) {
    final code = countryCode?.toUpperCase();
    final method = switch (code) {
      'EG' => adhan.CalculationMethod.egyptian,
      'US' || 'CA' => adhan.CalculationMethod.north_america,
      'SA' => adhan.CalculationMethod.umm_al_qura,
      'PK' || 'IN' || 'BD' || 'AF' => adhan.CalculationMethod.karachi,
      'TR' => adhan.CalculationMethod.turkey,
      'IR' => adhan.CalculationMethod.tehran,
      'KW' => adhan.CalculationMethod.kuwait,
      'QA' => adhan.CalculationMethod.qatar,
      'AE' => adhan.CalculationMethod.dubai,
      'SG' => adhan.CalculationMethod.singapore,
      // These authorities use the same angles and Dhuhr convention as the
      // Singapore preset in the available adhan package.
      'ID' || 'AU' || 'MY' || 'NZ' => adhan.CalculationMethod.singapore,
      _ => adhan.CalculationMethod.muslim_world_league,
    };
    final params = method.getParameters();
    return _PrayerCalculation(method.name, params);
  }

  double _cacheCoordinate(double value) =>
      (value * 10000).roundToDouble() / 10000;

  Future<CachedRegion?> _resolveRegion(CachedLocation location) async {
    final placemarks = await _geocoding.placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    if (placemarks.isEmpty) return null;
    final place = placemarks.first;
    String? clean(String? value) {
      final result = value?.trim();
      return result == null || result.isEmpty ? null : result;
    }

    final country = clean(place.country);
    final countryCode = clean(place.isoCountryCode)?.toUpperCase();
    final governorate = clean(place.administrativeArea);
    final displayLocation = [
      governorate,
      clean(place.locality),
      clean(place.subAdministrativeArea),
      clean(place.subLocality)
    ].whereType<String>().toSet().join('، ');
    // Keep the existing regional label, with city-level names as a fallback.
    final regionName =
        governorate ??
        clean(place.subAdministrativeArea) ??
        clean(place.locality);
    if (country == null) {
      return null;
    }
    final displayName = displayLocation.isEmpty ? country : displayLocation;
    final regionValue = regionName ?? country;

    final region = [
      regionValue,
      country,
    ].whereType<String>().map((part) => part.toLowerCase()).toSet().join('|');
    return CachedRegion(
      region: region,
      city: displayName,
      country: country,
      countryCode: countryCode,
      reference: location,
    );
  }

  Future<CachedLocation> _readDeviceLocation({
    required bool requestPermission,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const PrayerLocationException(
          PrayerLocationFailure.servicesDisabled,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (requestPermission && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const PrayerLocationException(
          PrayerLocationFailure.permissionPermanentlyDenied,
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        throw const PrayerLocationException(
          PrayerLocationFailure.permissionDenied,
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final location = CachedLocation(position.latitude, position.longitude);
      if (!location.isValid) {
        throw const PrayerLocationException(PrayerLocationFailure.unavailable);
      }
      return location;
    } on LocationServiceDisabledException {
      throw const PrayerLocationException(
        PrayerLocationFailure.servicesDisabled,
      );
    } on PermissionDeniedException {
      final currentPermission = await Geolocator.checkPermission();
      throw PrayerLocationException(
        currentPermission == LocationPermission.deniedForever
            ? PrayerLocationFailure.permissionPermanentlyDenied
            : PrayerLocationFailure.permissionDenied,
      );
    } on PrayerLocationException {
      rethrow;
    } catch (_) {
      throw const PrayerLocationException(PrayerLocationFailure.unavailable);
    }
  }
}

class _PrayerCalculation {
  const _PrayerCalculation(this.cacheKey, this.parameters);

  final String cacheKey;
  final adhan.CalculationParameters parameters;
}

enum PrayerLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class PrayerLocationException implements Exception {
  const PrayerLocationException(this.failure);

  final PrayerLocationFailure failure;
}
