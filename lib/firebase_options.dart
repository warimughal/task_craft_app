// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCQXZaQKsYA0stPZYNGindL_9kC3wyqxmQ',
    appId: '1:86915118133:web:956bf5a24d5012bfb32d7c',
    messagingSenderId: '86915118133',
    projectId: 'project-management-tool-a690d',
    authDomain: 'project-management-tool-a690d.firebaseapp.com',
    storageBucket: 'project-management-tool-a690d.appspot.com',
    measurementId: 'G-RWQYKNBP5W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC83YvL1I1wAcCW1WriwKlENVpwthXnETQ',
    appId: '1:86915118133:android:2cf0e4e9a7ff8fb6b32d7c',
    messagingSenderId: '86915118133',
    projectId: 'project-management-tool-a690d',
    storageBucket: 'project-management-tool-a690d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCC0om_t9QQCqUngEQNf4wnyU9ARuLaHQ0',
    appId: '1:86915118133:ios:4df3abd49ecd25edb32d7c',
    messagingSenderId: '86915118133',
    projectId: 'project-management-tool-a690d',
    storageBucket: 'project-management-tool-a690d.appspot.com',
    iosBundleId: 'com.example.taskCraftApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCC0om_t9QQCqUngEQNf4wnyU9ARuLaHQ0',
    appId: '1:86915118133:ios:7d1721981c35a73bb32d7c',
    messagingSenderId: '86915118133',
    projectId: 'project-management-tool-a690d',
    storageBucket: 'project-management-tool-a690d.appspot.com',
    iosBundleId: 'com.example.taskCraftApp.RunnerTests',
  );
}