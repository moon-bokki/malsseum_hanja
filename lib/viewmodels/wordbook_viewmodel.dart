import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/saved_word.dart';
import '../providers.dart';

class WordbookViewModel extends StreamNotifier<List<SavedWord>> {
  @override
  Stream<List<SavedWord>> build() =>
      ref.watch(wordbookRepositoryProvider).watchWords();

  Future<void> remove(String korean) =>
      ref.read(wordbookRepositoryProvider).remove(korean);
}

final wordbookViewModelProvider =
    StreamNotifierProvider<WordbookViewModel, List<SavedWord>>(
      WordbookViewModel.new,
    );

enum WordbookSort {
  recent('최근 저장순'),
  mostWrong('많이 틀린 순'),
  korean('가나다순');

  const WordbookSort(this.label);

  final String label;
}

/// 단어장 화면의 검색어와 정렬.
class WordbookFilter {
  const WordbookFilter({this.query = '', this.sort = WordbookSort.recent});

  final String query;
  final WordbookSort sort;
}

class WordbookFilterViewModel extends Notifier<WordbookFilter> {
  @override
  WordbookFilter build() => const WordbookFilter();

  void setQuery(String query) =>
      state = WordbookFilter(query: query, sort: state.sort);

  void setSort(WordbookSort sort) =>
      state = WordbookFilter(query: state.query, sort: sort);
}

final wordbookFilterProvider =
    NotifierProvider<WordbookFilterViewModel, WordbookFilter>(
      WordbookFilterViewModel.new,
    );

/// 한글 또는 한자로 거르고 정렬한다.
List<SavedWord> filterWordbook(List<SavedWord> words, WordbookFilter filter) {
  final q = filter.query.trim();
  final result = [
    for (final w in words)
      if (q.isEmpty || w.word.korean.contains(q) || w.word.hanja.contains(q)) w,
  ];
  switch (filter.sort) {
    case WordbookSort.recent:
      result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    case WordbookSort.mostWrong:
      result.sort((a, b) {
        final c = b.wrongCount.compareTo(a.wrongCount);
        return c != 0 ? c : a.word.korean.compareTo(b.word.korean);
      });
    case WordbookSort.korean:
      result.sort((a, b) => a.word.korean.compareTo(b.word.korean));
  }
  return result;
}
