/// 구약 / 신약 구분.
enum Testament {
  old('구약'),
  newT('신약');

  const Testament(this.label);

  final String label;
}

/// 성경 66권 (개역한글 책 이름과 약어).
class BibleBook {
  const BibleBook(
    this.name,
    this.abbr,
    this.code,
    this.chapterCount,
    this.testament,
  );

  final String name;
  final String abbr;

  /// 구절 id 에 쓰는 영문 코드 (예: 'JHN' → 'JHN-3-16').
  final String code;
  final int chapterCount;
  final Testament testament;

  /// 정경 순서 (창세기 = 0 … 요한계시록 = 65).
  int get order => all.indexOf(this);

  /// DB 의 verses.book 값 (창세기 = 1 … 요한계시록 = 66).
  int get number => order + 1;

  static BibleBook? byName(String name) {
    for (final b in all) {
      if (b.name == name) return b;
    }
    return null;
  }

  static BibleBook? byCode(String code) {
    for (final b in all) {
      if (b.code == code) return b;
    }
    return null;
  }

  static BibleBook byNumber(int number) => all[number - 1];

  /// 책 이름 또는 약어로 찾는다 (예: '요한복음', '요').
  static BibleBook? find(String token) {
    for (final b in all) {
      if (b.name == token || b.abbr == token) return b;
    }
    return null;
  }

  static List<BibleBook> of(Testament t) =>
      all.where((b) => b.testament == t).toList();

  static const all = [
    BibleBook('창세기', '창', 'GEN', 50, Testament.old),
    BibleBook('출애굽기', '출', 'EXO', 40, Testament.old),
    BibleBook('레위기', '레', 'LEV', 27, Testament.old),
    BibleBook('민수기', '민', 'NUM', 36, Testament.old),
    BibleBook('신명기', '신', 'DEU', 34, Testament.old),
    BibleBook('여호수아', '수', 'JOS', 24, Testament.old),
    BibleBook('사사기', '삿', 'JDG', 21, Testament.old),
    BibleBook('룻기', '룻', 'RUT', 4, Testament.old),
    BibleBook('사무엘상', '삼상', '1SA', 31, Testament.old),
    BibleBook('사무엘하', '삼하', '2SA', 24, Testament.old),
    BibleBook('열왕기상', '왕상', '1KI', 22, Testament.old),
    BibleBook('열왕기하', '왕하', '2KI', 25, Testament.old),
    BibleBook('역대상', '대상', '1CH', 29, Testament.old),
    BibleBook('역대하', '대하', '2CH', 36, Testament.old),
    BibleBook('에스라', '스', 'EZR', 10, Testament.old),
    BibleBook('느헤미야', '느', 'NEH', 13, Testament.old),
    BibleBook('에스더', '에', 'EST', 10, Testament.old),
    BibleBook('욥기', '욥', 'JOB', 42, Testament.old),
    BibleBook('시편', '시', 'PSA', 150, Testament.old),
    BibleBook('잠언', '잠', 'PRO', 31, Testament.old),
    BibleBook('전도서', '전', 'ECC', 12, Testament.old),
    BibleBook('아가', '아', 'SNG', 8, Testament.old),
    BibleBook('이사야', '사', 'ISA', 66, Testament.old),
    BibleBook('예레미야', '렘', 'JER', 52, Testament.old),
    BibleBook('예레미야애가', '애', 'LAM', 5, Testament.old),
    BibleBook('에스겔', '겔', 'EZK', 48, Testament.old),
    BibleBook('다니엘', '단', 'DAN', 12, Testament.old),
    BibleBook('호세아', '호', 'HOS', 14, Testament.old),
    BibleBook('요엘', '욜', 'JOL', 3, Testament.old),
    BibleBook('아모스', '암', 'AMO', 9, Testament.old),
    BibleBook('오바댜', '옵', 'OBA', 1, Testament.old),
    BibleBook('요나', '욘', 'JON', 4, Testament.old),
    BibleBook('미가', '미', 'MIC', 7, Testament.old),
    BibleBook('나훔', '나', 'NAM', 3, Testament.old),
    BibleBook('하박국', '합', 'HAB', 3, Testament.old),
    BibleBook('스바냐', '습', 'ZEP', 3, Testament.old),
    BibleBook('학개', '학', 'HAG', 2, Testament.old),
    BibleBook('스가랴', '슥', 'ZEC', 14, Testament.old),
    BibleBook('말라기', '말', 'MAL', 4, Testament.old),
    BibleBook('마태복음', '마', 'MAT', 28, Testament.newT),
    BibleBook('마가복음', '막', 'MRK', 16, Testament.newT),
    BibleBook('누가복음', '눅', 'LUK', 24, Testament.newT),
    BibleBook('요한복음', '요', 'JHN', 21, Testament.newT),
    BibleBook('사도행전', '행', 'ACT', 28, Testament.newT),
    BibleBook('로마서', '롬', 'ROM', 16, Testament.newT),
    BibleBook('고린도전서', '고전', '1CO', 16, Testament.newT),
    BibleBook('고린도후서', '고후', '2CO', 13, Testament.newT),
    BibleBook('갈라디아서', '갈', 'GAL', 6, Testament.newT),
    BibleBook('에베소서', '엡', 'EPH', 6, Testament.newT),
    BibleBook('빌립보서', '빌', 'PHP', 4, Testament.newT),
    BibleBook('골로새서', '골', 'COL', 4, Testament.newT),
    BibleBook('데살로니가전서', '살전', '1TH', 5, Testament.newT),
    BibleBook('데살로니가후서', '살후', '2TH', 3, Testament.newT),
    BibleBook('디모데전서', '딤전', '1TI', 6, Testament.newT),
    BibleBook('디모데후서', '딤후', '2TI', 4, Testament.newT),
    BibleBook('디도서', '딛', 'TIT', 3, Testament.newT),
    BibleBook('빌레몬서', '몬', 'PHM', 1, Testament.newT),
    BibleBook('히브리서', '히', 'HEB', 13, Testament.newT),
    BibleBook('야고보서', '약', 'JAS', 5, Testament.newT),
    BibleBook('베드로전서', '벧전', '1PE', 5, Testament.newT),
    BibleBook('베드로후서', '벧후', '2PE', 3, Testament.newT),
    BibleBook('요한일서', '요일', '1JN', 5, Testament.newT),
    BibleBook('요한이서', '요이', '2JN', 1, Testament.newT),
    BibleBook('요한삼서', '요삼', '3JN', 1, Testament.newT),
    BibleBook('유다서', '유', 'JUD', 1, Testament.newT),
    BibleBook('요한계시록', '계', 'REV', 22, Testament.newT),
  ];
}
