/// 사전 조회 결과. [fromApi] 가 false 이면 앱 내장 뜻풀이를 사용한 것이다.
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
