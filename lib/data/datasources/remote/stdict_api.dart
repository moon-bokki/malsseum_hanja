import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';

/// 표준국어대사전 검색 결과 한 항목.
class StdictItem {
  const StdictItem({
    required this.word,
    this.pos,
    required this.definition,
    this.targetCode = '',
    this.origin = '',
  });

  final String word;
  final String? pos;
  final String definition;

  /// 표제어 고유 번호. [StdictApi.view] 로 원어(한자) 등 자세한 정보를 볼 때 쓴다.
  final String targetCode;

  /// 원어 (은혜 → 恩惠). 고유어면 빈 문자열.
  final String origin;
}

/// 표준국어대사전 표제어 상세 (view.do).
class StdictEntry {
  const StdictEntry({
    required this.word,
    required this.originalLanguage,
    this.pos,
    required this.definitions,
  });

  final String word;

  /// 원어 중 한자 부분 (은혜 → 恩惠). 고유어면 빈 문자열.
  final String originalLanguage;
  final String? pos;
  final List<String> definitions;
}

/// API 가 돌려준 오류 (인증키 오류, 사용량 초과 등).
class StdictException implements Exception {
  const StdictException(this.message);

  final String message;

  @override
  String toString() => '표준국어대사전 API 오류: $message';
}

/// 국립국어원 표준국어대사전 Open API (REST, JSON).
/// https://stdict.korean.go.kr/openapi/openApiInfo.do
class StdictApi {
  StdictApi(this._dio, {String? apiKey})
    : _apiKey = apiKey ?? AppConfig.stdictApiKey;

  final Dio _dio;
  final String _apiKey;

  bool get hasKey => _apiKey.isNotEmpty;

  Future<List<StdictItem>> search(String query, {int num = 10}) async =>
      parseSearchResponse(
        await _get('/api/search.do', {'q': query, 'num': num}),
      );

  /// 표제어 상세 (모든 뜻풀이). 없으면 null.
  /// type_search=view 가 없으면 빈 본문이 온다.
  Future<StdictEntry?> view(String targetCode) async => parseViewResponse(
    await _get('/api/view.do', {
      'type_search': 'view',
      'method': 'TARGET_CODE',
      'q': targetCode,
    }),
  );

  Future<Object?> _get(String path, Map<String, Object> params) async {
    final res = await _dio.get<dynamic>(
      path,
      queryParameters: {'key': _apiKey, 'req_type': 'json', ...params},
    );
    var data = res.data;
    if (data is String) {
      if (data.trim().isEmpty) return null;
      data = jsonDecode(data);
    }
    // 인증키 오류 등은 200 과 함께 {"error": {"error_code", "message"}} 로 온다.
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      throw StdictException('${error['error_code']} ${error['message']}');
    }
    return data;
  }

  /// 검색 결과가 없으면 빈 본문이 오고, sense 는 객체 또는 배열로 올 수 있다.
  static List<StdictItem> parseSearchResponse(dynamic data) {
    if (data is String) {
      if (data.trim().isEmpty) return const [];
      data = jsonDecode(data);
    }
    if (data is! Map) return const [];
    final items = (data['channel'] as Map?)?['item'];

    final result = <StdictItem>[];
    for (final item in _list(items).whereType<Map>()) {
      for (final s in _list(item['sense']).whereType<Map>()) {
        final definition = _clean(s['definition'] as String? ?? '');
        if (definition.isEmpty) continue;
        result.add(
          StdictItem(
            word: _headword(item['word'] as String? ?? ''),
            pos: item['pos'] as String?,
            definition: definition,
            targetCode: '${item['target_code'] ?? ''}',
            origin: _originalLanguage('${item['origin'] ?? ''}'),
          ),
        );
      }
    }
    return result;
  }

  /// view.do 응답: channel.item.word_info 아래에
  /// original_language_info[] (원어), pos_info[].comm_pattern_info[].sense_info[] (뜻풀이).
  /// 항목이 하나뿐이면 배열 대신 객체로 오기도 한다.
  static StdictEntry? parseViewResponse(dynamic data) {
    if (data is String) {
      if (data.trim().isEmpty) return null;
      data = jsonDecode(data);
    }
    if (data is! Map) return null;
    final item = _list((data['channel'] as Map?)?['item']).firstOrNull;
    final info = item is Map ? item['word_info'] : null;
    if (info is! Map) return null;

    final original = _list(info['original_language_info'])
        .whereType<Map>()
        .where((o) => o['language_type'] == '한자')
        .map((o) => '${o['original_language'] ?? ''}')
        .join();

    String? pos;
    final definitions = <String>[];
    for (final p in _list(info['pos_info']).whereType<Map>()) {
      pos ??= p['pos'] as String?;
      for (final c in _list(p['comm_pattern_info']).whereType<Map>()) {
        for (final s in _list(c['sense_info']).whereType<Map>()) {
          final d = _clean(s['definition'] as String? ?? '');
          if (d.isNotEmpty) definitions.add(d);
        }
      }
    }

    return StdictEntry(
      word: _headword(info['word'] as String? ?? ''),
      originalLanguage: _originalLanguage(original),
      pos: pos == null || pos.isEmpty || pos == '품사 없음' ? null : pos,
      definitions: definitions,
    );
  }

  static List<Object?> _list(Object? v) => switch (v) {
    null => const [],
    List() => v,
    _ => [v],
  };

  /// 원어에 붙는 붙임표·띄어쓰기 표시를 뺀다 (恩-惠, 獨生^子).
  static String _originalLanguage(String s) =>
      s.replaceAll(RegExp(r'[-^ ]'), '');

  /// 표제어의 붙임표·띄어쓰기 표시를 뺀다 (독생-자 → 독생자).
  static String _headword(String word) => word.replaceAll(RegExp(r'[-^]'), '');

  /// 뜻풀이 안의 태그(`<sup>`, `<equ>` 등)와 엔티티를 정리한다.
  static String _clean(String s) => s
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAllMapped(
        RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'),
        (m) => String.fromCharCode(
          m[1]!.startsWith('x')
              ? int.parse(m[1]!.substring(1), radix: 16)
              : int.parse(m[1]!),
        ),
      )
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
