import 'hanja_word.dart';

class Verse {
  const Verse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.words,
  });

  final String id;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final List<HanjaWord> words;

  String get reference => '$book $chapter:$verse';

  factory Verse.fromJson(Map<String, dynamic> json) => Verse(
    id: json['id'] as String,
    book: json['book'] as String,
    chapter: json['chapter'] as int,
    verse: json['verse'] as int,
    text: json['text'] as String,
    words: (json['words'] as List)
        .map((e) => HanjaWord.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
