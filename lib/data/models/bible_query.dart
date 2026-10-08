import 'bible_book.dart';

/// 성경 검색 조건.
class BibleQuery {
  const BibleQuery({this.text = '', this.testament, this.book});

  /// 장절 표기('요 3:16'), 책 이름, 본문, 한글/한자 단어.
  final String text;

  /// null 이면 구약+신약 전체.
  final Testament? testament;

  /// null 이면 선택한 범위의 모든 책.
  final BibleBook? book;

  @override
  bool operator ==(Object other) =>
      other is BibleQuery &&
      other.text == text &&
      other.testament == testament &&
      other.book == book;

  @override
  int get hashCode => Object.hash(text, testament, book);
}

/// '요 3:16', '요한복음 3', '시 23장 1절' 같은 장절 표기.
class BibleReference {
  const BibleReference(this.book, this.chapter, [this.verse]);

  final BibleBook book;
  final int chapter;
  final int? verse;

  static final _pattern = RegExp(r'^(\S+?)\s*(\d+)(?:\s*[:장]\s*(\d+)절?)?$');

  static BibleReference? parse(String text) {
    final m = _pattern.firstMatch(text.trim());
    if (m == null) return null;
    final book = BibleBook.find(m.group(1)!);
    if (book == null) return null;
    return BibleReference(
      book,
      int.parse(m.group(2)!),
      m.group(3) == null ? null : int.parse(m.group(3)!),
    );
  }
}
