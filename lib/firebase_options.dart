
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
    apiKey: 'AIzaSyCd2NTlslty08PFHWxdma13MIX95SqNJ6Q',
    appId: '1:722574944900:web:b0ced069d0f85bc20770d1',
    messagingSenderId: '722574944900',
    projectId: 'syncgroceries-330cf',
    authDomain: 'syncgroceries-330cf.firebaseapp.com',
    storageBucket: 'syncgroceries-330cf.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDU-DBbCEaJ08HbkA9CnosbUj_aF_4XQdc',
    appId: '1:722574944900:android:ed744a46f59ed5bf0770d1',
    messagingSenderId: '722574944900',
    projectId: 'syncgroceries-330cf',
    storageBucket: 'syncgroceries-330cf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkplfSCfiGtwBJRk89NEphh9nCUHqAGc8',
    appId: '1:722574944900:ios:404ff4c4d7cfd8660770d1',
    messagingSenderId: '722574944900',
    projectId: 'syncgroceries-330cf',
    storageBucket: 'syncgroceries-330cf.firebasestorage.app',
    iosBundleId: 'com.example.syncgroceries',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCkplfSCfiGtwBJRk89NEphh9nCUHqAGc8',
    appId: '1:722574944900:ios:404ff4c4d7cfd8660770d1',
    messagingSenderId: '722574944900',
    projectId: 'syncgroceries-330cf',
    storageBucket: 'syncgroceries-330cf.firebasestorage.app',
    iosBundleId: 'com.example.syncgroceries',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCd2NTlslty08PFHWxdma13MIX95SqNJ6Q',
    appId: '1:722574944900:web:2075323d5e24e6dc0770d1',
    messagingSenderId: '722574944900',
    projectId: 'syncgroceries-330cf',
    authDomain: 'syncgroceries-330cf.firebaseapp.com',
    storageBucket: 'syncgroceries-330cf.firebasestorage.app',
  );

}