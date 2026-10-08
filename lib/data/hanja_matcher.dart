/// 본문에서 한자어(한글 표기)를 찾는 규칙. 앱 화면과 tool/build_bible_db.dart 가 함께 쓴다.
///
/// 1. 어절 첫머리에서 시작할 때만 찾는다.
///    '은혜를' 의 '은혜' 는 찾지만, '보은혜' 처럼 다른 글자 뒤에 붙은 것은 찾지 않는다.
/// 2. 같은 자리에서 여러 단어가 맞으면 긴 단어를 고른다. ('제사장' > '제사')
/// 3. 겹치면 앞에서 시작한 것을 고른다.
library;

class TextMatch {
  const TextMatch(this.start, this.word);

  final int start;
  final String word;

  int get end => start + word.length;
}

/// [text] 에서 [words] 를 위 규칙으로 찾아 앞에서부터 돌려준다.
List<TextMatch> matchWords(String text, Iterable<String> words) {
  final all = <TextMatch>[];
  for (final w in words.toSet()) {
    if (w.isEmpty) continue;
    var i = text.indexOf(w);
    while (i != -1) {
      if (_isWordStart(text, i)) all.add(TextMatch(i, w));
      i = text.indexOf(w, i + 1);
    }
  }
  all.sort((a, b) {
    final c = a.start.compareTo(b.start);
    return c != 0 ? c : b.word.length.compareTo(a.word.length);
  });

  final result = <TextMatch>[];
  var end = 0;
  for (final m in all) {
    if (m.start < end) continue;
    result.add(m);
    end = m.end;
  }
  return result;
}

/// 앞 글자가 없거나 한글이 아니면(공백, 문장부호 등) 어절 첫머리로 본다.
bool _isWordStart(String text, int i) {
  if (i == 0) return true;
  final prev = text.codeUnitAt(i - 1);
  return !(prev >= 0xAC00 && prev <= 0xD7A3);
}
