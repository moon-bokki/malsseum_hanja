import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/hanja_word.dart';
import '../data/models/quiz_question.dart';
import '../providers.dart';

/// 순수 로직이라 단위 테스트가 쉽다. [Random] 을 주입하면 결과가 고정된다.
class QuizGenerator {
  QuizGenerator([Random? random]) : _random = random ?? Random();

  final Random _random;

  List<QuizQuestion> generate(List<HanjaWord> pool, {int count = 5}) {
    final readings = pool.map((w) => w.korean).toSet().toList();
    if (readings.length < 4) return const [];

    final picked = [...pool]..shuffle(_random);
    return picked.take(count).map((answer) {
      final distractors = readings.where((r) => r != answer.korean).toList()
        ..shuffle(_random);
      final options = [answer.korean, ...distractors.take(3)]..shuffle(_random);
      return QuizQuestion(
        answer: answer,
        options: options,
        answerIndex: options.indexOf(answer.korean),
      );
    }).toList();
  }
}

enum QuizStatus { idle, loading, inProgress, finished }

class QuizState {
  const QuizState({
    this.status = QuizStatus.idle,
    this.questions = const [],
    this.index = 0,
    this.score = 0,
    this.selected,
  });

  final QuizStatus status;
  final List<QuizQuestion> questions;
  final int index;
  final int score;
  final int? selected;

  QuizQuestion? get current =>
      index < questions.length ? questions[index] : null;
  bool get answered => selected != null;

  QuizState copyWith({
    QuizStatus? status,
    List<QuizQuestion>? questions,
    int? index,
    int? score,
    int? Function()? selected,
  }) => QuizState(
    status: status ?? this.status,
    questions: questions ?? this.questions,
    index: index ?? this.index,
    score: score ?? this.score,
    selected: selected != null ? selected() : this.selected,
  );
}

final quizGeneratorProvider = Provider<QuizGenerator>((ref) => QuizGenerator());

class QuizViewModel extends Notifier<QuizState> {
  static const int minWordbookSize = 4;

  @override
  QuizState build() => const QuizState();

  /// 단어장에 4개 이상 있으면 단어장에서, 아니면 전체 구절 한자어에서 출제.
  Future<void> start({int count = 5}) async {
    state = const QuizState(status: QuizStatus.loading);
    final saved = await ref.read(wordbookRepositoryProvider).watchWords().first;
    final pool = saved.length >= minWordbookSize
        ? saved.map((s) => s.word).toList()
        : await ref.read(bibleRepositoryProvider).getAllWords();
    final questions = ref
        .read(quizGeneratorProvider)
        .generate(pool, count: count);
    state = QuizState(status: QuizStatus.inProgress, questions: questions);
  }

  Future<void> select(int optionIndex) async {
    final q = state.current;
    if (q == null || state.answered) return;
    final correct = optionIndex == q.answerIndex;
    state = state.copyWith(
      selected: () => optionIndex,
      score: state.score + (correct ? 1 : 0),
    );
    await ref
        .read(wordbookRepositoryProvider)
        .recordQuizResult(q.answer.korean, correct: correct);
  }

  void next() {
    final nextIndex = state.index + 1;
    state = state.copyWith(
      index: nextIndex,
      selected: () => null,
      status: nextIndex >= state.questions.length
          ? QuizStatus.finished
          : QuizStatus.inProgress,
    );
  }
}

final quizViewModelProvider = NotifierProvider<QuizViewModel, QuizState>(
  QuizViewModel.new,
);
