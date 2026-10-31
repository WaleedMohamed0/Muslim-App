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

class _MyAppState extends State<MyApp> {
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

