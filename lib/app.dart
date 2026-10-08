import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'views/main_shell.dart';

/// 포그라운드 푸시 알림을 SnackBar 로 띄우기 위한 전역 키.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MalsseumHanjaApp extends StatelessWidget {
  const MalsseumHanjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '말씀한자',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const MainShell(),
    );
  }
}
