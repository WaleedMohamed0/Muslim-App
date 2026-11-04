import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/data/data_sources/quran_audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:quran/quran.dart' as quran;
import 'package:untitled8/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:untitled8/features/azkar/presentation/cubit/azkar_cubit.dart';
import 'package:untitled8/features/hadeeth/presentation/cubit/hadeeth_cubit.dart';
import 'package:untitled8/features/asmaa_allah/presentation/cubit/allah_names_cubit.dart';
import 'package:untitled8/features/app/presentation/cubit/app_cubit.dart';
import 'package:untitled8/features/app/presentation/cubit/app_state.dart';
import 'package:untitled8/core/network/connectivity_service.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:untitled8/core/network/dio_client.dart';
import 'package:untitled8/core/storage/cache_helper.dart';
import 'package:untitled8/core/widgets/app_snackbar.dart';
import 'package:untitled8/core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/app/presentation/pages/app_entry_screen.dart';
import 'features/app/presentation/pages/startup_screen.dart';
import 'features/prayer_times/presentation/pages/prayer_adhan_settings_screen.dart';
import 'features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'features/quran/presentation/pages/home_screen.dart';
import 'features/quran/presentation/pages/surah_screen.dart';
import 'features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'features/prayer_times/presentation/pages/elazan_screen.dart';
import 'features/qibla/presentation/pages/qibla_compass_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
const MethodChannel _notificationNavigationChannel = MethodChannel(
  'com.muslim/notification_navigation',
);
const MethodChannel _quranAudioWidgetChannel = MethodChannel(
  'com.muslim/quran_audio_widget',
);
final _appRouteObserver = _AppRouteObserver();

class _AppRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

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

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _stack.remove(oldRoute);
    if (newRoute != null) _stack.add(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final quranAudioHandler = await initializeQuranAudioService();
  DioHelper.init();
  DioHelper.initHadeeth();
  final initialNotificationRoute = await _readInitialNotificationRoute();
  await CacheHelper.init().catchError((Object _) {});
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => QuranCubit(
            audioHandler: quranAudioHandler as QuranAudioHandler,
          ),
        ),
        BlocProvider(create: (_) => PrayerTimesCubit()),
        BlocProvider(create: (_) => AzkarCubit()..loadContent()),
        BlocProvider(create: (_) => HadeethCubit()),
        BlocProvider(create: (_) => AllahNamesCubit()..load()),
        BlocProvider(
          create:
              (context) => AppCubit(
                connectivity: ConnectivityService(
                  InternetConnectionChecker.instance,
                ),
                hadeeth: context.read<HadeethCubit>(),
                prayerTimes: context.read<PrayerTimesCubit>(),
                quran: context.read<QuranCubit>(),
                azkar: context.read<AzkarCubit>(),
              ),
        ),
      ],
      child: MyApp(initialNotificationRoute: initialNotificationRoute),
    ),
  );
}

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
  final widgetMatch = RegExp(r'^quran_reader:(\d+):(\d+)$').firstMatch(route);
  if (widgetMatch != null) {
    final surahNumber = int.parse(widgetMatch.group(1)!).clamp(1, 114);
    final ayahNumber = int.parse(widgetMatch.group(2)!).clamp(
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
        _openNotificationRoute(call.arguments as String);
      }
    });
  }

  void _syncQuranAudioWidget(QuranCubit cubit) {
    final active =
        cubit.quranSoundActive && cubit.surahNumber >= 1 && cubit.surahNumber <= 114;
    final hasTrack = cubit.surahNumber >= 1 && cubit.surahNumber <= 114;
    final stateKey = <Object>[
      active,
      active ? cubit.isPlaying : false,
      active ? cubit.isAudioLoading : false,
      hasTrack ? cubit.surahNumber : 0,
      hasTrack ? cubit.currentAyahNumber : 0,
      hasTrack ? cubit.surahName : '',
      hasTrack ? cubit.displayReciter.nameArabic : '',
      active ? cubit.audioPosition.inSeconds : 0,
      active ? cubit.audioDuration?.inSeconds ?? 0 : 0,
    ].join('|');
    if (stateKey == _lastQuranWidgetState) return;
    _lastQuranWidgetState = stateKey;
    final state = <String, Object>{
      'active': active,
      'playing': active && cubit.isPlaying,
      'loading': active && cubit.isAudioLoading,
      'surahNumber': hasTrack ? cubit.surahNumber : 0,
      'ayahNumber': hasTrack ? cubit.currentAyahNumber : 0,
      'surah': hasTrack ? cubit.surahName : '',
      'reciter': hasTrack ? cubit.displayReciter.nameArabic : '',
      'reciterAvatarAsset': hasTrack
          ? cubit.displayReciter.avatarAsset ?? ''
          : '',
      'positionMs': active ? cubit.audioPosition.inMilliseconds : 0,
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
    _openQuranReaderFromWidget(surahNumber, ayahNumber);
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
    final widgetMatch = RegExp(r'^quran_reader:(\d+):(\d+)$').firstMatch(route);
    if (widgetMatch != null) {
      final surahNumber = int.tryParse(widgetMatch.group(1) ?? '');
      final ayahNumber = int.tryParse(widgetMatch.group(2) ?? '');
      if (surahNumber != null && ayahNumber != null) {
        _openQuranReaderFromWidget(surahNumber, ayahNumber);
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
    if (_appRouteObserver.containsRoute(routeName)) {
      navigator.popUntil((route) => route.settings.name == routeName);
      return;
    }
    final isDailyReminderDestination =
        routeName.startsWith('/azkar-category-') ||
        routeName == '/quran-home';
    if (isDailyReminderDestination) {
      navigator.popUntil((route) => route.isFirst);
      if (_appRouteObserver.firstRouteName != '/home') {
        navigator.pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/home'),
            builder: (_) => const StartUpScreen(),
          ),
          (_) => false,
        );
      }
      navigator.push<void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: routeName),
          builder: (_) => page,
        ),
      );
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

  void _openQuranReaderFromWidget(int requestedSurah, int requestedAyah) {
    if (!mounted) return;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openQuranReaderFromWidget(requestedSurah, requestedAyah),
      );
      return;
    }
    final surahNumber = requestedSurah.clamp(1, 114);
    final ayahNumber = requestedAyah.clamp(
      1,
      quran.getVerseCount(surahNumber),
    );
    final routeName = '/quran-reader/$surahNumber';
    // Return to the existing app root, then open one reader at the latest
    // audio position. This avoids stacking duplicate reader routes and does
    // not touch the shared audio handler or its current position.
    navigator.popUntil((route) => route.isFirst);
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => SurahScreen(
          surahNumber: surahNumber,
          initialAyah: ayahNumber,
        ),
      ),
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
        final isDark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: theme.scaffoldBackgroundColor,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: theme.colorScheme.outlineVariant,
          ),
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(child: child ?? const SizedBox.shrink()),
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
            MaterialPageRoute<void>(
              settings: RouteSettings(
                name: '/',
              ),
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
