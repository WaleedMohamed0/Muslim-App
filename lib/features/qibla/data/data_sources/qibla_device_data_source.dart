import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaDeviceDataSource {
  static const _declinationChannel = MethodChannel('com.muslim/qibla_compass');

  Future<LocationPermission> checkLocationPermission() =>
      Geolocator.checkPermission();

  Future<LocationPermission> requestLocationPermission() =>
      Geolocator.requestPermission();

  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );

  Stream<CompassEvent>? get compassEvents => FlutterCompass.events;

  Future<double?> magneticDeclination(Position position) async {
    try {
      return await _declinationChannel
          .invokeMethod<double>('magneticDeclination', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'altitude': position.altitude,
          });
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
