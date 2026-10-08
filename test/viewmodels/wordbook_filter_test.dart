import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/models/hanja_word.dart';
import 'package:malsseum_hanja/data/models/saved_word.dart';
import 'package:malsseum_hanja/viewmodels/wordbook_viewmodel.dart';

SavedWord saved(
  String korean,
  String hanja, {
  required int day,
  int wrong = 0,
}) => SavedWord(
  word: HanjaWord(korean: korean, hanja: hanja, meaning: ''),
  verseRef: '',
  savedAt: DateTime(2026, 10, day),
  wrongCount: wrong,
);

final words = [
  saved('은혜', '恩惠', day: 1, wrong: 0),
  saved('회개', '悔改', day: 3, wrong: 2),
  saved('구원', '救援', day: 2, wrong: 1),
];

List<String> korean(WordbookFilter f) => [
  for (final w in filterWordbook(words, f)) w.word.korean,
];

void main() {
  test('정렬: 최근 저장순, 많이 틀린 순, 가나다순', () {
    expect(korean(const WordbookFilter()), ['회개', '구원', '은혜']);
    expect(korean(const WordbookFilter(sort: WordbookSort.mostWrong)), [
      '회개',
      '구원',
      '은혜',
    ]);
    expect(korean(const WordbookFilter(sort: WordbookSort.korean)), [
      '구원',
      '은혜',
      '회개',
    ]);
  });

  test('한글 또는 한자로 찾는다', () {
    expect(korean(const WordbookFilter(query: '은')), ['은혜']);
    expect(korean(const WordbookFilter(query: '救')), ['구원']);
    expect(korean(const WordbookFilter(query: '없음')), isEmpty);
  });
}
