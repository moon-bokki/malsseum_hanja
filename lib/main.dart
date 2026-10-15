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
import 'views/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 준비(글꼴·Firebase)가 끝날 때까지 스플래시 화면을 보여 준 뒤 앱을 띄운다.
  runApp(
    const ProviderScope(
      child: SplashGate(initialize: _initialize, child: MalsseumHanjaApp()),
    ),
  );
}

bool _pushInitialized = false;

/// 앱 시작 준비. 실패하면 스플래시의 '다시 시도'로 다시 불리므로 여러 번 불려도 안전해야 한다.
Future<void> _initialize() async {
  await AppTheme.preloadFonts();

  if (AppConfig.useFirebase) {
    // 옵션은 `flutterfire configure --project=bible-hanja` 가 만든 파일에서 읽는다.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    // 웹 푸시는 서비스 워커·VAPID 키 설정이 따로 필요해 아직 쓰지 않는다.
    if (!kIsWeb && !_pushInitialized) {
      _pushInitialized = true;
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
}
