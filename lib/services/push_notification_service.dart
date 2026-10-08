import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';

/// 앱이 종료/백그라운드 상태일 때 수신한 메시지 처리 (시스템 알림은 OS 가 표시).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// FCM 푸시 알림. 오늘의 말씀은 Cloud Functions 가 [AppConfig.dailyVerseTopic]
/// 토픽으로 매일 아침 발송한다 (functions/index.js 참고).
class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<void> init({
    required void Function(String title, String body) onForegroundMessage,
  }) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _messaging.requestPermission();
    debugPrint('FCM token: ${await _messaging.getToken()}');

    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n != null) onForegroundMessage(n.title ?? '', n.body ?? '');
    });
  }

  Future<void> setDailyVerseEnabled(bool enabled) => enabled
      ? _messaging.subscribeToTopic(AppConfig.dailyVerseTopic)
      : _messaging.unsubscribeFromTopic(AppConfig.dailyVerseTopic);
}
