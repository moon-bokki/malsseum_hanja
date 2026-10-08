/// 한자 한 글자의 훈(뜻)과 음(소리). 예: 恩 → 은혜 은
class HanjaChar {
  const HanjaChar({required this.char, required this.hun, required this.eum});

  final String char;
  final String hun;
  final String eum;

  String get hunEum => '$hun $eum';

  factory HanjaChar.fromJson(String char, Map<String, dynamic> json) =>
      HanjaChar(
        char: char,
        hun: json['hun'] as String,
        eum: json['eum'] as String,
      );
}
