import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/app.dart';
import 'package:malsseum_hanja/data/models/verse.dart';
import 'package:malsseum_hanja/providers.dart';
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
