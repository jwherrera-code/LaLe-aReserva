import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyArc5EQiW8vJK0kzlwXAzZK_0B1w0WxiGc',
    appId: '1:557544647477:web:9669472a32e31acfa37a7c',
    messagingSenderId: '557544647477',
    projectId: 'db-proyecto-39251',
    authDomain: 'db-proyecto-39251.firebaseapp.com',
    storageBucket: 'db-proyecto-39251.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYB3ioiFz9WPZvsPIu87pmy4sx212RGlw',
    appId: '1:557544647477:android:8bf2f6f83fd4fdcaa37a7c',
    messagingSenderId: '557544647477',
    projectId: 'db-proyecto-39251',
    storageBucket: 'db-proyecto-39251.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCFK3UL7sJG3U5HAFOXec9lGRZdUanopSM',
    appId: '1:557544647477:ios:1cb5d17c56138705a37a7c',
    messagingSenderId: '557544647477',
    projectId: 'db-proyecto-39251',
    storageBucket: 'db-proyecto-39251.firebasestorage.app',
    iosBundleId: 'com.example.appEmpresa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCFK3UL7sJG3U5HAFOXec9lGRZdUanopSM',
    appId: '1:557544647477:ios:1cb5d17c56138705a37a7c',
    messagingSenderId: '557544647477',
    projectId: 'db-proyecto-39251',
    storageBucket: 'db-proyecto-39251.firebasestorage.app',
    iosBundleId: 'com.example.appEmpresa',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyArc5EQiW8vJK0kzlwXAzZK_0B1w0WxiGc',
    appId: '1:557544647477:web:e7fe77d29414ddeaa37a7c',
    messagingSenderId: '557544647477',
    projectId: 'db-proyecto-39251',
    authDomain: 'db-proyecto-39251.firebaseapp.com',
    storageBucket: 'db-proyecto-39251.firebasestorage.app',
  );
}