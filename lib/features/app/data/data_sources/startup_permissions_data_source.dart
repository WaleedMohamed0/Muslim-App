import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';

class StartupPermissionsDataSource {
  static const _notificationDecisionKey =
      'first_launch_notifications_decided';
  static const _locationDecisionKey = 'first_launch_location_decided';

  Future<bool> notificationDecisionMade() async =>
      (await SharedPreferences.getInstance()).getBool(_notificationDecisionKey) ==
      true;

  Future<void> markNotificationDecisionMade() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationDecisionKey, true);
  }

  Future<bool> notificationsGranted() async =>
      (await PrayerAdhanService.instance.permissionStatus())['notifications'] ==
      true;

  Future<void> requestNotifications() =>
      PrayerAdhanService.instance.requestNotificationPermission();

  Future<bool> locationDecisionMade() async =>
      (await SharedPreferences.getInstance()).getBool(_locationDecisionKey) ==
      true;

  Future<bool> locationPermissionAlreadyGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever ||
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> markLocationDecisionMade() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_locationDecisionKey, true);
  }

  Future<void> requestLocation() async {
    await Geolocator.requestPermission();
  }
}
