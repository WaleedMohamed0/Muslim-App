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
import 'package:untitled8/core/bootstrap/app_bootstrap.dart';
import 'package:untitled8/core/widgets/app_snackbar.dart';
import 'core/theme/app_theme.dart';
import 'features/app/presentation/pages/startup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => QuranCubit()),
      BlocProvider(create: (_) => PrayerTimesCubit()),
      BlocProvider(create: (_) => AzkarCubit()..loadContent()),
      BlocProvider(create: (_) => HadeethCubit()),
      BlocProvider(create: (_) => AllahNamesCubit()..load()),
      BlocProvider(create: (context) => AppCubit(
        connectivity: ConnectivityService(InternetConnectionChecker.instance),
        hadeeth: context.read<HadeethCubit>(),
        prayerTimes: context.read<PrayerTimesCubit>(),
        quran: context.read<QuranCubit>(),
        azkar: context.read<AzkarCubit>(),
      )),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    final dayChanged = now.year != _lastLocalDate.year ||
        now.month != _lastLocalDate.month ||
        now.day != _lastLocalDate.day;
    final timezoneChanged = now.timeZoneName != _lastTimeZone ||
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
          builder: (context, state) => MaterialApp(
            builder: (context, child) {
              final theme =
                  state.themeMode == ThemeMode.dark
                      ? AppTheme.dark
                      : AppTheme.light;
              final isDark = theme.brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: theme.scaffoldBackgroundColor,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  statusBarBrightness:
                      isDark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: theme.scaffoldBackgroundColor,
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  systemNavigationBarDividerColor:
                      theme.colorScheme.outlineVariant,
                ),
                child: ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: SafeArea(child: child ?? const SizedBox.shrink()),
                ),
              );
            },
            scaffoldMessengerKey: AppSnackBar.messengerKey,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.themeMode,
            debugShowCheckedModeBanner: false,
            home: const StartUpScreen(),
          ),
        );
      },
    );
  }
}

