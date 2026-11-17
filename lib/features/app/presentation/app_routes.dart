part of 'muslim_app.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
const MethodChannel _notificationNavigationChannel = MethodChannel(
  'com.muslim/notification_navigation',
);
const MethodChannel _quranAudioWidgetChannel = MethodChannel(
  'com.muslim/quran_audio_widget',
);
final _appRouteObserver = _AppRouteObserver();
final ValueNotifier<String?> _activeRouteName = ValueNotifier<String?>(null);

Future<String?> _readInitialNotificationRoute() async {
  try {
    return await _notificationNavigationChannel.invokeMethod<String>(
      'initialNotificationRoute',
    );
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

class _AppRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];
  bool _activeRouteSyncScheduled = false;

  bool containsRoute(String name) =>
      _stack.any((route) => route.settings.name == name);

  String? latestRouteWithPrefix(String prefix) {
    for (final route in _stack.reversed) {
      final name = route.settings.name;
      if (name != null && name.startsWith(prefix)) return name;
    }
    return null;
  }

  String? get firstRouteName =>
      _stack.isEmpty ? null : _stack.first.settings.name;

  String? get currentRouteName =>
      _stack.isEmpty ? null : _stack.last.settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _syncActiveRoute();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _syncActiveRoute();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _syncActiveRoute();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _stack.remove(oldRoute);
    if (newRoute != null) _stack.add(newRoute);
    _syncActiveRoute();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _syncActiveRoute() {
    if (_activeRouteSyncScheduled) return;
    _activeRouteSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activeRouteSyncScheduled = false;
      final routeName = currentRouteName;
      if (_activeRouteName.value != routeName) {
        _activeRouteName.value = routeName;
        unawaited(
          DiagnosticContext.setCurrentScreen(
            DiagnosticContext.analyticsRouteName(routeName),
          ),
        );
      }
    });
  }
}

({String routeName, Widget page})? _notificationDestination(String route) {
  final widgetPlayMatch = RegExp(
    r'^quran_widget_play:(\d+):(\d+)$',
  ).firstMatch(route);
  if (widgetPlayMatch != null) {
    final surahNumber = int.parse(widgetPlayMatch.group(1)!).clamp(1, 114);
    final ayahNumber = int.parse(
      widgetPlayMatch.group(2)!,
    ).clamp(1, quran.getVerseCount(surahNumber));
    return (
      routeName: '/quran-reader/$surahNumber',
      page: _QuranWidgetPlaybackScreen(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      ),
    );
  }
  final widgetMatch = RegExp(
    r'^quran_reader:(\d+):(\d+):(\d+)$',
  ).firstMatch(route);
  if (widgetMatch != null) {
    final surahNumber = int.parse(widgetMatch.group(1)!).clamp(1, 114);
    final pageNumber = int.parse(widgetMatch.group(2)!);
    final ayahNumber = int.parse(
      widgetMatch.group(3)!,
    ).clamp(1, quran.getVerseCount(surahNumber));
    return (
      routeName: '/quran-reader/$surahNumber',
      page: SurahScreen(
        surahNumber: surahNumber,
        initialAyah: ayahNumber,
        initialPageNumber: pageNumber,
      ),
    );
  }
  final legacyWidgetMatch = RegExp(
    r'^quran_reader:(\d+):(\d+)$',
  ).firstMatch(route);
  if (legacyWidgetMatch != null) {
    final surahNumber = int.parse(legacyWidgetMatch.group(1)!).clamp(1, 114);
    final ayahNumber = int.parse(
      legacyWidgetMatch.group(2)!,
    ).clamp(1, quran.getVerseCount(surahNumber));
    return (
      routeName: '/quran-reader/$surahNumber',
      page: SurahScreen(surahNumber: surahNumber, initialAyah: ayahNumber),
    );
  }
  return switch (route) {
    'adhan_settings' => (
      routeName: '/adhan-settings',
      page: const PrayerAdhanSettingsScreen(),
    ),
    'prayer_times' => (routeName: '/prayer-times', page: const PrayerTimes()),
    'elazan_screen:fajr' => (
      routeName: '/elazan-screen/fajr',
      page: const ElAzanScreen(prayer: 'الفجر'),
    ),
    'elazan_screen:dhuhr' => (
      routeName: '/elazan-screen/dhuhr',
      page: const ElAzanScreen(prayer: 'الظهر'),
    ),
    'elazan_screen:asr' => (
      routeName: '/elazan-screen/asr',
      page: const ElAzanScreen(prayer: 'العصر'),
    ),
    'elazan_screen:maghrib' => (
      routeName: '/elazan-screen/maghrib',
      page: const ElAzanScreen(prayer: 'المغرب'),
    ),
    'elazan_screen:isha' => (
      routeName: '/elazan-screen/isha',
      page: const ElAzanScreen(prayer: 'العشاء'),
    ),
    'azkar_morning' => (
      routeName: '/azkar-category-0',
      page: const AzkarAndHadeethScreen(index: 0),
    ),
    'azkar_evening' => (
      routeName: '/azkar-category-1',
      page: const AzkarAndHadeethScreen(index: 1),
    ),
    'daily_wird' => (
      routeName: '/daily-wird',
      page: const DailyWirdReaderScreen(),
    ),
    'salawat' => (routeName: '/home', page: const StartUpScreen()),
    KahfReminderService.route => (
      routeName: '/quran-reader/18',
      page: const SurahScreen(surahNumber: 18),
    ),
    KahfReminderService.khatmahRoute => (
      routeName: '/khatmah',
      page: const KhatmahScreen(),
    ),
    PostPrayerAdhkarReminderService.route => (
      routeName: '/azkar-category-4',
      page: const AzkarAndHadeethScreen(index: 4),
    ),
    _ => null,
  };
}

Widget? _pageForRouteName(String routeName) {
  if (routeName == '/') return const AppEntryScreen();
  if (routeName == '/home') return const StartUpScreen();
  if (routeName == '/adhan-settings') {
    return const PrayerAdhanSettingsScreen();
  }
  if (routeName == '/prayer-times') return const PrayerTimes();
  if (routeName == '/quran-home') return const HomeScreen();
  if (routeName == '/qibla') return const QiblaCompassScreen();

  final notificationRoute = switch (routeName) {
    '/elazan-screen/fajr' => 'elazan_screen:fajr',
    '/elazan-screen/dhuhr' => 'elazan_screen:dhuhr',
    '/elazan-screen/asr' => 'elazan_screen:asr',
    '/elazan-screen/maghrib' => 'elazan_screen:maghrib',
    '/elazan-screen/isha' => 'elazan_screen:isha',
    '/azkar-category-0' => 'azkar_morning',
    '/azkar-category-1' => 'azkar_evening',
    _ => null,
  };
  final destination =
      notificationRoute == null
          ? null
          : _notificationDestination(notificationRoute);
  if (destination != null) return destination.page;

  final categoryPrefix = '/azkar-category-';
  if (routeName.startsWith(categoryPrefix)) {
    final index = int.tryParse(routeName.substring(categoryPrefix.length));
    if (index != null &&
        index >= 0 &&
        index < AppColors.azkarCategories.length) {
      return AzkarAndHadeethScreen(index: index);
    }
  }
  return null;
}

Route<dynamic>? _generateRoute(RouteSettings settings) {
  final page = _pageForRouteName(settings.name ?? '/');
  if (page == null) return null;
  return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
}
