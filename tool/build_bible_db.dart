// 앱에 내장할 assets/data/bible.db 를 만든다.
//
//   dart run tool/build_bible_db.dart
//
// 입력
//   tool/data/bible_text.tsv     개역한글 전체 본문 (tool/fetch_krv.dart 로 받는다). 한 줄에 한 절:
//                                책코드<TAB>장<TAB>절<TAB>본문   예) JHN	3	16	하나님이 …
//   tool/data/verses.json        손으로 검토한 구절별 한자어 (오늘의 말씀 목록도 이 순서)
//   tool/data/hanja_words.json   한자어 사전. 본문에서 찾아 모든 구절에 자동으로 붙인다.
//   tool/data/hanja_exclude.json (선택) 잘못 붙는 단어 빼기: {"구절id": ["한글", …]}
//
// 출력
//   assets/data/bible.db         앱에 들어가는 DB
//   tool/data/hanja_report.tsv   단어별 연결 구절 수와 상태 (검토용, 스프레드시트로 열기)
//   tool/data/hanja_review.tsv   검토가 필요한 구절 목록 (동음이의어)
//
// bible_text.tsv 가 없으면 verses.json 의 구절만 넣는다.
// 데이터를 바꿔 다시 만들면 lib/.../bible_db_schema.dart 의 bibleDataVersion 을 올린다.
import 'dart:convert';
import 'dart:io';

import 'package:malsseum_hanja/data/datasources/local/bible_db_schema.dart';
import 'package:malsseum_hanja/data/hanja_linker.dart';
import 'package:malsseum_hanja/data/models/bible_book.dart';
import 'package:malsseum_hanja/data/models/hanja_word.dart';
import 'package:malsseum_hanja/data/models/verse.dart';
import 'package:sqlite3/sqlite3.dart';

const _annotatedPath = 'tool/data/verses.json';
const _fullTextPath = 'tool/data/bible_text.tsv';
const _dictionaryPath = 'tool/data/hanja_words.json';
const _excludePath = 'tool/data/hanja_exclude.json';
const _reportPath = 'tool/data/hanja_report.tsv';
const _reviewPath = 'tool/data/hanja_review.tsv';
const _outPath = 'assets/data/bible.db';

void main() {
  final annotated = (_readJson(_annotatedPath) as List)
      .map((e) => Verse.fromJson(e as Map<String, dynamic>))
      .toList();

  final fullText = File(_fullTextPath);
  final base = fullText.existsSync()
      ? _mergeWords(_readFullText(fullText), annotated)
      : annotated;

  final dictionary = (_readJson(_dictionaryPath) as List)
      .map((e) => HanjaDictEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  final exclude = File(_excludePath).existsSync()
      ? (_readJson(_excludePath) as Map<String, dynamic>).map(
          (id, words) => MapEntry(id, {...(words as List).cast<String>()}),
        )
      : const <String, Set<String>>{};

  final links = linkHanjaWords(base, dictionary, exclude: exclude);

  final out = File(_outPath);
  if (out.existsSync()) out.deleteSync();
  final db = sqlite3.open(_outPath);
  buildBibleDb(
    db,
    verses: links.verses,
    dailyVerseIds: [for (final v in annotated) v.id],
    unreviewed: links.unreviewed,
  );
  db.execute('VACUUM');
  db.close();

  _writeReports(links, dictionary);

  final withWords = links.verses.where((v) => v.words.isNotEmpty).length;
  final words = {for (final v in links.verses) ...v.words}.length;
  stdout.writeln(
    '$_outPath 생성 (${out.lengthSync()} bytes)\n'
    '  구절 ${links.verses.length}개 중 한자어가 표시되는 구절 $withWords개 '
    '(${(withWords * 100 / links.verses.length).toStringAsFixed(1)}%)\n'
    '  표시되는 한자어 $words개, 검토 필요한 구절 ${links.unreviewed.length}개\n'
    '  보고서: $_reportPath, $_reviewPath',
  );
}

Object? _readJson(String path) => jsonDecode(File(path).readAsStringSync());

/// 단어별 연결 수 보고서와 검토 목록을 쓴다.
void _writeReports(HanjaLinks links, List<HanjaDictEntry> dictionary) {
  final shown = <HanjaWord, int>{};
  for (final v in links.verses) {
    for (final w in v.words) {
      shown[w] = (shown[w] ?? 0) + 1;
    }
  }
  final pending = <HanjaWord, int>{};
  for (final words in links.unreviewed.values) {
    for (final w in words) {
      pending[w] = (pending[w] ?? 0) + 1;
    }
  }

  final rows = [
    for (final w in {for (final e in dictionary) e.word, ...shown.keys})
      (w, shown[w] ?? 0, pending[w] ?? 0),
  ]..sort((a, b) => (b.$2 + b.$3).compareTo(a.$2 + a.$3));
  File(_reportPath).writeAsStringSync(
    [
      '한글\t한자\t표시 구절 수\t검토 필요 구절 수\t상태',
      for (final (w, ok, review) in rows)
        '${w.korean}\t${w.hanja}\t$ok\t$review\t'
            '${review > 0
                ? '검토 필요 (동음이의어)'
                : ok == 0
                ? '본문에 없음'
                : '자동 연결'}',
    ].join('\n'),
  );

  final byId = {for (final v in links.verses) v.id: v};
  File(_reviewPath).writeAsStringSync(
    [
      '구절 id\t구절\t한글\t한자 후보\t본문',
      for (final MapEntry(key: id, value: words) in links.unreviewed.entries)
        for (final korean in {for (final w in words) w.korean})
          '$id\t${byId[id]!.reference}\t$korean\t'
              '${words.where((w) => w.korean == korean).map((w) => w.hanja).join(' / ')}\t'
              '${byId[id]!.text}',
    ].join('\n'),
  );
}

List<Verse> _readFullText(File file) {
  final verses = <Verse>[];
  for (final (i, line) in file.readAsLinesSync().indexed) {
    if (line.trim().isEmpty) continue;
    final cols = line.split('\t');
    final book = cols.length == 4 ? BibleBook.byCode(cols[0].trim()) : null;
    if (book == null) {
      throw FormatException('$_fullTextPath:${i + 1} 형식 오류: $line');
    }
    final chapter = int.parse(cols[1]);
    final verse = int.parse(cols[2]);
    verses.add(
      Verse(
        id: '${book.code}-$chapter-$verse',
        book: book.name,
        chapter: chapter,
        verse: verse,
        text: cols[3].trim(),
        words: const [],
      ),
    );
  }
  return verses;
}

/// 전체 본문에 손으로 검토한 한자어를 붙인다. 본문이 다르면 경고만 하고 전체 본문을 쓴다.
List<Verse> _mergeWords(List<Verse> fullText, List<Verse> annotated) {
  final byId = {for (final v in annotated) v.id: v};
  final ids = {for (final v in fullText) v.id};
  for (final id in byId.keys.where((id) => !ids.contains(id))) {
    stderr.writeln('경고: $_annotatedPath 의 $id 가 전체 본문에 없습니다.');
  }
  return [
    for (final v in fullText)
      if (byId[v.id] case final a?) _withWords(v, a) else v,
  ];
}

Verse _withWords(Verse text, Verse annotated) {
  if (annotated.text != text.text) {
    stderr.writeln('경고: ${text.id} 본문이 다릅니다. 전체 본문을 사용합니다.');
  }
  return Verse(
    id: text.id,
    book: text.book,
    chapter: text.chapter,
    verse: text.verse,
    text: text.text,
    words: annotated.words,
  );
}
