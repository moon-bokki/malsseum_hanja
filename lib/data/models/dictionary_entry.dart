/// 사전 조회 결과. [fromApi] 가 true 이면 표준국어대사전 뜻풀이다 (API 로 받았거나 bible.db 에 미리 넣어 둔 것).
class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.definitions,
    this.pos,
    this.fromApi = false,
  });

  final String word;
  final String? pos;
  final List<String> definitions;
  final bool fromApi;
}
