import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/hanja_char.dart';
import '../../models/hanja_origin.dart';

/// 앱에 내장된 한자 훈음·구성원리 데이터를 읽는다. 구절 본문은 [BibleDatabase] 에 있다.
class LocalBibleDataSource {
  LocalBibleDataSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Map<String, HanjaChar>? _chars;
  Map<String, HanjaOrigin>? _origins;

  Future<Map<String, HanjaChar>> loadHanjaChars() async {
    if (_chars != null) return _chars!;
    final json = await _loadJson('assets/data/hanja_chars.json');
    _chars = json.map(
      (char, v) =>
          MapEntry(char, HanjaChar.fromJson(char, v as Map<String, dynamic>)),
    );
    return _chars!;
  }

  /// 글자별 구성원리 (tool/fetch_hanja_origin.dart 가 만든다).
  Future<Map<String, HanjaOrigin>> loadHanjaOrigins() async {
    if (_origins != null) return _origins!;
    final json = await _loadJson('assets/data/hanja_origin.json');
    _origins = json.map(
      (char, v) =>
          MapEntry(char, HanjaOrigin.fromJson(char, v as Map<String, dynamic>)),
    );
    return _origins!;
  }

  /// asset JSON 을 읽는다. 결과는 위의 필드에 따로 캐시한다.
  ///
  /// loadString 을 쓰지 않는 이유: 50KB 가 넘으면 별도 isolate 에서 디코딩하고,
  /// 읽은 Future 를 전역 캐시에 두어서 위젯 테스트에서 끝나지 않는 경우가 있다.
  /// 파일이 작아(200KB 이하) 바로 디코딩해도 충분히 빠르다.
  Future<Map<String, dynamic>> _loadJson(String key) async {
    final data = await _bundle.load(key);
    final raw = utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
