import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/datasources/remote/stdict_api.dart';
import 'package:malsseum_hanja/data/models/hanja_word.dart';
import 'package:malsseum_hanja/data/repositories/dictionary_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockStdictApi extends Mock implements StdictApi {}

const grace = HanjaWord(korean: '은혜', hanja: '恩惠', meaning: '내장 뜻풀이');

void main() {
  group('StdictApi.parseSearchResponse', () {
    test('sense 가 객체/배열 모두 파싱된다', () {
      final items = StdictApi.parseSearchResponse({
        'channel': {
          'item': [
            {
              'word': '은혜',
              'pos': '명사',
              'sense': {'definition': '고맙게 베풀어 주는 신세나 혜택.'},
            },
            {
              'word': '은-혜',
              'sense': [
                {'definition': '뜻1'},
                {'definition': '뜻2'},
              ],
            },
          ],
        },
      });

      expect(items.map((i) => i.definition), [
        '고맙게 베풀어 주는 신세나 혜택.',
        '뜻1',
        '뜻2',
      ]);
      expect(items.last.word, '은혜');
    });

    test('빈 응답은 빈 목록', () {
      expect(StdictApi.parseSearchResponse(''), isEmpty);
      expect(StdictApi.parseSearchResponse({}), isEmpty);
    });
  });

  group('DictionaryRepositoryImpl', () {
    late MockStdictApi api;

    setUp(() => api = MockStdictApi());

    test('API 키가 없으면 내장 뜻풀이를 쓴다', () async {
      when(() => api.hasKey).thenReturn(false);

      final entry = await DictionaryRepositoryImpl(api).lookup(grace);

      expect(entry.fromApi, isFalse);
      expect(entry.definitions, ['내장 뜻풀이']);
      verifyNever(() => api.search(any()));
    });

    test('API 결과가 있으면 사용한다', () async {
      when(() => api.hasKey).thenReturn(true);
      when(() => api.search('은혜')).thenAnswer(
        (_) async => const [
          StdictItem(word: '은혜', pos: '명사', definition: 'API 뜻풀이'),
        ],
      );

      final entry = await DictionaryRepositoryImpl(api).lookup(grace);

      expect(entry.fromApi, isTrue);
      expect(entry.pos, '명사');
      expect(entry.definitions, ['API 뜻풀이']);
    });

    test('API 오류가 나면 내장 뜻풀이로 대체한다', () async {
      when(() => api.hasKey).thenReturn(true);
      when(() => api.search(any())).thenThrow(Exception('network'));

      final entry = await DictionaryRepositoryImpl(api).lookup(grace);

      expect(entry.fromApi, isFalse);
    });
  });
}
