import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Placeholder Firebase configuration. Replace values by running:
/// flutterfire configure
/// or set manually below for Android/iOS/Web.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDigGRpRIGGfaQgXTEHXszwYfTKM3qUhqI',
        appId: '1:847309936408:web:75852f0682dad52bbcf06d',
        messagingSenderId: '847309936408',
        projectId: 'devxdiary0',
        storageBucket: 'devxdiary0.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyDigGRpRIGGfaQgXTEHXszwYfTKM3qUhqI',
          appId: '1:847309936408:android:devxdiary0',
          messagingSenderId: '847309936408',
          projectId: 'devxdiary0',
          storageBucket: 'devxdiary0.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyDigGRpRIGGfaQgXTEHXszwYfTKM3qUhqI',
          appId: '1:847309936408:ios:devxdiary0',
          messagingSenderId: '847309936408',
          projectId: 'devxdiary0',
          storageBucket: 'devxdiary0.firebasestorage.app',
          iosBundleId: 'com.example.devxDiaryFlutter',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyDigGRpRIGGfaQgXTEHXszwYfTKM3qUhqI',
          appId: '1:847309936408:macos:devxdiary0',
          messagingSenderId: '847309936408',
          projectId: 'devxdiary0',
          storageBucket: 'devxdiary0.firebasestorage.app',
          iosBundleId: 'com.example.devxDiaryFlutter',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }
}
