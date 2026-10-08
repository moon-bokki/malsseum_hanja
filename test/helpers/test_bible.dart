import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/datasources/local/bible_database.dart';
import 'package:malsseum_hanja/data/datasources/local/bible_db_schema.dart';
import 'package:malsseum_hanja/data/datasources/local/local_bible_datasource.dart';
import 'package:malsseum_hanja/data/models/verse.dart';
import 'package:malsseum_hanja/data/repositories/bible_repository.dart';
import 'package:sqlite3/sqlite3.dart';

/// tool/data/verses.json 의 검토된 구절 (bible.db 를 만드는 원본과 같다).
List<Verse> sampleVerses() =>
    (jsonDecode(File('tool/data/verses.json').readAsStringSync()) as List)
        .map((e) => Verse.fromJson(e as Map<String, dynamic>))
        .toList();

/// bible.db 와 같은 스키마로 만든 메모리 DB. 테스트가 끝나면 닫힌다.
BibleDatabase openTestBibleDatabase([List<Verse>? verses]) {
  final v = verses ?? sampleVerses();
  final raw = sqlite3.openInMemory();
  buildBibleDb(raw, verses: v, dailyVerseIds: [for (final x in v) x.id]);
  final db = BibleDatabase(NativeDatabase.opened(raw));
  addTearDown(db.close);
  return db;
}

SqliteBibleRepository testBibleRepository([List<Verse>? verses]) =>
    SqliteBibleRepository(
      openTestBibleDatabase(verses),
      LocalBibleDataSource(),
    );
