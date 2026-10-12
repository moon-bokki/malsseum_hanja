/// 성경 구절 속 한자어 (예: 은혜 / 恩惠).
class HanjaWord {
  const HanjaWord({
    required this.korean,
    required this.hanja,
    required this.meaning,
    this.pos,
    this.fromStdict = false,
  });

  final String korean;
  final String hanja;

  /// 뜻풀이. 뜻이 여럿이면 줄바꿈(\n)으로 나뉜다.
  final String meaning;

  /// 품사 (표준국어대사전에서 받은 경우).
  final String? pos;

  /// true 이면 [meaning] 이 국립국어원 표준국어대사전 뜻풀이다
  /// (tool/fetch_stdict.dart 로 받아 bible.db 에 넣은 것).
  final bool fromStdict;

  /// 한 글자씩 나눈 한자 목록 (恩惠 → [恩, 惠]).
  List<String> get chars => hanja.split('');

  /// 뜻풀이 목록.
  List<String> get definitions => [
    for (final d in meaning.split('\n'))
      if (d.trim().isNotEmpty) d.trim(),
  ];

  /// 목록·퀴즈에 보이는 짧은 뜻 (첫 번째 뜻풀이).
  String get shortMeaning => definitions.firstOrNull ?? '';

  factory HanjaWord.fromJson(Map<String, dynamic> json) => HanjaWord(
    korean: json['korean'] as String,
    hanja: json['hanja'] as String,
    meaning: json['meaning'] as String? ?? '',
    pos: json['pos'] as String?,
    fromStdict: json['fromStdict'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'korean': korean,
    'hanja': hanja,
    'meaning': meaning,
    if (pos != null) 'pos': pos,
    if (fromStdict) 'fromStdict': true,
  };

  /// 뜻풀이만 바꾼 사본.
  HanjaWord withMeaning(
    String meaning, {
    String? pos,
    bool fromStdict = false,
  }) => HanjaWord(
    korean: korean,
    hanja: hanja,
    meaning: meaning,
    pos: pos,
    fromStdict: fromStdict,
  );

  @override
  bool operator ==(Object other) =>
      other is HanjaWord && other.korean == korean && other.hanja == hanja;

  @override
  int get hashCode => Object.hash(korean, hanja);
}
