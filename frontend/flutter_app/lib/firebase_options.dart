import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // For now, fallback to web config if running on other platforms
    // to avoid crashes during development before full native setup.
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBzMWXnJWOGKrbak1XL0tf8F3mOq0cIm-0',
    appId: '1:31939447971:web:7c94a17db59c8353acc316',
    messagingSenderId: '31939447971',
    projectId: 'tailorsync-dd5e3',
    authDomain: 'tailorsync-dd5e3.firebaseapp.com',
    storageBucket: 'tailorsync-dd5e3.firebasestorage.app',
    measurementId: 'G-QZSR4RB7F8',
  );
}
