import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/models/hanja_word.dart';
import 'package:malsseum_hanja/data/repositories/bible_repository.dart';
import 'package:malsseum_hanja/data/repositories/wordbook_repository.dart';
import 'package:malsseum_hanja/providers.dart';
import 'package:malsseum_hanja/viewmodels/quiz_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

class MockBibleRepository extends Mock implements BibleRepository {}

const words = [
  HanjaWord(korean: '은혜', hanja: '恩惠', meaning: ''),
  HanjaWord(korean: '구원', hanja: '救援', meaning: ''),
  HanjaWord(korean: '영생', hanja: '永生', meaning: ''),
  HanjaWord(korean: '천국', hanja: '天國', meaning: ''),
  HanjaWord(korean: '회개', hanja: '悔改', meaning: ''),
];

void main() {
  group('QuizGenerator', () {
    test('보기 4개 중 정답이 정확히 하나 포함된다', () {
      final questions = QuizGenerator(Random(1)).generate(words, count: 3);

      expect(questions, hasLength(3));
      for (final q in questions) {
        expect(q.options, hasLength(4));
        expect(q.options.toSet(), hasLength(4));
        expect(q.options[q.answerIndex], q.answer.korean);
      }
    });

    test('단어가 4개 미만이면 문제를 만들지 않는다', () {
      expect(QuizGenerator().generate(words.take(3).toList()), isEmpty);
    });
  });

  group('QuizViewModel', () {
    late ProviderContainer container;
    late InMemoryWordbookRepository wordbook;

    setUp(() {
      final bible = MockBibleRepository();
      when(() => bible.getAllWords()).thenAnswer((_) async => words);
      wordbook = InMemoryWordbookRepository();
      container = ProviderContainer(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(bible),
          wordbookRepositoryProvider.overrideWithValue(wordbook),
          quizGeneratorProvider.overrideWithValue(QuizGenerator(Random(7))),
        ],
      );
      addTearDown(container.dispose);
    });

    test('정답을 고르면 점수가 오르고 단어장 기록이 갱신된다', () async {
      await wordbook.save(words[0], '에베소서 2:8');
      final vm = container.read(quizViewModelProvider.notifier);

      await vm.start(count: 5);
      var state = container.read(quizViewModelProvider);
      expect(state.status, QuizStatus.inProgress);

      // 모든 문제에 정답 선택
      for (var i = 0; i < 5; i++) {
        state = container.read(quizViewModelProvider);
        await vm.select(state.current!.answerIndex);
        vm.next();
      }

      state = container.read(quizViewModelProvider);
      expect(state.status, QuizStatus.finished);
      expect(state.score, 5);
      final saved = await wordbook.watchWords().first;
      expect(saved.single.correctCount, 1);
    });

    test('이미 답한 문제는 다시 선택할 수 없다', () async {
      final vm = container.read(quizViewModelProvider.notifier);
      await vm.start(count: 1);
      final q = container.read(quizViewModelProvider).current!;

      await vm.select((q.answerIndex + 1) % 4); // 오답
      await vm.select(q.answerIndex); // 무시되어야 함

      expect(container.read(quizViewModelProvider).score, 0);
    });
  });
}
