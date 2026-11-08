import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Owns the independent, offline Friday Surah Al-Kahf reminder.
class KahfReminderService {
  KahfReminderService._();

  static final KahfReminderService instance = KahfReminderService._();
  static const int _notificationId = 51009;
  static const int _khatmahNotificationId = 51010;
  static const String route = 'surah_al_kahf';
  static const String khatmahRoute = 'khatmah';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function(String route)? onNotificationTap;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _notifications.initialize(
      const InitializationSettings(
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
        final payload = response.payload;
        if (payload == route || payload == khatmahRoute) {
          onNotificationTap?.call(payload!);
        }
      },
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'kahf_friday_reminder',
            'تذكير سورة الكهف',
            description: 'تذكير أسبوعي بقراءة سورة الكهف يوم الجمعة',
            importance: Importance.high,
            playSound: true,
          ),
        );
    _initialized = true;
    final launch = await _notifications.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        (launch?.notificationResponse?.payload == route ||
            launch?.notificationResponse?.payload == khatmahRoute)) {
      // The callback is installed by MyApp after bootstrap; retain cold-start
      // taps until that handler is ready.
      _pendingLaunchRoute = launch?.notificationResponse?.payload;
    }
  }

  String? _pendingLaunchRoute;

  String? takePendingLaunchRoute() {
    final pending = _pendingLaunchRoute;
    _pendingLaunchRoute = null;
    return pending;
  }

  void consumePendingLaunch() {
    final pending = takePendingLaunchRoute();
    if (pending != null) onNotificationTap?.call(pending);
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    final androidGranted = await android?.requestNotificationsPermission();
    if (androidGranted == true) {
      await android?.requestExactAlarmsPermission();
    }
    final iosGranted = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await schedule();
    return androidGranted ?? iosGranted ?? true;
  }

  Future<bool> notificationsGranted() async {
    await initialize();
    final android = _notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android != null) return await android.areNotificationsEnabled() ?? false;
    final ios = _notifications.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin
    >();
    return await ios?.checkPermissions().then(
          (value) => value?.isEnabled == true,
        ) ??
        true;
  }

  Future<void> schedule() async {
    await initialize();
    await _notifications.cancel(_notificationId);
    final now = tz.TZDateTime.now(tz.local);
    var nextFriday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );
    while (nextFriday.weekday != DateTime.friday || !nextFriday.isAfter(now)) {
      nextFriday = nextFriday.add(const Duration(days: 1));
    }
    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'kahf_friday_reminder',
        'تذكير سورة الكهف',
        channelDescription: 'تذكير أسبوعي بقراءة سورة الكهف يوم الجمعة',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        ticker: 'تذكير يوم الجمعة',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
      ),
    );
    try {
      await _notifications.zonedSchedule(
        _notificationId,
        'تذكير يوم الجمعة 🌿',
        'لا تنسَ قراءة سورة الكهف، نورٌ ما بين الجمعتين.',
        nextFriday,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: route,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } on PlatformException {
      // Continue delivering on Android installs where exact-alarm access is
      // unavailable; the operating system may defer this fallback slightly.
      await _notifications.zonedSchedule(
        _notificationId,
        'تذكير يوم الجمعة 🌿',
        'لا تنسَ قراءة سورة الكهف، نورٌ ما بين الجمعتين.',
        nextFriday,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: route,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> scheduleKhatmah({required bool enabled, required int hour, required int minute, bool skipToday = false}) async {
    await initialize();
    await _notifications.cancel(_khatmahNotificationId);
    if (!enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    if (skipToday && next.year == now.year && next.month == now.month && next.day == now.day) {
      next = next.add(const Duration(days: 1));
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails('khatmah_daily_reminder', 'تذكير خطة الختمة',
        channelDescription: 'تذكير يومي بورد القرآن في خطة الختمة', importance: Importance.high, priority: Priority.high),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
    );
    try {
      await _notifications.zonedSchedule(_khatmahNotificationId, 'وردك اليوم من القرآن 🌿', 'حان وقت متابعة خطة الختمة. افتح التطبيق لإكمال وردك اليومي.', next, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: khatmahRoute,
        matchDateTimeComponents: DateTimeComponents.time);
    } on PlatformException {
      await _notifications.zonedSchedule(_khatmahNotificationId, 'وردك اليوم من القرآن 🌿', 'حان وقت متابعة خطة الختمة. افتح التطبيق لإكمال وردك اليومي.', next, details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: khatmahRoute,
        matchDateTimeComponents: DateTimeComponents.time);
    }
  }
}
