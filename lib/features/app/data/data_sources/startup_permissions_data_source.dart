import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:muslim/features/app/data/services/kahf_reminder_service.dart';

class StartupPermissionsDataSource {
  static const _notificationDecisionKey =
      'first_launch_notifications_decided';
  static const _locationDecisionKey = 'first_launch_location_decided';
  static const _exactAlarmDecisionKey = 'first_launch_exact_alarm_decided';

  Future<bool> notificationDecisionMade() async =>
      (await SharedPreferences.getInstance()).getBool(_notificationDecisionKey) ==
      true;

  Future<void> markNotificationDecisionMade() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationDecisionKey, true);
  }

  Future<bool> notificationsGranted() =>
      KahfReminderService.instance.notificationsGranted();

  Future<void> requestNotifications() async {
    await KahfReminderService.instance.requestPermission();
    // Preserve the existing Android notification permission path used by
    // prayer and Adhan notifications.
    if (Platform.isAndroid) {
      await PrayerAdhanService.instance.requestNotificationPermission();
    }
  }

  Future<bool> exactAlarmDecisionMade() async =>
      (await SharedPreferences.getInstance()).getBool(_exactAlarmDecisionKey) ==
      true;

  Future<bool> exactAlarmsGranted() async {
    if (!Platform.isAndroid) return true;
    return (await PrayerAdhanService.instance.permissionStatus())['exactAlarms'] ??
        true;
  }

  Future<void> markExactAlarmDecisionMade() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_exactAlarmDecisionKey, true);
  }

  Future<void> requestExactAlarms() async {
    if (Platform.isAndroid) {
      await PrayerAdhanService.instance.requestExactAlarmPermission();
    }
  }

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
