import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/app.dart';
import 'package:malsseum_hanja/providers.dart';

import '../helpers/test_bible.dart';

void main() {
  Future<void> openBibleTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(testBibleRepository()),
        ],
        child: const MalsseumHanjaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('성경'));
    await tester.pumpAndSettle();
  }

  testWidgets('처음에는 66권 책이 모두 보이고, 구약/신약으로 거를 수 있다', (tester) async {
    await openBibleTab(tester);

    expect(find.text('구약 · 39권'), findsOneWidget);
    expect(find.text('신약 · 27권'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(66));

    await tester.tap(find.widgetWithText(ChoiceChip, '신약'));
    await tester.pumpAndSettle();
    expect(find.text('구약 · 39권'), findsNothing);
    expect(find.byType(FilterChip), findsNWidgets(27));
  });

  testWidgets('검색어를 넣으면 결과 표가 나오고 행을 누르면 그 장이 열린다', (tester) async {
    await openBibleTab(tester);

    expect(find.byType(DataTable), findsNothing);

    await tester.enterText(find.byType(SearchBar).first, '은혜');
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('검색 결과 1개'), findsOneWidget);

    // 검색 결과 본문에도 한자어가 병기되고, 한자 병기를 끄면 한글만 남는다.
    Finder inTable(String text) => find.descendant(
      of: find.byType(DataTable),
      matching: find.textContaining(text, findRichText: true),
    );
    expect(inTable('은혜(恩惠)를 인하여'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(inTable('은혜(恩惠)'), findsNothing);
    expect(inTable('그 은혜를 인하여'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar).first, '요 3:16');
    await tester.pumpAndSettle();
    expect(find.text('검색 결과 1개'), findsOneWidget);

    await tester.tap(find.text('3:16'));
    await tester.pumpAndSettle();
    expect(find.text('요한복음 3장'), findsOneWidget);
    expect(find.text('요한복음 3:16'), findsOneWidget);

    // 검색에서 고른 구절은 선택된 상태로 열리고, 그 구절의 한자어 카드가 보인다.
    expect(find.text('이 구절의 한자어 4'), findsOneWidget);
    expect(find.text('獨生子'), findsOneWidget);

    // 구절을 다시 누르면 선택이 풀리고 카드가 사라진다.
    await tester.tap(find.text('요한복음 3:16'));
    await tester.pumpAndSettle();
    expect(find.text('이 구절의 한자어 4'), findsNothing);
  });

  testWidgets('책을 고르면 장 번호 표가 나오고, 본문이 있는 장만 누를 수 있다', (tester) async {
    await openBibleTab(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, '신약'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '마태복음'));
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsNothing);
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('마태복음 · 28장'), findsOneWidget);
    InkWell cellOf(String n) => tester.widget(
      find.ancestor(of: find.text(n), matching: find.byType(InkWell)).first,
    );
    expect(cellOf('1').onTap, isNull); // 샘플 데이터에는 4장만 있다
    expect(cellOf('4').onTap, isNotNull);

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    expect(find.text('마태복음 4장'), findsOneWidget);

    // 뒤로 와서 '다른 책'을 누르면 책 목록으로 돌아간다.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('다른 책'));
    await tester.pumpAndSettle();
    expect(find.byType(Table), findsNothing);
    expect(find.text('신약 · 27권'), findsOneWidget);
  });
}
