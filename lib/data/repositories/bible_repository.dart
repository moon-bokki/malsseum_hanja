import 'package:drift/drift.dart';

import '../datasources/local/bible_database.dart';
import '../datasources/local/local_bible_datasource.dart';
import '../models/bible_book.dart';
import '../models/bible_query.dart';
import '../models/hanja_char.dart';
import '../models/hanja_word.dart';
import '../models/verse.dart';

abstract class BibleRepository {
  /// 한 장의 구절을 절 순서로.
  Future<List<Verse>> getChapter(BibleBook book, int chapter);

  /// 본문이 들어 있는 장 번호.
  Future<Set<int>> getAvailableChapters(BibleBook book);

  /// 책별 구절 수 (키: [BibleBook.number]). 본문이 없는 책은 빠진다.
  Future<Map<int, int>> getVerseCounts();

  /// 검색 조건에 맞는 구절을 정경 순서로 [offset] 부터 [limit] 개.
  Future<List<Verse>> search(
    BibleQuery query, {
    int limit = 100,
    int offset = 0,
  });

  Future<int> countSearch(BibleQuery query);

  /// 오늘의 말씀 목록에서 날짜마다 한 구절씩 돌아가며 고른다.
  Future<Verse> getTodayVerse(DateTime date);

  Future<List<HanjaChar>> getHanjaChars(HanjaWord word);

  /// 검토를 마친 한자어 전체.
  Future<List<HanjaWord>> getAllWords();
}

class SqliteBibleRepository implements BibleRepository {
  SqliteBibleRepository(this._db, this._local);

  final BibleDatabase _db;
  final LocalBibleDataSource _local;

  static const _columns = 'v.id, v.book, v.chapter, v.verse, v.text';

  @override
  Future<List<Verse>> getChapter(BibleBook book, int chapter) => _selectVerses(
    'SELECT $_columns FROM verses v WHERE v.book = ? AND v.chapter = ? '
    'ORDER BY v.verse',
    [book.number, chapter],
  );

  @override
  Future<Set<int>> getAvailableChapters(BibleBook book) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT chapter FROM verses WHERE book = ?',
          variables: [Variable.withInt(book.number)],
        )
        .get();
    return {for (final r in rows) r.read<int>('chapter')};
  }

  @override
  Future<Map<int, int>> getVerseCounts() async {
    final rows = await _db
        .customSelect('SELECT book, COUNT(*) AS n FROM verses GROUP BY book')
        .get();
    return {for (final r in rows) r.read<int>('book'): r.read<int>('n')};
  }

  @override
  Future<List<Verse>> search(
    BibleQuery query, {
    int limit = 100,
    int offset = 0,
  }) {
    final (where, args) = _where(query);
    return _selectVerses(
      'SELECT $_columns FROM verses v WHERE $where '
      'ORDER BY v.book, v.chapter, v.verse LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );
  }

  @override
  Future<int> countSearch(BibleQuery query) async {
    final (where, args) = _where(query);
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM verses v WHERE $where',
          variables: _vars(args),
        )
        .getSingle();
    return row.read<int>('n');
  }

  @override
  Future<Verse> getTodayVerse(DateTime date) async {
    final dayIndex =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final verses = await _selectVerses(
      'SELECT $_columns FROM verses v '
      'JOIN daily_verses d ON d.verse_id = v.id '
      'WHERE d.ord = ? % (SELECT COUNT(*) FROM daily_verses)',
      [dayIndex],
    );
    if (verses.isEmpty) throw StateError('오늘의 말씀 목록이 비어 있습니다.');
    return verses.single;
  }

  @override
  Future<List<HanjaChar>> getHanjaChars(HanjaWord word) async {
    final chars = await _local.loadHanjaChars();
    return [
      for (final c in word.chars)
        chars[c] ?? HanjaChar(char: c, hun: '?', eum: '?'),
    ];
  }

  @override
  Future<List<HanjaWord>> getAllWords() async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT w.korean, w.hanja, w.meaning '
          'FROM words w JOIN verse_words vw ON vw.word_id = w.id '
          'WHERE vw.reviewed = 1 ORDER BY w.id',
        )
        .get();
    return [for (final r in rows) _word(r)];
  }

  /// 검색 조건을 WHERE 절로 바꾼다.
  (String, List<Object>) _where(BibleQuery query) {
    final clauses = <String>[];
    final args = <Object>[];

    if (query.book != null) {
      clauses.add('v.book = ?');
      args.add(query.book!.number);
    } else if (query.testament != null) {
      final books = BibleBook.of(query.testament!);
      clauses.add('v.book BETWEEN ? AND ?');
      args.addAll([books.first.number, books.last.number]);
    }

    final text = query.text.trim();
    final ref = BibleReference.parse(text);
    if (ref != null) {
      clauses.add('v.book = ? AND v.chapter = ?');
      args.addAll([ref.book.number, ref.chapter]);
      if (ref.verse != null) {
        clauses.add('v.verse = ?');
        args.add(ref.verse!);
      }
    } else if (text.isNotEmpty) {
      // 책 이름(약어 포함), 본문, 검토된 한글/한자 단어 중 하나라도 맞으면 된다.
      final like = '%${_escapeLike(text)}%';
      final books = [
        for (final b in BibleBook.all)
          if (b.name.contains(text) || b.abbr == text) b.number,
      ];
      final bookClause = books.isEmpty
          ? ''
          : 'v.book IN (${books.map((_) => '?').join(',')}) OR ';
      clauses.add(
        '($bookClause'
        r"v.text LIKE ? ESCAPE '\' OR v.id IN ("
        'SELECT vw.verse_id FROM verse_words vw '
        'JOIN words w ON w.id = vw.word_id WHERE vw.reviewed = 1 AND '
        r"(w.korean LIKE ? ESCAPE '\' OR w.hanja LIKE ? ESCAPE '\')))",
      );
      args.addAll([...books, like, like, like]);
    }

    return (clauses.isEmpty ? '1' : clauses.join(' AND '), args);
  }

  static String _escapeLike(String s) =>
      s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');

  Future<List<Verse>> _selectVerses(String sql, List<Object> args) async {
    final rows = await _db.customSelect(sql, variables: _vars(args)).get();
    if (rows.isEmpty) return const [];

    final ids = [for (final r in rows) r.read<String>('id')];
    final words = await _wordsFor(ids);
    return [
      for (final r in rows)
        Verse(
          id: r.read<String>('id'),
          book: BibleBook.byNumber(r.read<int>('book')).name,
          chapter: r.read<int>('chapter'),
          verse: r.read<int>('verse'),
          text: r.read<String>('text'),
          words: words[r.read<String>('id')] ?? const [],
        ),
    ];
  }

  /// 구절별 검토된 한자어를 본문에 나오는 순서대로.
  Future<Map<String, List<HanjaWord>>> _wordsFor(List<String> verseIds) async {
    final rows = await _db
        .customSelect(
          'SELECT vw.verse_id, w.korean, w.hanja, w.meaning '
          'FROM verse_words vw JOIN words w ON w.id = vw.word_id '
          'WHERE vw.reviewed = 1 AND vw.verse_id IN '
          '(${verseIds.map((_) => '?').join(',')}) '
          'ORDER BY vw.verse_id, vw.position',
          variables: _vars(verseIds),
        )
        .get();
    final result = <String, List<HanjaWord>>{};
    for (final r in rows) {
      (result[r.read<String>('verse_id')] ??= []).add(_word(r));
    }
    return result;
  }

  static HanjaWord _word(QueryRow r) => HanjaWord(
    korean: r.read<String>('korean'),
    hanja: r.read<String>('hanja'),
    meaning: r.read<String>('meaning'),
  );

  static List<Variable> _vars(List<Object> args) => [
    for (final a in args)
      a is int ? Variable.withInt(a) : Variable.withString(a as String),
  ];
}
