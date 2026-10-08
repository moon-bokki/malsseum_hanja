import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';

/// 표준국어대사전 검색 결과 한 항목.
class StdictItem {
  const StdictItem({required this.word, this.pos, required this.definition});

  final String word;
  final String? pos;
  final String definition;
}

/// 국립국어원 표준국어대사전 Open API (REST, JSON).
/// https://stdict.korean.go.kr/openapi/openApiInfo.do
class StdictApi {
  StdictApi(this._dio, {String? apiKey})
    : _apiKey = apiKey ?? AppConfig.stdictApiKey;

  final Dio _dio;
  final String _apiKey;

  bool get hasKey => _apiKey.isNotEmpty;

  Future<List<StdictItem>> search(String query) async {
    final res = await _dio.get<dynamic>(
      '/api/search.do',
      queryParameters: {
        'key': _apiKey,
        'q': query,
        'req_type': 'json',
        'num': 10,
      },
    );
    return parseSearchResponse(res.data);
  }

  /// 검색 결과가 없으면 빈 본문이 오고, sense 는 객체 또는 배열로 올 수 있다.
  static List<StdictItem> parseSearchResponse(dynamic data) {
    if (data is String) {
      if (data.trim().isEmpty) return const [];
      data = jsonDecode(data);
    }
    if (data is! Map) return const [];
    final items = (data['channel'] as Map?)?['item'];
    if (items is! List) return const [];

    final result = <StdictItem>[];
    for (final item in items.whereType<Map>()) {
      final sense = item['sense'];
      final senses = sense is List ? sense : [sense];
      for (final s in senses.whereType<Map>()) {
        final definition = s['definition'] as String?;
        if (definition == null || definition.isEmpty) continue;
        result.add(
          StdictItem(
            word: (item['word'] as String? ?? '').replaceAll('-', ''),
            pos: item['pos'] as String?,
            definition: definition,
          ),
        );
      }
    }
    return result;
  }
}
