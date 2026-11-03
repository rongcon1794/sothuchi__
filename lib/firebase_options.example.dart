// Tệp mẫu tham khảo.
// Chạy lệnh `flutterfire configure` ở thư mục gốc dự án để sinh tự động `lib/firebase_options.dart`.
// Lưu ý: Trên Android & iOS, `Firebase.initializeApp()` cũng tự động đọc cấu hình gốc
// từ `android/app/google-services.json` và `ios/Runner/GoogleService-Info.plist`.
// Bạn có thể truyền thêm `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` nếu cần chỉ định Web Client ID.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptionsExample {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'REPLACE_VIA_FLUTTERFIRE_CONFIGURE',
          appId: '1:000000000000:android:0000000000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'your-firebase-project-id',
          storageBucket: 'your-firebase-project-id.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'REPLACE_VIA_FLUTTERFIRE_CONFIGURE',
          appId: '1:000000000000:ios:0000000000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'your-firebase-project-id',
          storageBucket: 'your-firebase-project-id.firebasestorage.app',
          iosBundleId: 'vn.sothuchi.soThuChi',
          iosClientId:
              '000000000000-youriosclientid.apps.googleusercontent.com',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptionsExample chỉ hỗ trợ Android và iOS.',
        );
    }
  }
}

