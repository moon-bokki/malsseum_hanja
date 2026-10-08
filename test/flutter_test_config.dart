import 'dart:async';

import 'package:malsseum_hanja/core/theme/app_theme.dart';

/// 모든 테스트 전에 실행된다. 테스트에서는 네트워크 글꼴(google_fonts)을 쓰지 않는다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppTheme.useGoogleFonts = false;
  await testMain();
}
