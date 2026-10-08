// 개역한글 전체 본문을 Bolls Bible 에서 내려받아 tool/data/bible_text.tsv 로 저장한다.
//
//   dart run tool/fetch_krv.dart
//   dart run tool/build_bible_db.dart     ← 이어서 bible.db 를 다시 만든다
//
// 출처: https://bolls.life (번역본 코드 KRV = 개역한글)
// 본문: 성경전서 개역한글판 © 대한성서공회 1961 (저작재산권 소멸, 출처 표시·동일성 유지 필요)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:malsseum_hanja/data/models/bible_book.dart';

const _url = 'https://bolls.life/static/translations/KRV.zip';
const _outPath = 'tool/data/bible_text.tsv';

Future<void> main() async {
  stdout.writeln('내려받는 중: $_url');
  final bytes = await _download(Uri.parse(_url));

  final archive = ZipDecoder().decodeBytes(bytes);
  final entry = archive.files.firstWhere(
    (f) => f.isFile && f.name.endsWith('.json'),
    orElse: () => throw const FormatException('zip 안에 JSON 파일이 없습니다.'),
  );
  final verses = (jsonDecode(utf8.decode(entry.content)) as List)
      .cast<Map<String, dynamic>>();

  final lines = <String>[];
  final chapters = <int, Set<int>>{};
  for (final v in verses) {
    final number = v['book'] as int;
    if (number < 1 || number > 66) {
      throw FormatException('알 수 없는 책 번호: $number');
    }
    final book = BibleBook.byNumber(number);
    final chapter = v['chapter'] as int;
    final verse = v['verse'] as int;
    // 탭·줄바꿈은 TSV 를 깨뜨리므로 공백 하나로 바꾼다 (글자는 바꾸지 않는다).
    final text = (v['text'] as String).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) {
      stderr.writeln('경고: ${book.code} $chapter:$verse 본문이 비어 있어 건너뜁니다.');
      continue;
    }
    lines.add('${book.code}\t$chapter\t$verse\t$text');
    (chapters[number] ??= {}).add(chapter);
  }

  // 장 수가 BibleBook 과 맞는지 확인한다.
  for (final book in BibleBook.all) {
    final count = chapters[book.number]?.length ?? 0;
    if (count != book.chapterCount) {
      stderr.writeln(
        '경고: ${book.name} 장 수가 다릅니다 (받은 데이터 $count, 앱 ${book.chapterCount}).',
      );
    }
  }

  File(_outPath).writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln('$_outPath 저장: ${lines.length}절, ${chapters.length}권');
}

Future<List<int>> _download(Uri uri) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(uri)).close();
    if (response.statusCode != 200) {
      throw HttpException('다운로드 실패 (${response.statusCode})', uri: uri);
    }
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    return builder.takeBytes();
  } finally {
    client.close();
  }
}
