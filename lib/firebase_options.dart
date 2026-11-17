import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options derived from the registered Android and iOS app configs.
/// Regenerate with `flutterfire configure` when Firebase apps change.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtqxxeDDeUVbq28MGZl6MTrR9G6LX8iPc',
    appId: '1:363027229688:android:6b1451eebe77c40ea4040d',
    messagingSenderId: '363027229688',
    projectId: 'muslim-8ff5c',
    storageBucket: 'muslim-8ff5c.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBegBByC85MT3ZirbyTsE9qy6WVgB-L5cg',
    appId: '1:363027229688:ios:58a13a17bec21d25a4040d',
    messagingSenderId: '363027229688',
    projectId: 'muslim-8ff5c',
    storageBucket: 'muslim-8ff5c.firebasestorage.app',
    iosBundleId: 'com.waleed.muslimapp',
  );
}
