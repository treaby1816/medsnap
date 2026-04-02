// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated for Project ID: vailmeds-74e4b
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAPLmjEA4tjB81avFtAY5VCtK18nP1hHdc', // Updated from json
    appId: '1:870868324526:web:0a5c8a728f38d91a129d3f', 
    messagingSenderId: '870868324526', // Updated from json
    projectId: 'vailmeds-74e4b', // Updated from json
    authDomain: 'vailmeds-74e4b.firebaseapp.com',
    storageBucket: 'vailmeds-74e4b.firebasestorage.app', // Updated from json
    measurementId: 'G-2YL2TJHKPH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPLmjEA4tjB81avFtAY5VCtK18nP1hHdc', // Updated from json
    appId: '1:870868324526:android:2358e09d22d071a7129d3f', // Updated from json
    messagingSenderId: '870868324526', // Updated from json
    projectId: 'vailmeds-74e4b', // Updated from json
    storageBucket: 'vailmeds-74e4b.firebasestorage.app', // Updated from json
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAPLmjEA4tjB81avFtAY5VCtK18nP1hHdc', // Updated from json
    appId: '1:870868324526:ios:d299dae5096e3865056026', // Updated from json
    messagingSenderId: '870868324526', // Updated from json
    projectId: 'vailmeds-74e4b', // Updated from json
    storageBucket: 'vailmeds-74e4b.firebasestorage.app', // Updated from json
    iosBundleId: 'com.vailmeds.v2',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAPLmjEA4tjB81avFtAY5VCtK18nP1hHdc', // Updated from json
    appId: '1:870868324526:ios:d299dae5096e3865056026', // Updated from json
    messagingSenderId: '870868324526', // Updated from json
    projectId: 'vailmeds-74e4b', // Updated from json
    storageBucket: 'vailmeds-74e4b.firebasestorage.app', // Updated from json
    iosBundleId: 'com.vailmeds.v2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAPLmjEA4tjB81avFtAY5VCtK18nP1hHdc', // Updated from json
    appId: '1:870868324526:web:80c44c52e09d22d071a712', // Updated from json
    messagingSenderId: '870868324526', // Updated from json
    projectId: 'vailmeds-74e4b', // Updated from json
    authDomain: 'vailmeds-74e4b.firebaseapp.com',
    storageBucket: 'vailmeds-74e4b.firebasestorage.app', // Updated from json
  );
}
