// ⚠️ PLACEHOLDER Firebase configuration — committed on purpose so that a
// fresh clone of this repository compiles and its tests can run.
//
// Every value below is FAKE. Before building or shipping the app you must
// replace this file with your real configuration:
//
//   1. Create a Firebase project at https://console.firebase.google.com and
//      register your app (Android, iOS and/or Web).
//   2. Install the FlutterFire CLI (https://firebase.google.com/docs/flutter/setup)
//      and run `flutterfire configure` from the project root. This overwrites
//      this file with your real options.
//   3. If you would rather not keep your (client-side, publicly visible)
//      Firebase keys in git, run `git rm --cached lib/firebase_options.dart`
//      and re-add the line for it under "Firebase config" in .gitignore.
//
// Note: Firebase web API keys and app IDs are not secrets — they ship in
// every built APK/IPA/web bundle — but they are still tied to a billing
// project, so don't commit your real ones casually.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '$defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER_REPLACE_ME_ANDROID',
    appId: '1:1111111111:android:0000000000000000000000',
    messagingSenderId: '1111111111',
    projectId: 'awesomenotes-placeholder',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER_REPLACE_ME_IOS',
    appId: '1:1111111111:ios:0000000000000000000000',
    messagingSenderId: '1111111111',
    projectId: 'awesomenotes-placeholder',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER_REPLACE_ME_WEB',
    appId: '1:1111111111:web:0000000000000000000000',
    messagingSenderId: '1111111111',
    projectId: 'awesomenotes-placeholder',
  );
}
