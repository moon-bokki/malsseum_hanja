import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/app.dart';
import 'package:malsseum_hanja/data/models/verse.dart';
import 'package:malsseum_hanja/providers.dart';
import 'package:malsseum_hanja/views/splash/splash_screen.dart';
import 'package:malsseum_hanja/views/widgets/verse_text.dart';

import 'helpers/test_bible.dart';

void main() {
  testWidgets('홈 화면에 오늘의 말씀과 하단 탭이 보인다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(testBibleRepository()),
        ],
        child: const MalsseumHanjaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘의 말씀'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    // 맨 위에는 로고 머리글(assets/images/logo02.png)이 모든 탭에서 고정되어 보인다.
    expect(find.bySemanticsLabel('말씀한자 처음 화면으로'), findsOneWidget);
    for (final tab in ['성경', '단어장', '퀴즈', '마이']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('말씀한자 처음 화면으로'),
        findsOneWidget,
        reason: tab,
      );
    }
  });

  testWidgets('머리글 로고를 누르면 스플래시를 3초 보여 준 뒤 오늘 탭으로 간다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(testBibleRepository()),
        ],
        child: const MalsseumHanjaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('단어장'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('오늘의 말씀'), findsNothing);

    await tester.tap(find.bySemanticsLabel('말씀한자 처음 화면으로'));
    await tester.pump(); // 새 화면은 첫 프레임을 화면 밖에서 그린다
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SplashScreen), findsOneWidget);

    // 3초가 지나기 전에는 스플래시가 그대로 있다.
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('오늘의 말씀'), findsOneWidget);
  });

  test('findWordMatches 는 본문 속 한자어 위치를 순서대로 찾는다', () {
    final verse = Verse.fromJson({
      'id': 't',
      'book': '테스트',
      'chapter': 1,
      'verse': 1,
      'text': '은혜로 구원을 얻었으니 은혜라',
      'words': [
        {'korean': '구원', 'hanja': '救援', 'meaning': ''},
        {'korean': '은혜', 'hanja': '恩惠', 'meaning': ''},
      ],
    });

    final matches = findWordMatches(verse);

    expect(matches.map((m) => m.start), [0, 4, 13]);
    expect(matches.map((m) => m.word.korean), ['은혜', '구원', '은혜']);
  });
}
