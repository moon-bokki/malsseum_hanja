import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/views/splash/splash_screen.dart';

void main() {
  const app = MaterialApp(home: Scaffold(body: Text('홈 화면')));

  testWidgets('준비가 끝날 때까지 스플래시를 보여 주고, 끝나면 앱으로 넘어간다', (tester) async {
    final ready = Completer<void>();
    await tester.pumpWidget(
      SplashGate(
        initialize: () => ready.future,
        minimumDuration: Duration.zero,
        child: app,
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('말씀한자'), findsOneWidget); // 로고
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('홈 화면'), findsNothing);

    ready.complete();
    await tester.pumpAndSettle();
    expect(find.text('홈 화면'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('준비에 실패하면 다시 시도 버튼을 보여 주고, 누르면 다시 준비한다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      SplashGate(
        initialize: () async {
          calls++;
          if (calls == 1) throw Exception('network');
        },
        minimumDuration: Duration.zero,
        child: app,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('홈 화면'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('홈 화면'), findsOneWidget);
  });
}
