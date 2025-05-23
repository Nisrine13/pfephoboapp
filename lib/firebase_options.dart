// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyCpA3gesinDe0cUsHDzAbcLHhZhaD1E-Q0',
    appId: '1:767227048847:web:c05cc6a206d71b0a2591fa',
    messagingSenderId: '767227048847',
    projectId: 'pfeprojetphobo',
    authDomain: 'pfeprojetphobo.firebaseapp.com',
    measurementId: 'G-NG222MNDL6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBxIA_vqXdRbYHloFIq9h_QLdj7Uz159WY',
    appId: '1:767227048847:android:ce4b052403f4a1042591fa',
    messagingSenderId: '767227048847',
    projectId: 'pfeprojetphobo',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCIttcuvXKrrtScwpCjeoNBZZb3TLDR2w8',
    appId: '1:767227048847:ios:beb225c19e693a922591fa',
    messagingSenderId: '767227048847',
    projectId: 'pfeprojetphobo',
    iosBundleId: 'com.nisrine.monapp.pfephoboapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCIttcuvXKrrtScwpCjeoNBZZb3TLDR2w8',
    appId: '1:767227048847:ios:beb225c19e693a922591fa',
    messagingSenderId: '767227048847',
    projectId: 'pfeprojetphobo',
    iosBundleId: 'com.nisrine.monapp.pfephoboapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCpA3gesinDe0cUsHDzAbcLHhZhaD1E-Q0',
    appId: '1:767227048847:web:b7fae026059fb04c2591fa',
    messagingSenderId: '767227048847',
    projectId: 'pfeprojetphobo',
    authDomain: 'pfeprojetphobo.firebaseapp.com',
    measurementId: 'G-FHM4RBLT5J',
  );
}