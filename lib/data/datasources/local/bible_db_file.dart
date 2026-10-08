import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// 내장 bible.db 를 앱 저장소에 복사하고 경로를 돌려준다. 이미 있으면 그대로 쓴다.
/// 이름에 데이터 버전이 들어가므로, 버전이 바뀌면 새 파일로 복사된다.
Future<String> copyBibleAsset(
  String name,
  Future<Uint8List> Function() loadAsset,
) async {
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$name.sqlite');
  if (!file.existsSync()) {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(await loadAsset(), flush: true);
    await tmp.rename(file.path);
  }
  return file.path;
}
