import 'package:sqlite3/common.dart';

import '../../models/bible_book.dart';
import '../../models/hanja_word.dart';
import '../../models/verse.dart';

/// 앱에 내장하는 bible.db 의 버전. 데이터를 다시 만들면 올린다.
/// (기기에 복사해 둔 이전 버전 DB 대신 새 파일을 쓰게 된다.)
const bibleDataVersion = 3;

/// bible.db 스키마. tool/build_bible_db.dart 와 테스트가 함께 쓴다.
///
/// - verses:       본문 (개역한글). book 은 정경 순서 1~66.
/// - words:        한자어 사전. 같은 단어는 한 번만 저장한다.
/// - verse_words:  구절 ↔ 한자어 연결. reviewed = 0 이면 앱에 보이지 않는다.
/// - daily_verses: 오늘의 말씀 목록 (Firestore verses 의 order 와 같은 순서).
const _schema = '''
CREATE TABLE verses (
  id      TEXT PRIMARY KEY,
  book    INTEGER NOT NULL,
  chapter INTEGER NOT NULL,
  verse   INTEGER NOT NULL,
  text    TEXT NOT NULL
);
CREATE INDEX verses_ref ON verses (book, chapter, verse);

CREATE TABLE words (
  id      INTEGER PRIMARY KEY,
  korean  TEXT NOT NULL,
  hanja   TEXT NOT NULL,
  meaning TEXT NOT NULL,
  UNIQUE (korean, hanja)
);

CREATE TABLE verse_words (
  verse_id TEXT NOT NULL REFERENCES verses (id),
  word_id  INTEGER NOT NULL REFERENCES words (id),
  position INTEGER NOT NULL,
  reviewed INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (verse_id, word_id)
);
CREATE INDEX verse_words_word ON verse_words (word_id);

CREATE TABLE daily_verses (
  ord      INTEGER PRIMARY KEY,
  verse_id TEXT NOT NULL REFERENCES verses (id)
);
''';

/// 빈 DB 에 스키마를 만들고 구절·한자어·오늘의 말씀 목록을 넣는다.
///
/// [verses] 의 words 는 검토를 마친 한자어로 저장된다(reviewed = 1).
/// [unreviewed] (구절 id → 한자어) 는 검토가 필요한 연결로 저장되어 앱에 보이지 않는다
/// (reviewed = 0, 예: 동음이의어 인자 仁慈/人子).
/// drift 가 마이그레이션을 다시 돌리지 않도록 user_version 을 1 로 맞춘다.
void buildBibleDb(
  CommonDatabase db, {
  required List<Verse> verses,
  required List<String> dailyVerseIds,
  Map<String, List<HanjaWord>> unreviewed = const {},
}) {
  db.execute('BEGIN');
  db.execute(_schema);

  final insertVerse = db.prepare(
    'INSERT INTO verses (id, book, chapter, verse, text) VALUES (?, ?, ?, ?, ?)',
  );
  final insertWord = db.prepare(
    'INSERT INTO words (korean, hanja, meaning) VALUES (?, ?, ?) '
    'ON CONFLICT (korean, hanja) DO NOTHING',
  );
  final findWord = db.prepare(
    'SELECT id FROM words WHERE korean = ? AND hanja = ?',
  );
  final linkWord = db.prepare(
    'INSERT OR IGNORE INTO verse_words (verse_id, word_id, position, reviewed) '
    'VALUES (?, ?, ?, ?)',
  );

  void link(String verseId, HanjaWord w, int position, {required bool ok}) {
    insertWord.execute([w.korean, w.hanja, w.meaning]);
    final wordId = findWord.select([w.korean, w.hanja]).first['id'];
    linkWord.execute([verseId, wordId, position, ok ? 1 : 0]);
  }

  for (final v in verses) {
    final book =
        BibleBook.byName(v.book) ??
        (throw ArgumentError('알 수 없는 책 이름: ${v.book} (${v.id})'));
    insertVerse.execute([v.id, book.number, v.chapter, v.verse, v.text]);
    for (final (i, w) in v.words.indexed) {
      link(v.id, w, i, ok: true);
    }
    for (final (i, w) in (unreviewed[v.id] ?? const <HanjaWord>[]).indexed) {
      link(v.id, w, v.words.length + i, ok: false);
    }
  }

  final insertDaily = db.prepare(
    'INSERT INTO daily_verses (ord, verse_id) VALUES (?, ?)',
  );
  for (final (i, id) in dailyVerseIds.indexed) {
    insertDaily.execute([i, id]);
  }

  for (final s in [insertVerse, insertWord, findWord, linkWord, insertDaily]) {
    s.close();
  }
  db.execute('COMMIT');
  db.userVersion = 1;
}
