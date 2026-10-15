import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.preloadFonts();

  if (AppConfig.useFirebase) {
    // 옵션은 `flutterfire configure --project=bible-hanja` 가 만든 파일에서 읽는다.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    // 웹 푸시는 서비스 워커·VAPID 키 설정이 따로 필요해 아직 쓰지 않는다.
    if (!kIsWeb) {
      try {
        await PushNotificationService().init(
          onForegroundMessage: (title, body) => scaffoldMessengerKey
              .currentState
              ?.showSnackBar(SnackBar(content: Text('$title\n$body'))),
        );
      } catch (e) {
        // 알림 권한·토큰 오류가 나도 앱(단어장 동기화)은 그대로 쓸 수 있게 한다.
        debugPrint('푸시 알림 초기화 실패: $e');
      }
    }
  }

  runApp(const ProviderScope(child: MalsseumHanjaApp()));
}
