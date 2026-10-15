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
    final raw = await _bundle.loadString('assets/data/hanja_chars.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _chars = json.map(
      (char, v) =>
          MapEntry(char, HanjaChar.fromJson(char, v as Map<String, dynamic>)),
    );
    return _chars!;
  }

  /// 글자별 구성원리 (tool/fetch_hanja_origin.dart 가 만든다).
  Future<Map<String, HanjaOrigin>> loadHanjaOrigins() async {
    if (_origins != null) return _origins!;
    // loadString 은 50KB 가 넘으면 별도 isolate 에서 디코딩한다 (위젯 테스트에서 끝나지 않음).
    // 200KB 정도라 바로 디코딩해도 충분히 빠르다.
    final data = await _bundle.load('assets/data/hanja_origin.json');
    final raw = utf8.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _origins = json.map(
      (char, v) =>
          MapEntry(char, HanjaOrigin.fromJson(char, v as Map<String, dynamic>)),
    );
    return _origins!;
  }
}
