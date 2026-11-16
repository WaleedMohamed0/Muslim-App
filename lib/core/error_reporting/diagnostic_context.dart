import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Shared, privacy-safe diagnostics for navigation and meaningful app actions.
abstract final class DiagnosticContext {
  static String? _currentScreen;

  static Future<void> setCurrentScreen(String screen) async {
    if (screen == _currentScreen) return;
    _currentScreen = screen;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCustomKey('current_screen', screen);
      await crashlytics.log('Navigation: $screen');
    } catch (_) {
      // Diagnostics must never interfere with navigation.
    }
  }

  static void log(String message) {
    unawaited(() async {
      try {
        await FirebaseCrashlytics.instance.log(message);
      } catch (_) {}
    }());
  }

  static Future<void> reportHandledError({
    required Object error,
    required StackTrace stackTrace,
    required String reason,
    Map<String, Object?> information = const {},
  }) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        information: information.entries
            .where((entry) => entry.value != null)
            .map((entry) => '${entry.key}: ${entry.value}')
            .toList(growable: false),
        fatal: false,
      );
    } catch (_) {}
  }

  static String analyticsRouteName(String? routeName) {
    if (routeName == null || routeName.isEmpty) return 'unknown';
    final path = routeName.split('?').first;
    if (path.startsWith('/quran-reader/')) return 'quran_reader';
    if (path.startsWith('/azkar-category-')) return 'azkar_category';
    if (path.startsWith('/')) {
      final name = path.substring(1).replaceAll('-', '_');
      return name.length > 36 ? name.substring(0, 36) : name;
    }
    return 'screen';
  }

  static FirebaseAnalyticsObserver get analyticsObserver =>
      FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
        nameExtractor: (settings) => analyticsRouteName(settings.name),
      );
}
