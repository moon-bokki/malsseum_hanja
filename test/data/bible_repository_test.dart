import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/models/bible_book.dart';
import 'package:malsseum_hanja/data/models/bible_query.dart';
import 'package:malsseum_hanja/data/models/verse.dart';
import 'package:malsseum_hanja/data/repositories/bible_repository.dart';

import '../helpers/test_bible.dart';

Verse verse(
  String book,
  int chapter,
  int v,
  String text, [
  List<Map<String, String>> words = const [],
]) => Verse.fromJson({
  'id': '${BibleBook.byName(book)!.code}-$chapter-$v',
  'book': book,
  'chapter': chapter,
  'verse': v,
  'text': text,
  'words': words,
});

final verses = [
  verse('요한복음', 3, 16, '하나님이 세상을 이처럼 사랑하사', [
    {'korean': '세상', 'hanja': '世上', 'meaning': ''},
  ]),
  verse('요한복음', 3, 17, '하나님이 그 아들을 세상에 보내신 것은'),
  verse('시편', 23, 1, '여호와는 나의 목자시니'),
  verse('에베소서', 2, 8, '그 은혜를 인하여 100%', [
    {'korean': '은혜', 'hanja': '恩惠', 'meaning': ''},
    {'korean': '세상', 'hanja': '世上', 'meaning': ''},
  ]),
];

void main() {
  late BibleRepository repo;
  setUp(() => repo = testBibleRepository(verses));

  Future<List<String>> refs(BibleQuery q) async => [
    for (final v in await repo.search(q)) v.reference,
  ];

  test('BibleBook 은 구약 39권 929장, 신약 27권 260장이다', () {
    int chapters(Testament t) =>
        BibleBook.of(t).fold(0, (sum, b) => sum + b.chapterCount);
    expect(BibleBook.of(Testament.old), hasLength(39));
    expect(BibleBook.of(Testament.newT), hasLength(27));
    expect(chapters(Testament.old), 929);
    expect(chapters(Testament.newT), 260);
  });

  test('BibleReference 는 여러 장절 표기를 읽는다', () {
    final r = BibleReference.parse('시 23장 1절')!;
    expect((r.book.name, r.chapter, r.verse), ('시편', 23, 1));
    expect(BibleReference.parse('요한복음 3')!.verse, isNull);
    expect(BibleReference.parse('은혜'), isNull);
    expect(BibleReference.parse('없는책 3:1'), isNull);
  });

  test('조건이 없으면 정경 순서로 정렬하고, 개수와 페이지를 나눈다', () async {
    expect(await refs(const BibleQuery()), [
      '시편 23:1',
      '요한복음 3:16',
      '요한복음 3:17',
      '에베소서 2:8',
    ]);
    expect(await repo.countSearch(const BibleQuery()), 4);
    final page = await repo.search(const BibleQuery(), limit: 2, offset: 1);
    expect(page.map((v) => v.reference), ['요한복음 3:16', '요한복음 3:17']);
  });

  test('구약/신약과 책으로 거른다', () async {
    expect(await refs(const BibleQuery(testament: Testament.old)), ['시편 23:1']);
    expect(await refs(BibleQuery(book: BibleBook.find('엡'))), ['에베소서 2:8']);
  });

  test('장절 표기와 약어로 찾는다', () async {
    expect(await refs(const BibleQuery(text: '요 3:16')), ['요한복음 3:16']);
    expect(await refs(const BibleQuery(text: '요한복음 3')), [
      '요한복음 3:16',
      '요한복음 3:17',
    ]);
    expect(await refs(const BibleQuery(text: '요 3:18')), isEmpty);
    expect(await refs(const BibleQuery(text: '시')), ['시편 23:1']);
  });

  test('본문, 한글 단어, 한자 단어로 찾고 LIKE 특수문자는 글자로 본다', () async {
    expect(await refs(const BibleQuery(text: '목자')), ['시편 23:1']);
    expect(await refs(const BibleQuery(text: '恩惠')), ['에베소서 2:8']);
    expect(await refs(const BibleQuery(text: '100%')), ['에베소서 2:8']);
    expect(await refs(const BibleQuery(text: '_')), isEmpty);
  });

  test('구절의 한자어는 본문 순서대로, 같은 단어는 한 번만 저장된다', () async {
    final eph = (await repo.getChapter(BibleBook.find('엡')!, 2)).single;
    expect(eph.words.map((w) => w.hanja), ['恩惠', '世上']);
    expect((await repo.getAllWords()).map((w) => w.hanja), ['世上', '恩惠']);
  });

  test('장 목록과 책별 구절 수', () async {
    expect(await repo.getAvailableChapters(BibleBook.find('요')!), {3});
    expect(await repo.getVerseCounts(), {19: 1, 43: 2, 49: 1});
  });

  test('오늘의 말씀은 날짜마다 목록을 차례로 돈다', () async {
    final day = DateTime(2026, 10, 7);
    final a = await repo.getTodayVerse(day);
    final b = await repo.getTodayVerse(day.add(const Duration(days: 1)));
    final c = await repo.getTodayVerse(day.add(const Duration(days: 4)));
    expect(a.id, isNot(b.id));
    expect(c.id, a.id);
  });
}
