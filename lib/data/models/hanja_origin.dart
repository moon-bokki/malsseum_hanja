/// 한자 한 글자의 구성원리 (자원 풀이). 네이버 한자사전에서 받아 앱에 넣은 것
/// (tool/fetch_hanja_origin.dart → assets/data/hanja_origin.json).
///
/// 삽화·옛 글자 이미지는 앱에 넣지 않고 [naverUrl] 로 네이버 한자사전 페이지를 연다.
class HanjaOrigin {
  const HanjaOrigin({
    required this.char,
    required this.source,
    required this.type,
    required this.text,
    this.entryId = '',
    this.pictures = const [],
  });

  final String char;

  /// '한자로드' 또는 '네이버'.
  final String source;

  /// 육서 분류 (회의문자, 형성문자, 상형문자 …).
  final String type;

  /// 풀이 본문. 문단은 줄바꿈으로 나뉜다.
  final String text;

  /// 네이버 한자사전 표제어 id.
  final String entryId;

  /// 네이버 페이지에서 볼 수 있는 그림 (삽화, 갑골문, 금문, 소전, 해서 …).
  final List<String> pictures;

  /// 네이버 한자사전의 이 글자 페이지. id 가 없으면 검색 페이지.
  Uri get naverUrl => entryId.isNotEmpty
      ? Uri.parse('https://hanja.dict.naver.com/#/entry/ccko/$entryId')
      : Uri.parse(
          'https://hanja.dict.naver.com/#/search?query=${Uri.encodeComponent(char)}',
        );

  /// 화면에 표시하는 출처.
  String get credit =>
      source == '한자로드' ? '출처: 한자로드(路) 신동윤 (네이버 한자사전)' : '출처: 네이버 한자사전';

  factory HanjaOrigin.fromJson(String char, Map<String, dynamic> json) =>
      HanjaOrigin(
        char: char,
        source: json['source'] as String? ?? '',
        type: json['type'] as String? ?? '',
        text: json['text'] as String? ?? '',
        entryId: json['entryId'] as String? ?? '',
        pictures: [...?(json['pictures'] as List?)?.cast<String>()],
      );
}
