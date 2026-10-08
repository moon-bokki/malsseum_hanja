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

    // 다음 글자로 가면 惠 의 훈음이 나오고, 마치기를 누르면 닫힌다.
    await tester.tap(find.text('다음 글자'));
    await tester.pumpAndSettle();
    expect(find.textContaining('은혜 혜', findRichText: true), findsOneWidget);
    await tester.tap(find.text('마치기'));
    await tester.pumpAndSettle();
    expect(find.text('쓰기 연습'), findsNothing);
  });
}
