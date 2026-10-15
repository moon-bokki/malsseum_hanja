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
      builder: (context, child) => MediaQuery(
        data: sanitizeTypography(MediaQuery.of(context)),
        child: child!,
      ),
      home: const MainShell(),
    );
  }
}

/// 웹에서 브라우저가 알려 주는 글자 설정 중 화면을 깨뜨리는 값을 거른다.
///
/// Flutter 웹은 브라우저의 줄 간격·자간·글자 크기 설정을 읽어 앱에 적용한다.
/// 그런데 카카오톡 인앱 브라우저처럼 글자 크기를 자체 조정하는 브라우저에서는
/// 줄 간격 배율이 몇 배로 잘못 계산되어, 모든 줄이 매우 높아지고 화면 아래가 잘린다.
/// 접근성 기준(WCAG 1.4.12: 줄 간격 1.5배, 자간 0.12em …) 범위의 값은 그대로 두고,
/// 그보다 지나치게 큰 값만 무시한다. 글자 크기 배율도 1.6배까지만 쓴다.
MediaQueryData sanitizeTypography(MediaQueryData data) {
  double? within(double? value, double max) =>
      value != null && value <= max ? value : null;
  return data
      .applyTextStyleOverrides(
        lineHeightScaleFactorOverride: within(
          data.lineHeightScaleFactorOverride,
          2.0,
        ),
        letterSpacingOverride: within(data.letterSpacingOverride, 4),
        wordSpacingOverride: within(data.wordSpacingOverride, 8),
        paragraphSpacingOverride: within(data.paragraphSpacingOverride, 32),
      )
      .copyWith(
        textScaler: data.textScaler.clamp(
          minScaleFactor: 1,
          maxScaleFactor: 1.6,
        ),
      );
}
