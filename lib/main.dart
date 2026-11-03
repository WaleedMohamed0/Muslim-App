import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
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
import 'features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'features/prayer_times/presentation/pages/elazan_screen.dart';
import 'features/qibla/presentation/pages/qibla_compass_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
const MethodChannel _notificationNavigationChannel = MethodChannel(
  'com.muslim/notification_navigation',
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
  DioHelper.init();
  DioHelper.initHadeeth();
  final initialNotificationRoute = await _readInitialNotificationRoute();
  await CacheHelper.init().catchError((Object _) {});
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => QuranCubit()),
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

({String routeName, Widget page})? _notificationDestination(String route) =>
    switch (route) {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationNavigationChannel.setMethodCallHandler((call) async {
      if (call.method == 'openNotificationRoute' && call.arguments is String) {
        _openNotificationRoute(call.arguments as String);
      }
    });
  }

  void _openNotificationRoute(String route) {
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
