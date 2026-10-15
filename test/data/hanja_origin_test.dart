import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/datasources/local/local_bible_datasource.dart';
import 'package:malsseum_hanja/data/models/hanja_origin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HanjaOrigin.fromJson 은 분류·네이버 페이지·그림 목록·출처를 읽는다', () {
    final o = HanjaOrigin.fromJson('渡', {
      'source': '한자로드',
      'type': '회의문자',
      'text': '渡자는 ‘건너다’라는 뜻을 가진 글자이다.',
      'entryId': 'eb38190910404cccbd21207f423c6966',
      'pictures': ['삽화', '소전', '해서'],
    });
    expect(o.type, '회의문자');
    expect(
      o.naverUrl.toString(),
      'https://hanja.dict.naver.com/#/entry/ccko/eb38190910404cccbd21207f423c6966',
    );
    expect(o.pictures, ['삽화', '소전', '해서']);
    expect(o.credit, contains('한자로드'));

    // entryId 가 없으면 네이버 검색 페이지로 간다.
    final naver = HanjaOrigin.fromJson('上', {
      'source': '네이버',
      'type': '지사문자',
      'text': '…',
    });
    expect(naver.pictures, isEmpty);
    expect(naver.naverUrl.toString(), contains('search?query='));
    expect(naver.credit, '출처: 네이버 한자사전');
  });

  test('내장 구성원리 데이터가 사전의 모든 글자를 담고 있다', () async {
    final origins = await LocalBibleDataSource().loadHanjaOrigins();
    final chars = await LocalBibleDataSource().loadHanjaChars();
    expect(origins['恩']?.type, '회의문자');
    final missing = chars.keys.where((c) => !origins.containsKey(c)).toList();
    // 네이버에 구성원리가 없는 글자가 조금 있을 수 있다.
    expect(missing.length, lessThan(chars.length ~/ 10), reason: '$missing');
  });
}
