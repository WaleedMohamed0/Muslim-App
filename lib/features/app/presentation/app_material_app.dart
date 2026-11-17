part of 'muslim_app.dart';

extension _AppMaterialAppConfiguration on _MyAppState {
  MaterialApp _buildMaterialApp(ThemeMode themeMode) {
    final initialDestination = _notificationDestination(
      widget.initialNotificationRoute ?? '',
    );
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      navigatorObservers: [
        _appRouteObserver,
        DiagnosticContext.analyticsObserver,
        dailyWirdRouteObserver,
      ],
      builder: (context, child) {
        final theme =
            themeMode == ThemeMode.dark ? AppTheme.dark : AppTheme.light;
        return BlocBuilder<QuranCubit, QuranState>(
          builder:
              (context, _) => AnimatedBuilder(
                animation: _activeRouteName,
                builder: (context, _) {
                  final isReaderRoute =
                      _activeRouteName.value?.startsWith('/quran-reader/') ??
                      false;
                  final quranCubit = context.read<QuranCubit>();
                  final isDark = theme.brightness == Brightness.dark;
                  final readerBackground =
                      isDark
                          ? quranCubit.darkReaderBackgroundColorValue
                          : quranCubit.lightReaderBackgroundColorValue;
                  final insetColor =
                      isReaderRoute
                          ? Color(
                            readerBackground ??
                                QuranReaderBackgroundColors.defaultFor(
                                  isDark,
                                ).toARGB32(),
                          )
                          : quranCubit.quranSoundActive
                          ? theme.colorScheme.surface
                          : theme.scaffoldBackgroundColor;
                  return ColoredBox(
                    color: insetColor,
                    child: DismissKeyboardOnOutsideTap(
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
                    initialDestination.routeName == '/quran-home' ||
                    initialDestination.routeName == '/daily-wird' ||
                    initialDestination.routeName.startsWith(
                      '/quran-reader/',
                    ))) ...[
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
                settings: RouteSettings(name: initialDestination.routeName),
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
