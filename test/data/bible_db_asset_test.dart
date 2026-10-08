import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/datasources/local/bible_database.dart';
import 'package:malsseum_hanja/data/datasources/local/local_bible_datasource.dart';
import 'package:malsseum_hanja/data/models/bible_book.dart';
import 'package:malsseum_hanja/data/models/bible_query.dart';
import 'package:malsseum_hanja/data/repositories/bible_repository.dart';
import 'package:sqlite3/sqlite3.dart';

/// 앱에 실제로 들어가는 assets/data/bible.db 를 검사한다.
/// (tool/fetch_krv.dart → tool/build_bible_db.dart 로 만든 파일)
void main() {
  late BibleDatabase db;
  late BibleRepository repo;

  setUpAll(() {
    final raw = sqlite3.open('assets/data/bible.db', mode: OpenMode.readOnly);
    db = BibleDatabase(NativeDatabase.opened(raw));
    repo = SqliteBibleRepository(db, LocalBibleDataSource());
  });
  tearDownAll(() => db.close());

  test('개역한글 66권 31,103절이 모두 들어 있다', () async {
    expect(await repo.countSearch(const BibleQuery()), 31103);
    final counts = await repo.getVerseCounts();
    expect(counts.keys, hasLength(66));
    for (final book in BibleBook.all) {
      expect(
        await repo.getAvailableChapters(book),
        hasLength(book.chapterCount),
        reason: book.name,
      );
    }
  });

  test('본문과 검토된 한자어가 함께 나온다', () async {
    final gen = await repo.getChapter(BibleBook.find('창')!, 1);
    expect(gen.first.text, '태초에 하나님이 천지를 창조하시니라');

    final john = await repo.search(const BibleQuery(text: '요 3:16'));
    expect(john.single.words.map((w) => w.hanja), contains('永生'));
  });

  test('한자어 사전이 전체 본문에 자동으로 연결되어 있다', () async {
    final gen = (await repo.getChapter(BibleBook.find('창')!, 1)).first;
    expect(gen.words.map((w) => w.hanja), ['太初', '天地', '創造']);

    // 에스겔의 '인자야' 는 人子, 시편의 '인자하심' 은 仁慈 로 정해진다.
    final ezk = await repo.getChapter(BibleBook.find('겔')!, 2);
    expect(ezk.first.words.map((w) => w.hanja), contains('人子'));
    final psa = await repo.search(const BibleQuery(text: '시 136:1'));
    expect(psa.single.words.map((w) => w.hanja), contains('仁慈'));

    // 검토가 필요한 연결(동음이의어)은 화면에 나오지 않는다.
    final words = await repo.getAllWords();
    expect(words.length, greaterThan(100));
  });

  test('전체 본문 검색: 구약/신약 필터와 장절 표기', () async {
    final all = await repo.countSearch(const BibleQuery(text: '은혜'));
    final oldT = await repo.countSearch(
      const BibleQuery(text: '은혜', testament: Testament.old),
    );
    final newT = await repo.countSearch(
      const BibleQuery(text: '은혜', testament: Testament.newT),
    );
    expect(all, greaterThan(100));
    expect(oldT + newT, all);

    final psalm = await repo.search(
      const BibleQuery(text: '시 119'),
      limit: 200,
    );
    expect(psalm, hasLength(176));
  });
}
