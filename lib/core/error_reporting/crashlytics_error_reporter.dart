import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:muslim/firebase_options.dart';

/// Initializes Firebase Crashlytics and forwards uncaught Flutter errors.
///
/// No user identifiers, content, or other custom data are attached to reports.
abstract final class CrashlyticsErrorReporter {
  static bool _initialized = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      _initialized = true;
    } on FirebaseException {
      // Firebase platform configuration may not be present in local builds.
      // Keep startup available; handlers remain chained to Flutter defaults.
    } catch (_) {
      // Reporting must not prevent the app from starting.
    }

    final previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterErrorHandler?.call(details);
      if (_initialized) {
        unawaited(
          FirebaseCrashlytics.instance.recordFlutterFatalError(details),
        );
      } else if (previousFlutterErrorHandler == null) {
        FlutterError.presentError(details);
      }
    };

    final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_initialized) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
      }
      return previousPlatformErrorHandler?.call(error, stack) ?? false;
    };
  }

  /// Reports an explicitly handled error without marking it as fatal.
  static Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace,
    {
    String reason = 'Handled application error',
    Map<String, Object?> information = const {},
    }
  ) async {
    if (!_initialized) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      information: information.entries
          .where((entry) => entry.value != null)
          .map((entry) => '${entry.key}: ${entry.value}')
          .toList(growable: false),
      fatal: false,
    );
  }
}
