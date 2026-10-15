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

    test('target_code 와 뜻풀이 태그를 정리한다', () {
      final items = StdictApi.parseSearchResponse({
        'channel': {
          'item': {
            'target_code': 412345,
            'word': '장로',
            'origin': '長-老',
            'sense': {'definition': '나이가 <sup>많고</sup>  &amp; 덕이 높은 사람.'},
          },
        },
      });
      expect(items.single.targetCode, '412345');
      expect(items.single.origin, '長老');
      expect(items.single.definition, '나이가 많고 & 덕이 높은 사람.');
    });
  });

  group('StdictApi.parseViewResponse', () {
    test('원어(한자)·품사·뜻풀이를 모두 읽는다', () {
      final entry = StdictApi.parseViewResponse({
        'channel': {
          'total': 1,
          'item': {
            'target_code': '412345',
            'word_info': {
              'word': '독생-자',
              'original_language_info': [
                {'original_language': '獨生', 'language_type': '한자'},
                {'original_language': '^子', 'language_type': '한자'},
              ],
              'pos_info': [
                {
                  'pos': '명사',
                  'comm_pattern_info': [
                    {
                      'sense_info': [
                        {'definition': '외아들.'},
                        {'definition': '예수 그리스도를 이르는 말.'},
                      ],
                    },
                  ],
                },
              ],
            },
          },
        },
      })!;
      expect(entry.word, '독생자');
      expect(entry.originalLanguage, '獨生子');
      expect(entry.pos, '명사');
      expect(entry.definitions, ['외아들.', '예수 그리스도를 이르는 말.']);
    });

    test('배열 대신 객체로 와도 읽고, 고유어는 원어가 비어 있다', () {
      final entry = StdictApi.parseViewResponse({
        'channel': {
          'item': {
            'word_info': {
              'word': '사랑',
              'pos_info': {
                'pos': '명사',
                'comm_pattern_info': {
                  'sense_info': {'definition': '아끼고 귀중히 여기는 마음.'},
                },
              },
            },
          },
        },
      })!;
      expect(entry.originalLanguage, isEmpty);
      expect(entry.definitions, ['아끼고 귀중히 여기는 마음.']);
    });

    test('빈 응답은 null', () {
      expect(StdictApi.parseViewResponse(''), isNull);
      expect(StdictApi.parseViewResponse({'channel': {}}), isNull);
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

    test('내장 뜻풀이가 표준국어대사전 것이면 API 를 부르지 않는다', () async {
      when(() => api.hasKey).thenReturn(true);
      const word = HanjaWord(
        korean: '은혜',
        hanja: '恩惠',
        meaning: '고맙게 베풀어 주는 신세나 혜택.\n두 번째 뜻.',
        pos: '명사',
        fromStdict: true,
      );

      final entry = await DictionaryRepositoryImpl(api).lookup(word);

      expect(entry.fromApi, isTrue);
      expect(entry.pos, '명사');
      expect(entry.definitions, ['고맙게 베풀어 주는 신세나 혜택.', '두 번째 뜻.']);
      verifyNever(() => api.search(any()));
    });

    test('API 오류가 나면 내장 뜻풀이로 대체한다', () async {
      when(() => api.hasKey).thenReturn(true);
      when(() => api.search(any())).thenThrow(Exception('network'));

      final entry = await DictionaryRepositoryImpl(api).lookup(grace);

      expect(entry.fromApi, isFalse);
    });
  });
}
