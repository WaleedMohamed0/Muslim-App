import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:muslim/core/network/connectivity_service.dart';
import 'package:muslim/core/network/dio_client.dart';
import 'package:muslim/core/storage/cache_helper.dart';
import 'package:muslim/features/app/presentation/cubit/app_cubit.dart';
import 'package:muslim/features/app/presentation/muslim_app.dart';
import 'package:muslim/features/app/data/services/kahf_reminder_service.dart';
import 'package:muslim/features/asmaa_allah/presentation/cubit/allah_names_cubit.dart';
import 'package:muslim/features/azkar/presentation/cubit/azkar_cubit.dart';
import 'package:muslim/features/hadeeth/presentation/cubit/hadeeth_cubit.dart';
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:muslim/features/quran/data/data_sources/quran_audio_handler.dart';
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/khatmah/presentation/cubit/khatmah_cubit.dart';

const MethodChannel _notificationNavigationChannel = MethodChannel(
  'com.muslim/notification_navigation',
);

Future<void> runMuslimApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UthmaniQuranText.initialize();
  await MushafLineLayoutData.initialize();
  final quranAudioHandler = await initializeQuranAudioService();
  String? initialKahfRoute;
  try {
    final kahfReminder = KahfReminderService.instance;
    await kahfReminder.initialize();
    initialKahfRoute = kahfReminder.takePendingLaunchRoute();
    await kahfReminder.schedule();
  } catch (_) {
    // Keep app startup available if notification services are unavailable.
  }
  DioHelper.init();
  DioHelper.initHadeeth();
  final initialNotificationRoute =
      initialKahfRoute ?? await _readInitialNotificationRoute();
  await CacheHelper.init().catchError((Object _) {});
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => KhatmahCubit()),
        BlocProvider(
          create:
              (_) => QuranCubit(
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
