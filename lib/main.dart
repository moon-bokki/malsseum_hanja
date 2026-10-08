import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.preloadFonts();

  if (AppConfig.useFirebase) {
    // `flutterfire configure` 실행 후에는 아래처럼 옵션을 넘긴다:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp();
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await PushNotificationService().init(
      onForegroundMessage: (title, body) => scaffoldMessengerKey.currentState
          ?.showSnackBar(SnackBar(content: Text('$title\n$body'))),
    );
  }

  runApp(const ProviderScope(child: MalsseumHanjaApp()));
}
