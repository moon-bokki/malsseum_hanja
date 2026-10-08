import 'hanja_word.dart';

/// 단어장에 저장된 한자어와 학습 기록.
class SavedWord {
  const SavedWord({
    required this.word,
    required this.verseRef,
    required this.savedAt,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  final HanjaWord word;
  final String verseRef;
  final DateTime savedAt;
  final int correctCount;
  final int wrongCount;

  SavedWord copyWith({int? correctCount, int? wrongCount}) => SavedWord(
    word: word,
    verseRef: verseRef,
    savedAt: savedAt,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
  );

  Map<String, dynamic> toJson() => {
    ...word.toJson(),
    'verseRef': verseRef,
    'savedAt': savedAt.toIso8601String(),
    'correctCount': correctCount,
    'wrongCount': wrongCount,
  };

  factory SavedWord.fromJson(Map<String, dynamic> json) => SavedWord(
    word: HanjaWord.fromJson(json),
    verseRef: json['verseRef'] as String? ?? '',
    savedAt:
        DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    correctCount: json['correctCount'] as int? ?? 0,
    wrongCount: json['wrongCount'] as int? ?? 0,
  );
}
