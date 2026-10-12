import 'package:flutter/foundation.dart';

import '../datasources/remote/stdict_api.dart';
import '../models/dictionary_entry.dart';
import '../models/hanja_word.dart';

abstract class DictionaryRepository {
  Future<DictionaryEntry> lookup(HanjaWord word);
}

/// 내장 뜻풀이가 이미 표준국어대사전 것이면 그대로 쓴다 (tool/fetch_stdict.dart).
/// 아니면 Open API 로 뜻풀이를 가져오고, 키가 없거나 실패하면 내장 뜻풀이로 대체한다.
class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl(this._api);

  final StdictApi _api;
  final Map<String, DictionaryEntry> _cache = {};

  @override
  Future<DictionaryEntry> lookup(HanjaWord word) async {
    final cached = _cache[word.korean];
    if (cached != null) return cached;

    final fallback = DictionaryEntry(
      word: word.korean,
      pos: word.pos,
      definitions: word.definitions,
      fromApi: word.fromStdict,
    );
    if (word.fromStdict || !_api.hasKey) return fallback;

    try {
      final items = (await _api.search(word.korean))
          .where((i) => i.word == word.korean)
          .toList();
      if (items.isEmpty) return fallback;
      final entry = DictionaryEntry(
        word: word.korean,
        pos: items.first.pos,
        definitions: items.map((i) => i.definition).take(3).toList(),
        fromApi: true,
      );
      _cache[word.korean] = entry;
      return entry;
    } catch (e) {
      debugPrint('표준국어대사전 조회 실패: $e');
      return fallback;
    }
  }
}
