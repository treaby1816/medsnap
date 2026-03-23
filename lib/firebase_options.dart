// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
    apiKey: 'AIzaSyD7FgvoF_1pULuB_0WgbbbCQmN6jt6u2jM',
    appId: '1:119669105875:web:d6673fc00ddb7199056026',
    messagingSenderId: '119669105875',
    projectId: 'vail-meds',
    authDomain: 'vail-meds.firebaseapp.com',
    storageBucket: 'vail-meds.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgXkksw0t5AvFJ4ZjKI-eOtArqQ12XEqA',
    appId: '1:119669105875:android:bdafcd4b5177e3a4056026',
    messagingSenderId: '119669105875',
    projectId: 'vail-meds',
    storageBucket: 'vail-meds.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC0My3uywSISZECAhKbSExoJuGp2zQ15Xk',
    appId: '1:119669105875:ios:d299dae5096e3865056026',
    messagingSenderId: '119669105875',
    projectId: 'vail-meds',
    storageBucket: 'vail-meds.firebasestorage.app',
    iosBundleId: 'com.example.vailMedsV2',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC0My3uywSISZECAhKbSExoJuGp2zQ15Xk',
    appId: '1:119669105875:ios:d299dae5096e3865056026',
    messagingSenderId: '119669105875',
    projectId: 'vail-meds',
    storageBucket: 'vail-meds.firebasestorage.app',
    iosBundleId: 'com.example.vailMedsV2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD7FgvoF_1pULuB_0WgbbbCQmN6jt6u2jM',
    appId: '1:119669105875:web:dea77e25c52c15ea056026',
    messagingSenderId: '119669105875',
    projectId: 'vail-meds',
    authDomain: 'vail-meds.firebaseapp.com',
    storageBucket: 'vail-meds.firebasestorage.app',
  );
}