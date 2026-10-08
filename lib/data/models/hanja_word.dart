/// 성경 구절 속 한자어 (예: 은혜 / 恩惠).
class HanjaWord {
  const HanjaWord({
    required this.korean,
    required this.hanja,
    required this.meaning,
  });

  final String korean;
  final String hanja;
  final String meaning;

  /// 한 글자씩 나눈 한자 목록 (恩惠 → [恩, 惠]).
  List<String> get chars => hanja.split('');

  factory HanjaWord.fromJson(Map<String, dynamic> json) => HanjaWord(
    korean: json['korean'] as String,
    hanja: json['hanja'] as String,
    meaning: json['meaning'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'korean': korean,
    'hanja': hanja,
    'meaning': meaning,
  };

  @override
  bool operator ==(Object other) =>
      other is HanjaWord && other.korean == korean && other.hanja == hanja;

  @override
  int get hashCode => Object.hash(korean, hanja);
}
