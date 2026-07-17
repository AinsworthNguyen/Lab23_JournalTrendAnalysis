import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDbw5YIFU27YFitQ_kXg673RJZH_XC9HbU',
    appId: '1:561393583256:web:dummy1234567890abcdef',
    messagingSenderId: '561393583256',
    projectId: 'journal-trend-analysis',
    authDomain: 'journal-trend-analysis.firebaseapp.com',
    storageBucket: 'journal-trend-analysis.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDbw5YIFU27YFitQ_kXg673RJZH_XC9HbU',
    appId: '1:561393583256:android:cdec6d5a2781846d77bced',
    messagingSenderId: '561393583256',
    projectId: 'journal-trend-analysis',
    storageBucket: 'journal-trend-analysis.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDbw5YIFU27YFitQ_kXg673RJZH_XC9HbU',
    appId: '1:561393583256:ios:dummy1234567890abcdef',
    messagingSenderId: '561393583256',
    projectId: 'journal-trend-analysis',
    storageBucket: 'journal-trend-analysis.firebasestorage.app',
    iosBundleId: 'com.fptu.journaltrend.journalTrendAnalysis',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDbw5YIFU27YFitQ_kXg673RJZH_XC9HbU',
    appId: '1:561393583256:ios:dummy1234567890abcdef',
    messagingSenderId: '561393583256',
    projectId: 'journal-trend-analysis',
    storageBucket: 'journal-trend-analysis.firebasestorage.app',
    iosBundleId: 'com.fptu.journaltrend.journalTrendAnalysis',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDbw5YIFU27YFitQ_kXg673RJZH_XC9HbU',
    appId: '1:561393583256:web:dummy1234567890abcdef',
    messagingSenderId: '561393583256',
    projectId: 'journal-trend-analysis',
    authDomain: 'journal-trend-analysis.firebaseapp.com',
    storageBucket: 'journal-trend-analysis.firebasestorage.app',
  );
}
