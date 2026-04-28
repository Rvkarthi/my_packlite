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

  // Values from google-services.json — client with package_name: com.packlite.packlite
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmmfaJ4XP23eNZByQflieKuNzVHOo2XRs',
    appId: '1:571434079074:android:ad1d082052ec842ee2523b',
    messagingSenderId: '571434079074',
    projectId: 'packlite-32bb6',
    storageBucket: 'packlite-32bb6.firebasestorage.app',
  );

  // Placeholder — add GoogleService-Info.plist and update these values for iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAmmfaJ4XP23eNZByQflieKuNzVHOo2XRs',
    appId: '1:571434079074:ios:000000000000000000000000',
    messagingSenderId: '571434079074',
    projectId: 'packlite-32bb6',
    storageBucket: 'packlite-32bb6.firebasestorage.app',
    iosBundleId: 'com.packlite.packlite',
  );
}
