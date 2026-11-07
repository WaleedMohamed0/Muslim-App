import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:muslim/features/app/presentation/cubit/app_cubit.dart';
import 'package:muslim/features/app/presentation/cubit/app_state.dart';
import 'package:muslim/core/storage/cache_helper.dart';
import 'package:muslim/core/widgets/app_snackbar.dart';
import 'package:muslim/core/theme/app_colors.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/features/app/presentation/pages/app_entry_screen.dart';
import 'package:muslim/features/app/presentation/pages/startup_screen.dart';
import 'package:muslim/features/prayer_times/presentation/pages/prayer_adhan_settings_screen.dart';
import 'package:muslim/features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'package:muslim/features/quran/presentation/pages/home_screen.dart';
import 'package:muslim/features/quran/presentation/pages/surah_screen.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_background_colors.dart';
import 'package:muslim/features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'package:muslim/features/prayer_times/presentation/pages/elazan_screen.dart';
import 'package:muslim/features/qibla/presentation/pages/qibla_compass_screen.dart';

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
    final ayahNumber = int.parse(widgetPlayMatch.group(2)!).clamp(
      1,
      quran.getVerseCount(surahNumber),
    );
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
    final ayahNumber = int.parse(widgetMatch.group(3)!).clamp(
      1,
      quran.getVerseCount(surahNumber),
    );
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
    final ayahNumber = int.parse(legacyWidgetMatch.group(2)!).clamp(
      1,
      quran.getVerseCount(surahNumber),
    );
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
      'daily_wird' => (routeName: '/quran-home', page: const HomeScreen()),
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

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialNotificationRoute});

  final String? initialNotificationRoute;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime _lastLocalDate = DateTime.now();
  String _lastTimeZone = DateTime.now().timeZoneName;
  Duration _lastUtcOffset = DateTime.now().timeZoneOffset;
  StreamSubscription<bool>? _mediaNotificationClickSubscription;
  StreamSubscription? _quranWidgetStateSubscription;
  String? _lastQuranWidgetState;
  String? _lastLiveNotificationRoute;
  Timer? _quranWidgetProgressTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final quranCubit = context.read<QuranCubit>();
    _quranWidgetStateSubscription = quranCubit.stream.listen(
      (_) => _syncQuranAudioWidget(quranCubit),
    );
    _quranWidgetProgressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (quranCubit.quranSoundActive) _syncQuranAudioWidget(quranCubit);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncQuranAudioWidget(quranCubit),
    );
    _mediaNotificationClickSubscription = AudioService.notificationClicked.listen(
      (clicked) {
        if (clicked) _openQuranFromMediaNotification();
      },
    );
    _notificationNavigationChannel.setMethodCallHandler((call) async {
      if (call.method == 'openNotificationRoute' && call.arguments is String) {
        final route = call.arguments as String;
        _lastLiveNotificationRoute = route;
        _openNotificationRoute(route);
      }
    });
    // A widget tap can arrive after main() consumed the cold-start Intent but
    // before this MethodChannel handler was installed. MainActivity retains
    // that request; consume it again now so the route cannot be lost in that
    // startup window. For Quran routes, verify the reader is still on top
    // before treating the initial route as handled.
    unawaited(_consumePendingNotificationRoute());
  }

  Future<void> _consumePendingNotificationRoute() async {
    final route = await _readInitialNotificationRoute();
    if (!mounted || route == null || route.isEmpty) return;
    final isQuranReaderRoute = RegExp(
      r'^quran_reader:(\d+):(?:(\d+):)?(\d+)$',
    ).hasMatch(route);
    final routeName = isQuranReaderRoute
        ? '/quran-reader/${RegExp(r'^quran_reader:(\d+)').firstMatch(route)!.group(1)}'
        : null;
    final requestedRouteName = routeName ??
        _notificationDestination(route)?.routeName;
    final alreadyAtRequestedDestination = requestedRouteName != null &&
        _appRouteObserver.currentRouteName == requestedRouteName;
    // A second read of the native pending Intent is common during startup:
    // main() consumes it before runApp, then this State checks again after its
    // MethodChannel handler is installed. Only suppress that replay when the
    // requested page is actually on top. Otherwise a lost/late initial route
    // can leave Home visible and make Back reveal the destination afterward.
    if ((route == widget.initialNotificationRoute ||
            route == _lastLiveNotificationRoute) &&
        alreadyAtRequestedDestination) {
      return;
    }
    _openNotificationRoute(route);
  }

  void _syncQuranAudioWidget(QuranCubit cubit) {
    final active =
        cubit.quranSoundActive && cubit.surahNumber >= 1 && cubit.surahNumber <= 114;
    final hasTrack = cubit.surahNumber >= 1 && cubit.surahNumber <= 114;
    final widgetAyahNumber = cubit.currentAyahNumber;
    final widgetPageNumber = cubit.currentMushafPageNumber;
    final stateKey = <Object>[
      active,
      active ? cubit.isPlaying : false,
      active ? cubit.isAudioLoading : false,
      hasTrack ? cubit.surahNumber : 0,
      hasTrack ? widgetPageNumber : 0,
      hasTrack ? widgetAyahNumber : 0,
      hasTrack ? cubit.currentSurahVerseCount : 0,
      hasTrack ? cubit.surahName : '',
      hasTrack ? cubit.displayReciter.nameArabic : '',
      cubit.lastKnownAudioPositionMs ~/ 1000,
      active ? cubit.audioDuration?.inSeconds ?? 0 : 0,
    ].join('|');
    if (stateKey == _lastQuranWidgetState) return;
    _lastQuranWidgetState = stateKey;
    final state = <String, Object>{
      'active': active,
      'playing': active && cubit.isPlaying,
      'loading': active && cubit.isAudioLoading,
      'surahNumber': hasTrack ? cubit.surahNumber : 0,
      'pageNumber': hasTrack ? widgetPageNumber : 0,
      'ayahNumber': hasTrack ? widgetAyahNumber : 0,
      'verseCount': hasTrack ? cubit.currentSurahVerseCount : 0,
      'surah': hasTrack ? cubit.surahName : '',
      'reciter': hasTrack ? cubit.displayReciter.nameArabic : '',
      'reciterAvatarAsset': hasTrack
          ? cubit.displayReciter.avatarAsset ?? ''
          : '',
      'positionMs': cubit.lastKnownAudioPositionMs,
      'durationMs': active ? cubit.audioDuration?.inMilliseconds ?? 0 : 0,
    };
    unawaited(_writeQuranWidgetState(state, stateKey));
  }

  Future<void> _writeQuranWidgetState(
    Map<String, Object> state,
    String stateKey,
  ) async {
    try {
      await _quranAudioWidgetChannel.invokeMethod<void>('updateState', state);
    } on PlatformException {
      if (_lastQuranWidgetState == stateKey) _lastQuranWidgetState = null;
    } on MissingPluginException {
      if (_lastQuranWidgetState == stateKey) _lastQuranWidgetState = null;
    }
  }

  void _openQuranFromMediaNotification() {
    if (!mounted) return;
    final cubit = context.read<QuranCubit>();
    final savedSurah = CacheHelper.getData(key: 'quran_last_played_surah');
    final surahNumber = cubit.surahNumber > 0
        ? cubit.surahNumber
        : (savedSurah is int ? savedSurah : 1).clamp(1, 114);
    final savedAyah = CacheHelper.getData(
      key: 'quran_last_played_ayah_$surahNumber',
    );
    final ayahNumber = cubit.surahNumber == surahNumber
        ? cubit.currentAyahNumber
        : savedAyah is int
            ? savedAyah
            : 1;
    _openQuranReaderFromWidget(
      surahNumber,
      ayahNumber,
      requestedPage: cubit.surahNumber == surahNumber
          ? cubit.currentMushafPageNumber
          : null,
    );
  }

  void _openNotificationRoute(String route) {
    final widgetPlayMatch = RegExp(
      r'^quran_widget_play:(\d+):(\d+)$',
    ).firstMatch(route);
    if (widgetPlayMatch != null) {
      final surahNumber = int.tryParse(widgetPlayMatch.group(1) ?? '');
      final ayahNumber = int.tryParse(widgetPlayMatch.group(2) ?? '');
      if (surahNumber != null && ayahNumber != null) {
        unawaited(
          context.read<QuranCubit>().playFromAyahBookmark(
            surahNumber,
            ayahNumber,
          ),
        );
        _openQuranReaderFromWidget(surahNumber, ayahNumber);
      }
      return;
    }
    final widgetMatch = RegExp(
      r'^quran_reader:(\d+):(\d+):(\d+)$',
    ).firstMatch(route);
    final legacyWidgetMatch = widgetMatch == null
        ? RegExp(r'^quran_reader:(\d+):(\d+)$').firstMatch(route)
        : null;
    final readerMatch = widgetMatch ?? legacyWidgetMatch;
    if (readerMatch != null) {
      final surahNumber = int.tryParse(readerMatch.group(1) ?? '');
      final hasPage = widgetMatch != null;
      final pageNumber = hasPage
          ? int.tryParse(readerMatch.group(2) ?? '')
          : null;
      final ayahNumber = int.tryParse(
        readerMatch.group(hasPage ? 3 : 2) ?? '',
      );
      if (surahNumber != null && ayahNumber != null) {
        _openQuranReaderFromWidget(
          surahNumber,
          ayahNumber,
          requestedPage: pageNumber,
        );
      }
      return;
    }
    final destination = _notificationDestination(route);
    if (destination == null) return;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openNotificationRoute(route),
      );
      return;
    }
    final routeName = destination.routeName;
    final page = destination.page;
    final isDailyReminderDestination =
        routeName.startsWith('/azkar-category-') ||
        routeName == '/quran-home';
    // A reminder is a direct entry point. Rebuild the stack even if an older
    // copy of its route is already present; Home may have been pushed above
    // that copy during startup or while the app was backgrounded.
    if (isDailyReminderDestination) {
      if (routeName.startsWith('/azkar-category-') ||
          routeName == '/quran-home') {
        navigator.pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/home'),
            builder: (_) => const StartUpScreen(),
          ),
          (_) => false,
        );
        // Wait until the replacement Home route is installed before pushing
        // the reminder destination. The notification can arrive while the
        // app entry route is still transitioning during a cold start.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || appNavigatorKey.currentState != navigator) return;
          if (_appRouteObserver.currentRouteName == routeName) return;
          navigator.push<void>(
            MaterialPageRoute<void>(
              settings: RouteSettings(name: routeName),
              builder: (_) => page,
            ),
          );
        });
      } else {
        navigator.pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            settings: RouteSettings(name: routeName),
            builder: (_) => page,
          ),
          (_) => false,
        );
      }
      return;
    }
    if (_appRouteObserver.containsRoute(routeName)) {
      navigator.popUntil((route) => route.settings.name == routeName);
      return;
    }
    final existingElAzanRoute = _appRouteObserver.latestRouteWithPrefix(
      '/elazan-screen/',
    );
    if (routeName.startsWith('/elazan-screen/') &&
        existingElAzanRoute != null) {
      navigator.popUntil((route) => route.settings.name == existingElAzanRoute);
      navigator.pushReplacement<void, void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: routeName),
          builder: (_) => page,
        ),
      );
      return;
    }
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }

  void _openQuranReaderFromWidget(
    int requestedSurah,
    int requestedAyah, {
    int? requestedPage,
  }) {
    if (!mounted) return;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openQuranReaderFromWidget(
          requestedSurah,
          requestedAyah,
          requestedPage: requestedPage,
        ),
      );
      return;
    }
    final surahNumber = requestedSurah.clamp(1, 114);
    final ayahNumber = requestedAyah.clamp(
      1,
      quran.getVerseCount(surahNumber),
    );
    final correctPage = quran.getPageNumber(surahNumber, ayahNumber);
    final pageNumber = requestedPage == correctPage ? requestedPage : correctPage;
    final routeName = '/quran-reader/$surahNumber';
    // A widget launch is a direct reader entry point. Remove Home/AppEntry
    // and any stale routes so Back cannot reveal a Home screen inserted
    // solely to sit underneath this reader. Playback state lives in the
    // shared Cubit/AudioHandler and is unaffected by replacing the route stack.
    navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => SurahScreen(
          surahNumber: surahNumber,
          initialAyah: ayahNumber,
          initialPageNumber: pageNumber,
        ),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quranWidgetProgressTimer?.cancel();
    _mediaNotificationClickSubscription?.cancel();
    _quranWidgetStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<QuranCubit>().handleAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    final dayChanged =
        now.year != _lastLocalDate.year ||
        now.month != _lastLocalDate.month ||
        now.day != _lastLocalDate.day;
    final timezoneChanged =
        now.timeZoneName != _lastTimeZone ||
        now.timeZoneOffset != _lastUtcOffset;
    _lastLocalDate = now;
    _lastTimeZone = now.timeZoneName;
    _lastUtcOffset = now.timeZoneOffset;
    if (dayChanged || timezoneChanged) {
      final prayerTimes = context.read<PrayerTimesCubit>();
      if (prayerTimes.isOnline) unawaited(prayerTimes.getPrayerTime());
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return ResponsiveSizer(
      builder: (p0, p1, p2) {
        return BlocBuilder<AppCubit, AppState>(
          builder: (context, state) => _buildMaterialApp(state.themeMode),
        );
      },
    );
  }

  MaterialApp _buildMaterialApp(ThemeMode themeMode) {
    final initialDestination = _notificationDestination(
      widget.initialNotificationRoute ?? '',
    );
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      navigatorObservers: [_appRouteObserver],
      builder: (context, child) {
        final theme =
            themeMode == ThemeMode.dark ? AppTheme.dark : AppTheme.light;
        return BlocBuilder<QuranCubit, QuranState>(
          builder: (context, _) => AnimatedBuilder(
            animation: _activeRouteName,
            builder: (context, _) {
              final isReaderRoute =
                  _activeRouteName.value?.startsWith('/quran-reader/') ??
                  false;
              final quranCubit = context.read<QuranCubit>();
              final isDark = theme.brightness == Brightness.dark;
              final readerBackground = isDark
                  ? quranCubit.darkReaderBackgroundColorValue
                  : quranCubit.lightReaderBackgroundColorValue;
              final insetColor = isReaderRoute
                  ? Color(
                    readerBackground ??
                        QuranReaderBackgroundColors.defaultFor(isDark)
                            .toARGB32(),
                  )
                  : theme.scaffoldBackgroundColor;
              return ColoredBox(
                color: insetColor,
                child: SafeArea(
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle(
                      statusBarColor: insetColor,
                      statusBarIconBrightness:
                          isDark ? Brightness.light : Brightness.dark,
                      statusBarBrightness:
                          isDark ? Brightness.dark : Brightness.light,
                      systemNavigationBarColor: insetColor,
                      systemNavigationBarIconBrightness:
                          isDark ? Brightness.light : Brightness.dark,
                      systemNavigationBarDividerColor: insetColor,
                      systemNavigationBarContrastEnforced: false,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        );
      },
      scaffoldMessengerKey: AppSnackBar.messengerKey,
      onGenerateRoute: _generateRoute,
      onUnknownRoute:
          (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const StartUpScreen(),
          ),
      initialRoute: '/',
      onGenerateInitialRoutes:
          (initialRoute) => [
            if (initialDestination != null &&
                (initialDestination.routeName.startsWith('/azkar-category-') ||
                    initialDestination.routeName == '/quran-home')) ...[
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/home'),
                builder: (_) => const StartUpScreen(),
              ),
              MaterialPageRoute<void>(
                settings: RouteSettings(name: initialDestination.routeName),
                builder: (_) => initialDestination.page,
              ),
            ] else if (initialDestination != null)
              MaterialPageRoute<void>(
                settings: RouteSettings(
                  name: initialDestination.routeName,
                ),
                builder: (_) => initialDestination.page,
              )
            else
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/'),
                builder:
                    (_) => AppEntryScreen(
                      initialDestination: initialDestination?.page,
                      initialDestinationRouteName:
                          initialDestination?.routeName,
                    ),
              ),
          ],
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Cold-start fallback for a widget Play tap when Android has recreated the
/// media service without its prepared audio source. It uses the app's existing
/// QuranCubit and its single shared player.
class _QuranWidgetPlaybackScreen extends StatefulWidget {
  const _QuranWidgetPlaybackScreen({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  @override
  State<_QuranWidgetPlaybackScreen> createState() =>
      _QuranWidgetPlaybackScreenState();
}

class _QuranWidgetPlaybackScreenState
    extends State<_QuranWidgetPlaybackScreen> {
  bool _playRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_playRequested) return;
    _playRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<QuranCubit>().playFromAyahBookmark(
          widget.surahNumber,
          widget.ayahNumber,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => SurahScreen(
    surahNumber: widget.surahNumber,
    initialAyah: widget.ayahNumber,
  );
}
