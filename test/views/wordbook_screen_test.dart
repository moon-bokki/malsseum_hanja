import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/app.dart';
import 'package:malsseum_hanja/data/models/hanja_word.dart';
import 'package:malsseum_hanja/data/repositories/wordbook_repository.dart';
import 'package:malsseum_hanja/providers.dart';

import '../helpers/test_bible.dart';

void main() {
  testWidgets('단어장에서 단어를 누르면 오른쪽에서 쓰기 연습 패널이 나온다', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);

    final wordbook = InMemoryWordbookRepository();
    await wordbook.save(
      const HanjaWord(korean: '은혜', hanja: '恩惠', meaning: ''),
      '에베소서 2:8',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(testBibleRepository()),
          wordbookRepositoryProvider.overrideWithValue(wordbook),
        ],
        child: const MalsseumHanjaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('단어장'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('은혜'));
    await tester.pumpAndSettle();
    expect(find.text('쓰기 연습'), findsOneWidget);
    expect(find.textContaining('은혜 은', findRichText: true), findsOneWidget);

    // 칸에 그리면 '한 획 지우기' 가 켜진다.
    final undo = find.ancestor(
      of: find.text('한 획 지우기'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(undo).onTap, isNull);
    await tester.drag(
      find.byKey(const ValueKey('writing-pad')),
      const Offset(60, 40),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(undo).onTap, isNotNull);

    // '구성원리' 를 누르면 恩 의 자원 풀이 창이 나온다 (assets/data/hanja_origin.json).
    await tester.tap(find.widgetWithText(OutlinedButton, '구성원리'));
    await tester.pumpAndSettle();
    expect(find.text('회의문자'), findsOneWidget);
    expect(find.textContaining('因(인할 인)자와 心(마음 심)자'), findsOneWidget);
    expect(find.textContaining('출처: 한자로드'), findsOneWidget);
    expect(find.text('네이버 한자사전에서 그림 보기'), findsOneWidget);
    expect(find.byType(Image), findsNothing); // 이미지는 앱에서 직접 불러오지 않는다
    await tester.tapAt(const Offset(10, 10)); // 창 바깥을 눌러 닫는다
    await tester.pumpAndSettle();
    expect(find.text('회의문자'), findsNothing);

    // 다음 글자로 가면 惠 의 훈음이 나오고, 마치기를 누르면 닫힌다.
    await tester.tap(find.text('다음 글자'));
    await tester.pumpAndSettle();
    expect(find.textContaining('은혜 혜', findRichText: true), findsOneWidget);
    await tester.tap(find.text('마치기'));
    await tester.pumpAndSettle();
    expect(find.text('쓰기 연습'), findsNothing);
  });
}
