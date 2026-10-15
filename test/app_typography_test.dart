import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/app.dart';

void main() {
  test('지나치게 큰 줄 간격·자간·글자 배율은 거르고, 접근성 범위 값은 둔다', () {
    // 카카오톡 인앱 브라우저에서 잘못 계산된 값 (줄 높이가 6배로 늘어남).
    final broken = sanitizeTypography(
      const MediaQueryData(
        lineHeightScaleFactorOverride: 6.25,
        letterSpacingOverride: 100,
        wordSpacingOverride: 100,
        paragraphSpacingOverride: 100,
        textScaler: TextScaler.linear(3),
      ),
    );
    expect(broken.lineHeightScaleFactorOverride, isNull);
    expect(broken.letterSpacingOverride, isNull);
    expect(broken.wordSpacingOverride, isNull);
    expect(broken.paragraphSpacingOverride, isNull);
    expect(broken.textScaler.scale(10), 16); // 1.6배까지만

    // WCAG 텍스트 간격 설정 정도는 그대로 적용한다.
    final accessible = sanitizeTypography(
      const MediaQueryData(
        lineHeightScaleFactorOverride: 1.5,
        letterSpacingOverride: 1.9,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    expect(accessible.lineHeightScaleFactorOverride, 1.5);
    expect(accessible.letterSpacingOverride, 1.9);
    expect(accessible.textScaler.scale(10), closeTo(13, 0.001));
  });
}
