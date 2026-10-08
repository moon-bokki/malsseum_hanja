import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_book.dart';
import '../data/models/bible_query.dart';
import '../data/models/verse.dart';
import '../providers.dart';

/// 본문에 한자 병기 표시 여부: 은혜 ↔ 은혜(恩惠)
class ShowHanjaViewModel extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final showHanjaProvider = NotifierProvider<ShowHanjaViewModel, bool>(
  ShowHanjaViewModel.new,
);

/// 성경 탭의 검색/탐색 조건.
class BibleSearchViewModel extends Notifier<BibleQuery> {
  @override
  BibleQuery build() => const BibleQuery();

  void setText(String text) => state = BibleQuery(
    text: text,
    testament: state.testament,
    book: state.book,
  );

  /// 구약/신약을 바꾸면 선택한 책은 해제한다.
  void setTestament(Testament? testament) =>
      state = BibleQuery(text: state.text, testament: testament);

  void selectBook(BibleBook? book) => state = BibleQuery(
    text: state.text,
    testament: book?.testament ?? state.testament,
    book: book,
  );
}

final bibleSearchProvider = NotifierProvider<BibleSearchViewModel, BibleQuery>(
  BibleSearchViewModel.new,
);

class SearchResults {
  const SearchResults(this.verses, this.total);

  final List<Verse> verses;
  final int total;

  bool get hasMore => verses.length < total;
}

/// 검색 결과를 [pageSize] 개씩 불러온다.
class SearchResultsViewModel extends AsyncNotifier<SearchResults> {
  static const pageSize = 100;

  @override
  Future<SearchResults> build() async {
    final query = ref.watch(bibleSearchProvider);
    final repo = ref.watch(bibleRepositoryProvider);
    final (verses, total) = await (
      repo.search(query, limit: pageSize),
      repo.countSearch(query),
    ).wait;
    return SearchResults(verses, total);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final query = ref.read(bibleSearchProvider);
    final more = await ref
        .read(bibleRepositoryProvider)
        .search(query, limit: pageSize, offset: current.verses.length);
    // 불러오는 사이 검색어가 바뀌었으면 버린다.
    if (!ref.mounted || ref.read(bibleSearchProvider) != query) return;
    state = AsyncData(
      SearchResults([...current.verses, ...more], current.total),
    );
  }
}

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsViewModel, SearchResults>(
      SearchResultsViewModel.new,
    );

/// 책별 구절 수 (키: [BibleBook.number]).
final verseCountsProvider = FutureProvider<Map<int, int>>(
  (ref) => ref.watch(bibleRepositoryProvider).getVerseCounts(),
);

/// 본문이 들어 있는 장 번호.
final availableChaptersProvider = FutureProvider.family<Set<int>, BibleBook>(
  (ref, book) => ref.watch(bibleRepositoryProvider).getAvailableChapters(book),
);

/// 한 장의 구절.
final chapterProvider = FutureProvider.family<List<Verse>, (BibleBook, int)>((
  ref,
  arg,
) {
  final (book, chapter) = arg;
  return ref.watch(bibleRepositoryProvider).getChapter(book, chapter);
});

/// '에베소서 2:8' 같은 구절 표기로 구절 하나를 찾는다. 없으면 null.
final verseByRefProvider = FutureProvider.family<Verse?, String>((
  ref,
  reference,
) async {
  final parsed = BibleReference.parse(reference);
  if (parsed == null || parsed.verse == null) return null;
  final verses = await ref
      .watch(bibleRepositoryProvider)
      .getChapter(parsed.book, parsed.chapter);
  for (final v in verses) {
    if (v.verse == parsed.verse) return v;
  }
  return null;
});
