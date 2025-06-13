import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default Firebase configuration options for the current platform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCjdvnpDIYnLUHIGh94j4nsLXmqsbkGXsY',
    appId: '1:695369766912:android:3c84020514c056b80760e5',
    messagingSenderId: '695369766912',
    projectId: 'ispeedscan-4edc4',
    storageBucket: 'ispeedscan-4edc4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBVtRujTrW2EZrxy1wTMCv7V0PCPEEzYwQ',
    appId: '1:274796257208:ios:f9be4f45e48fc8dc0db94d',
    messagingSenderId: '274796257208',
    projectId: 'ispeedscanios',
    storageBucket: 'ispeedscanios.firebasestorage.app',
  );
}
