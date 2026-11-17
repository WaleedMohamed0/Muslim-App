import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../prayer_times/domain/entities/prayer_times.dart';

/// Schedules the Flutter-owned reminders independently from native Adhan alarms.
class PostPrayerAdhkarReminderService {
  PostPrayerAdhkarReminderService._();

  static final instance = PostPrayerAdhkarReminderService._();
  static const route = 'post_prayer_adhkar';
  static const _idsKey = 'post_prayer_adhkar_scheduled_ids_v1';
  static const _completedPeriodsKey =
      'post_prayer_adhkar_completed_periods_v1';
  static const _idBase = 62000000;
  static const _channelId = 'post_prayer_adhkar_reminders';
  static const _prayerIds = <String>[
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _pendingLaunchRoute;
  void Function(String route)? onNotificationTap;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentAlert: true,
          defaultPresentBanner: true,
          defaultPresentSound: true,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == route) onNotificationTap?.call(route);
      },
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'أذكار ما بعد الصلاة',
            description: 'تذكير بأذكار ما بعد الصلاة',
            importance: Importance.high,
          ),
        );
    _initialized = true;
    final launch = await _notifications.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload == route) {
      _pendingLaunchRoute = route;
    }
  }

  String? takePendingLaunchRoute() {
    final route = _pendingLaunchRoute;
    _pendingLaunchRoute = null;
    return route;
  }

  void consumePendingLaunch() {
    final pending = takePendingLaunchRoute();
    if (pending != null) onNotificationTap?.call(pending);
  }

  /// Cancels and suppresses the reminder for a completed prayer period.
  Future<void> cancelForCompletedPeriod(String period) async {
    await initialize();
    final parts = period.split(':');
    if (parts.length != 2) return;
    final date = DateTime.tryParse(parts.first);
    final prayerIndex = _prayerIds.indexOf(parts.last);
    if (date == null || prayerIndex < 0) return;

    final id = _notificationId(date, prayerIndex);
    await _notifications.cancel(id: id);

    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_idsKey) ?? const <String>[];
    await preferences.setStringList(
      _idsKey,
      ids.where((scheduledId) => scheduledId != '$id').toList(),
    );
    final completed =
        preferences.getStringList(_completedPeriodsKey) ?? const <String>[];
    await preferences.setStringList(
      _completedPeriodsKey,
      {...completed, period}.toList(growable: false),
    );
  }

  Future<void> schedule(PrayerTimes times) async {
    await initialize();
    final preferences = await SharedPreferences.getInstance();
    final previousIds = preferences.getStringList(_idsKey) ?? const [];
    for (final id in previousIds) {
      final parsed = int.tryParse(id);
      if (parsed != null) await _notifications.cancel(id: parsed);
    }

    final now = tz.TZDateTime.now(tz.local);
    final todayKey = _dateKey(now);
    final completedPeriods =
        (preferences.getStringList(_completedPeriodsKey) ?? const <String>[])
            .where((period) => period.split(':').first.compareTo(todayKey) >= 0)
            .toSet();
    final prayers = <(String, DateTime)>[
      ('الفجر', times.fajr),
      ('الظهر', times.dhuhr),
      ('العصر', times.asr),
      ('المغرب', times.maghrib),
      ('العشاء', times.isha),
    ];
    final ids = <String>[];
    // Keep today and tomorrow armed. Flutter's scheduled notification boot
    // receiver restores these alarms after reboot; date refresh replaces them.
    for (var dayOffset = 0; dayOffset < 2; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      for (var index = 0; index < prayers.length; index++) {
        final prayerTime = prayers[index].$2;
        final prayer = DateTime(
          date.year,
          date.month,
          date.day,
          prayerTime.hour,
          prayerTime.minute,
          prayerTime.second,
        );
        final reminder = prayer.add(const Duration(minutes: 15));
        final scheduled = tz.TZDateTime(
          tz.local,
          reminder.year,
          reminder.month,
          reminder.day,
          reminder.hour,
          reminder.minute,
          reminder.second,
        );
        if (!scheduled.isAfter(now)) continue;
        final period = '${_dateKey(date)}:${_prayerIds[index]}';
        if (completedPeriods.contains(period)) continue;
        final id = _notificationId(date, index);
        final title = 'تذكير بأذكار ما بعد صلاة ${prayers[index].$1} 🌿';
        final details = const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'أذكار ما بعد الصلاة',
            channelDescription: 'تذكير بأذكار ما بعد الصلاة',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        );
        try {
          await _notifications.zonedSchedule(
            id: id,
            title: title,
            body: 'لا تنسَ أذكار ما بعد الصلاة، اجعل لسانك رطبًا بذكر الله.',
            scheduledDate: scheduled,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: route,
          );
        } on PlatformException {
          await _notifications.zonedSchedule(
            id: id,
            title: title,
            body: 'لا تنسَ أذكار ما بعد الصلاة، اجعل لسانك رطبًا بذكر الله.',
            scheduledDate: scheduled,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: route,
          );
        }
        ids.add(id.toString());
      }
    }
    await preferences.setStringList(_idsKey, ids);
    await preferences.setStringList(
      _completedPeriodsKey,
      completedPeriods.toList(growable: false),
    );
  }

  int _notificationId(DateTime date, int prayerIndex) {
    final dayNumber = DateTime.utc(date.year, date.month, date.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return _idBase + dayNumber * _prayerIds.length + prayerIndex;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
