import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bible_db_schema.dart';
import 'bible_db_file.dart'
    if (dart.library.js_interop) 'bible_db_file_web.dart';

const _assetPath = 'assets/data/bible.db';

/// 앱에 내장된 bible.db (읽기 전용). 테이블은 bible_db_schema.dart 참고.
///
/// 코드 생성 없이 customSelect 로 SQL 을 직접 쓴다.
class BibleDatabase extends GeneratedDatabase {
  BibleDatabase(super.executor);

  /// 기기: 처음 실행할 때 asset 을 앱 저장소로 복사해서 연다.
  /// 웹: 브라우저 저장소에 asset 내용으로 DB 를 만든다 (web/sqlite3.wasm 필요).
  factory BibleDatabase.open() {
    final name = 'bible_v$bibleDataVersion';
    return BibleDatabase(
      driftDatabase(
        name: name,
        native: DriftNativeOptions(
          databasePath: () => copyBibleAsset(name, _loadAsset),
        ),
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
          initializeDatabase: _loadAsset,
        ),
      ),
    );
  }

  static Future<Uint8List> _loadAsset() async =>
      (await rootBundle.load(_assetPath)).buffer.asUint8List();

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  /// DB 는 미리 만들어져 있으므로 drift 가 테이블을 만들지 않게 한다.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async =>
        debugPrint('bible.db 가 비어 있습니다. tool/build_bible_db.dart 를 실행하세요.'),
  );
}
