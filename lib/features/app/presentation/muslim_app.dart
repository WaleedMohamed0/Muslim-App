import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quran/quran.dart' as quran;
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:muslim/core/error_reporting/diagnostic_context.dart';
import 'package:muslim/core/storage/cache_helper.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/features/azkar/presentation/azkar_categories.dart';
import 'package:muslim/core/widgets/app_snackbar.dart';
import 'package:muslim/core/widgets/dismiss_keyboard_on_outside_tap.dart';
import 'package:muslim/features/app/data/services/kahf_reminder_service.dart';
import 'package:muslim/features/app/data/services/post_prayer_adhkar_reminder_service.dart';
import 'package:muslim/features/app/presentation/cubit/app_cubit.dart';
import 'package:muslim/features/app/presentation/cubit/app_state.dart';
import 'package:muslim/features/app/presentation/daily_wird_route_observer.dart';
import 'package:muslim/features/app/presentation/pages/app_entry_screen.dart';
import 'package:muslim/features/app/presentation/pages/app_home_shell.dart';
import 'package:muslim/features/app/presentation/pages/daily_wird_reader_screen.dart';
import 'package:muslim/features/app/presentation/pages/startup_screen.dart';
import 'package:muslim/features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'package:muslim/features/khatmah/presentation/pages/khatmah_screen.dart';
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:muslim/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:muslim/features/prayer_times/presentation/pages/elazan_screen.dart';
import 'package:muslim/features/prayer_times/presentation/pages/prayer_adhan_settings_screen.dart';
import 'package:muslim/features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'package:muslim/features/qibla/presentation/pages/qibla_compass_screen.dart';
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:muslim/features/quran/presentation/pages/home_screen.dart';
import 'package:muslim/features/quran/presentation/pages/surah_screen.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_background_colors.dart';

part 'app_routes.dart';
part 'app_notification_handlers.dart';
part 'app_material_app.dart';
part 'quran_widget_playback_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialNotificationRoute});

  final String? initialNotificationRoute;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<bool>? _mediaNotificationClickSubscription;
  StreamSubscription? _quranWidgetStateSubscription;
  StreamSubscription? _prayerWidgetStateSubscription;
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
    final prayerCubit = context.read<PrayerTimesCubit>();
    _prayerWidgetStateSubscription = prayerCubit.stream.listen((state) {
      _syncPrayerTimesWidget(state);
    });
    _syncPrayerTimesWidget(prayerCubit.state);
    _quranWidgetProgressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (quranCubit.quranSoundActive) _syncQuranAudioWidget(quranCubit);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncQuranAudioWidget(quranCubit),
    );
    _mediaNotificationClickSubscription = AudioService.notificationClicked
        .listen((clicked) {
          if (clicked) _openQuranFromMediaNotification();
        });
    _notificationNavigationChannel.setMethodCallHandler((call) async {
      if (call.method == 'openNotificationRoute' && call.arguments is String) {
        final route = call.arguments as String;
        _lastLiveNotificationRoute = route;
        _openNotificationRoute(route);
      }
    });
    final kahfReminder = KahfReminderService.instance;
    kahfReminder.onNotificationTap = _openNotificationRoute;
    kahfReminder.consumePendingLaunch();
    final postPrayerReminder = PostPrayerAdhkarReminderService.instance;
    postPrayerReminder.onNotificationTap = _openNotificationRoute;
    postPrayerReminder.consumePendingLaunch();
    // A widget tap can arrive after main() consumed the cold-start Intent but
    // before this MethodChannel handler was installed. MainActivity retains
    // that request; consume it again now so the route cannot be lost in that
    // startup window. For Quran routes, verify the reader is still on top
    // before treating the initial route as handled.
    unawaited(_consumePendingNotificationRoute());
  }

  void _syncPrayerTimesWidget(PrayerTimesState state) {
    final times = state.prayerTimes;
    if (times == null) return;
    unawaited(_prayerTimesWidgetChannel.invokeMethod<void>('updateSchedule', {
      'fajr': times.fajr.millisecondsSinceEpoch,
      'sunrise': times.sunrise.millisecondsSinceEpoch,
      'dhuhr': times.dhuhr.millisecondsSinceEpoch,
      'asr': times.asr.millisecondsSinceEpoch,
      'maghrib': times.maghrib.millisecondsSinceEpoch,
      'isha': times.isha.millisecondsSinceEpoch,
      'city': state.cityName,
    }).catchError((Object _) {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quranWidgetProgressTimer?.cancel();
    _mediaNotificationClickSubscription?.cancel();
    _quranWidgetStateSubscription?.cancel();
    _prayerWidgetStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<QuranCubit>().handleAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    unawaited(context.read<PrayerTimesCubit>().getPrayerTime());
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
}
