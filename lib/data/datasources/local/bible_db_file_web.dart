import 'dart:typed_data';

/// 웹에서는 DriftWebOptions.initializeDatabase 가 대신 쓰이므로 호출되지 않는다.
Future<String> copyBibleAsset(
  String name,
  Future<Uint8List> Function() loadAsset,
) => throw UnsupportedError('웹에서는 파일 복사를 하지 않습니다.');
