import 'hanja_word.dart';

/// 한자(恩惠)를 보고 올바른 읽기(은혜)를 고르는 객관식 문제.
class QuizQuestion {
  const QuizQuestion({
    required this.answer,
    required this.options,
    required this.answerIndex,
  });

  final HanjaWord answer;
  final List<String> options;
  final int answerIndex;
}
