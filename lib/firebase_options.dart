// Generated Firebase options from google-services.json
// Run `flutterfire configure` to regenerate if you add more platforms.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not supported for ${defaultTargetPlatform.name}');
    }
  }

  // WARNING: Replace with your actual Firebase config values
  // Do NOT commit real API keys to version control
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY_HERE',
    appId: '1:571434079074:android:ad1d082052ec842ee2523b',
    messagingSenderId: '571434079074',
    projectId: 'packlite-32bb6',
    storageBucket: 'packlite-32bb6.firebasestorage.app',
  );

  // WARNING: Replace with your actual Firebase config values
  // Do NOT commit real API keys to version control
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY_HERE',
    appId: '1:571434079074:ios:000000000000000000000000',
    messagingSenderId: '571434079074',
    projectId: 'packlite-32bb6',
    storageBucket: 'packlite-32bb6.firebasestorage.app',
    iosBundleId: 'com.packlite.packlite',
  );
}
