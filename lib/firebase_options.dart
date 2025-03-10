import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  ///Note : Values available android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6irw7hQQVQAkBTwikrJ5Sg_cZoACg6MY',
    appId: '1:215579898202:android:6af2263b7cd73685e24363',
    messagingSenderId: '215579898202',
    projectId: 'streamit-laravel-flutter',
    storageBucket: 'streamit-laravel-flutter.appspot.com',
  );

  ///Note : Values available ios/Runner/GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWjF4CG7ieCMDMG8rx1yPxSg8ll-GQj5Y',
    appId: '1:215579898202:ios:817645a0fa6e94f2e24363',
    messagingSenderId: '215579898202',
    projectId: 'streamit-laravel-flutter',
    storageBucket: 'streamit-laravel-flutter.appspot.com',
    iosBundleId: 'com.iqonic.streamitlaravel',
  );
}
