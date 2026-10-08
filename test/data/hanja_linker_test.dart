import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/hanja_linker.dart';
import 'package:malsseum_hanja/data/hanja_matcher.dart';
import 'package:malsseum_hanja/data/models/hanja_word.dart';
import 'package:malsseum_hanja/data/models/verse.dart';

HanjaWord w(String korean, String hanja) =>
    HanjaWord(korean: korean, hanja: hanja, meaning: '');

Verse verse(String id, String text, [List<HanjaWord> words = const []]) =>
    Verse(id: id, book: '시편', chapter: 1, verse: 1, text: text, words: words);

final dictionary = [
  HanjaDictEntry(w('은혜', '恩惠')),
  HanjaDictEntry(w('제사', '祭祀')),
  HanjaDictEntry(w('제사장', '祭司長')),
  HanjaDictEntry(w('천하', '天下'), except: ['천하게']),
  HanjaDictEntry(w('인자', '仁慈'), forms: ['인자하']),
  HanjaDictEntry(w('인자', '人子'), forms: ['인자야']),
];

List<String> hanjaOf(HanjaLinks links, String id) => [
  for (final v in links.verses)
    if (v.id == id) ...v.words.map((w) => w.hanja),
];

void main() {
  group('matchWords', () {
    test('어절 첫머리에서만 찾는다', () {
      final m = matchWords('은혜를 받은 보은혜 은혜', ['은혜']);
      expect(m.map((x) => x.start), [0, 11]);
    });

    test('같은 자리에서는 긴 단어를 고른다', () {
      final m = matchWords('제사장이 제사를 드리니', ['제사', '제사장']);
      expect(m.map((x) => x.word), ['제사장', '제사']);
    });
  });

  group('linkHanjaWords', () {
    test('사전 단어를 모든 구절에 자동으로 붙인다', () {
      final links = linkHanjaWords([
        verse('A', '제사장이 은혜를 구하고 제사를 드리니'),
        verse('B', '여호와는 나의 목자시니'),
      ], dictionary);
      expect(hanjaOf(links, 'A'), ['祭司長', '恩惠', '祭祀']);
      expect(hanjaOf(links, 'B'), isEmpty);
      expect(links.unreviewed, isEmpty);
    });

    test('동음이의어는 forms 로 정하고, 정하지 못하면 검토 목록으로 보낸다', () {
      final links = linkHanjaWords([
        verse('A', '주의 인자하심이 크도다'),
        verse('B', '인자야 너는 일어서라'),
        verse('C', '인자가 온 것은'),
      ], dictionary);
      expect(hanjaOf(links, 'A'), ['仁慈']);
      expect(hanjaOf(links, 'B'), ['人子']);
      expect(hanjaOf(links, 'C'), isEmpty);
      expect(links.unreviewed['C']!.map((w) => w.hanja), ['仁慈', '人子']);
    });

    test('except 로 시작하는 어절이 있으면 그 구절에는 붙이지 않는다', () {
      final links = linkHanjaWords([
        verse('A', '천하에 두루 다니며'),
        verse('B', '천하게 여기며 천하를 다스리고'),
      ], dictionary);
      expect(hanjaOf(links, 'A'), ['天下']);
      expect(hanjaOf(links, 'B'), isEmpty);
    });

    test('손으로 넣은 단어가 우선이고, exclude 로 뺄 수 있다', () {
      final links = linkHanjaWords(
        [
          verse('A', '인자가 온 것은', [w('인자', '人子')]),
          verse('B', '은혜를 받고 제사를 드리니'),
        ],
        dictionary,
        exclude: {
          'B': {'은혜'},
        },
      );
      expect(hanjaOf(links, 'A'), ['人子']);
      expect(links.unreviewed.containsKey('A'), isFalse);
      expect(hanjaOf(links, 'B'), ['祭祀']);
    });
  });
}
