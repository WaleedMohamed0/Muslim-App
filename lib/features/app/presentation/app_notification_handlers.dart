part of 'muslim_app.dart';

extension _AppNotificationHandlers on _MyAppState {
  Future<void> _consumePendingNotificationRoute() async {
    final route = await _readInitialNotificationRoute();
    if (!mounted || route == null || route.isEmpty) return;
    final isQuranReaderRoute = RegExp(
      r'^quran_reader:(\d+):(?:(\d+):)?(\d+)$',
    ).hasMatch(route);
    final routeName =
        isQuranReaderRoute
            ? '/quran-reader/${RegExp(r'^quran_reader:(\d+)').firstMatch(route)!.group(1)}'
            : null;
    final requestedRouteName =
        routeName ?? _notificationDestination(route)?.routeName;
    final alreadyAtRequestedDestination =
        requestedRouteName != null &&
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
        cubit.quranSoundActive &&
        cubit.surahNumber >= 1 &&
        cubit.surahNumber <= 114;
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
      'reciterAvatarAsset':
          hasTrack ? cubit.displayReciter.avatarAsset ?? '' : '',
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
    final surahNumber =
        cubit.surahNumber > 0
            ? cubit.surahNumber
            : (savedSurah is int ? savedSurah : 1).clamp(1, 114);
    final savedAyah = CacheHelper.getData(
      key: 'quran_last_played_ayah_$surahNumber',
    );
    final ayahNumber =
        cubit.surahNumber == surahNumber
            ? cubit.currentAyahNumber
            : savedAyah is int
            ? savedAyah
            : 1;
    _openQuranReaderFromWidget(
      surahNumber,
      ayahNumber,
      requestedPage:
          cubit.surahNumber == surahNumber
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
    final legacyWidgetMatch =
        widgetMatch == null
            ? RegExp(r'^quran_reader:(\d+):(\d+)$').firstMatch(route)
            : null;
    final readerMatch = widgetMatch ?? legacyWidgetMatch;
    if (readerMatch != null) {
      final surahNumber = int.tryParse(readerMatch.group(1) ?? '');
      final hasPage = widgetMatch != null;
      final pageNumber =
          hasPage ? int.tryParse(readerMatch.group(2) ?? '') : null;
      final ayahNumber = int.tryParse(readerMatch.group(hasPage ? 3 : 2) ?? '');
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
        routeName == '/quran-home' ||
        routeName == '/daily-wird' ||
        routeName == '/khatmah' ||
        routeName == '/home' ||
        routeName == '/quran-reader/18';
    // A reminder is a direct entry point. Rebuild the stack even if an older
    // copy of its route is already present; Home may have been pushed above
    // that copy during startup or while the app was backgrounded.
    if (isDailyReminderDestination) {
      if (routeName.startsWith('/azkar-category-') ||
          routeName == '/quran-home' ||
          routeName == '/daily-wird' ||
          routeName == '/khatmah') {
        navigator.pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/home'),
            builder: (_) => const StartUpScreen(),
          ),
          (_) => false,
        );
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
    final ayahNumber = requestedAyah.clamp(1, quran.getVerseCount(surahNumber));
    final correctPage = MushafLineLayoutData.pageNumber(
      surahNumber,
      ayahNumber,
    );
    final pageNumber =
        requestedPage == correctPage ? requestedPage : correctPage;
    final routeName = '/quran-reader/$surahNumber';
    // Keep an app entry route beneath notification-launched readers so Back
    // always returns to the app instead of dismissing the Activity.
    if (_appRouteObserver.currentRouteName == routeName) return;
    navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const StartUpScreen(),
      ),
      (_) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || appNavigatorKey.currentState != navigator) return;
      if (_appRouteObserver.currentRouteName == routeName) return;
      navigator.push<void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: routeName),
          builder:
              (_) => SurahScreen(
                surahNumber: surahNumber,
                initialAyah: ayahNumber,
                initialPageNumber: pageNumber,
              ),
        ),
      );
    });
  }
}
