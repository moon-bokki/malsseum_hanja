import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/hanja_char.dart';

/// 앱에 내장된 한자 훈음 데이터를 읽는다. 구절 본문은 [BibleDatabase] 에 있다.
class LocalBibleDataSource {
  LocalBibleDataSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Map<String, HanjaChar>? _chars;

  Future<Map<String, HanjaChar>> loadHanjaChars() async {
    if (_chars != null) return _chars!;
    final raw = await _bundle.loadString('assets/data/hanja_chars.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _chars = json.map(
      (char, v) =>
          MapEntry(char, HanjaChar.fromJson(char, v as Map<String, dynamic>)),
    );
    return _chars!;
  }
}
