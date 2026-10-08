// 네이버 한자사전에서 글자별 '한자 구성원리'(자원 풀이)를 받아 tool/data/hanja_origin.json 으로 저장한다.
//
//   dart run tool/fetch_hanja_origin.dart              ← hanja_words.json 의 글자 중 아직 없는 것만 받는다
//   dart run tool/fetch_hanja_origin.dart 渡 恩        ← 지정한 글자만 다시 받는다
//   dart run tool/fetch_hanja_origin.dart --refresh    ← 전부 다시 받는다
//
// 입력
//   tool/data/hanja_words.json   한자어 사전. 여기 나오는 한자 낱자를 모두 받는다.
//
// 출력
//   tool/data/hanja_origin.json  글자별 구성원리 (다시 실행하면 이어서 받는다)
//   tool/data/hanja_origin.tsv   검토용 요약 (스프레드시트로 열기)
//
// 출처: https://hanja.dict.naver.com (공개 API 가 아니라 사이트 내부 API 이므로 바뀔 수 있다)
// 구성원리 본문·삽화는 출처별 저작물이다. 특히 『한자로드(路)』(신동윤, 삽화 변아롱·박혜현)는
// 앱에 넣어 배포하려면 이용 허락이 필요하다. 이 파일은 검토·참고용이다.
import 'dart:convert';
import 'dart:io';

import 'package:malsseum_hanja/data/hanja_linker.dart';

const _dictionaryPath = 'tool/data/hanja_words.json';
const _outPath = 'tool/data/hanja_origin.json';
const _reportPath = 'tool/data/hanja_origin.tsv';

const _acUrl = 'https://ac-dict.naver.com/ccko/ac';
const _entryUrl = 'https://hanja.dict.naver.com/api/platform/ccko/entry';
const _userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/130.0 Safari/537.36';

/// 요청 사이 간격. 사이트에 부담을 주지 않도록 줄이지 않는다.
const _delay = Duration(seconds: 1);

/// learning_info_cid → 출처 이름. 모르는 cid 는 그대로 적는다.
const _sources = {'881919b1': '한자로드', '8800002B': '네이버'};

final _client = HttpClient()..userAgent = _userAgent;

Future<void> main(List<String> args) async {
  final refresh = args.contains('--refresh');
  final picked = args.where((a) => !a.startsWith('--')).join().runes.toSet();

  final out = File(_outPath);
  final saved = out.existsSync()
      ? (jsonDecode(out.readAsStringSync()) as Map<String, dynamic>)
      : <String, dynamic>{};

  final dictionary =
      (jsonDecode(File(_dictionaryPath).readAsStringSync()) as List)
          .map((e) => HanjaDictEntry.fromJson(e as Map<String, dynamic>))
          .toList();
  final all = <String>{
    for (final word in dictionary)
      for (final rune in word.word.hanja.runes) String.fromCharCode(rune),
  };

  final targets = picked.isNotEmpty
      ? picked.map(String.fromCharCode).toList()
      : all.where((c) => refresh || !saved.containsKey(c)).toList();
  stdout.writeln(
    '받을 글자: ${targets.length}자 (전체 ${all.length}자, 저장됨 ${saved.length}자)',
  );

  var failed = 0;
  try {
    for (final (i, hanja) in targets.indexed) {
      try {
        final result = await _fetch(hanja);
        saved[hanja] = result;
        final origins = (result['origins'] as List)
            .cast<Map<String, dynamic>>();
        final summary = origins.isEmpty
            ? '구성원리 없음'
            : origins.map((o) => '${o['source']}:${o['type']}').join(', ');
        stdout.writeln(
          '[${i + 1}/${targets.length}] $hanja ${result['reading']} — $summary',
        );
      } on Exception catch (e) {
        // 저장하지 않으면 다음 실행 때 다시 받는다.
        failed++;
        stderr.writeln('[${i + 1}/${targets.length}] $hanja 실패: $e');
      }
      _save(out, saved);
    }
  } finally {
    _client.close();
  }

  _writeReport(saved, all);
  stdout.writeln(
    '$_outPath 저장: ${saved.length}자${failed > 0 ? ' (실패 $failed자, 다시 실행하면 이어서 받는다)' : ''}',
  );
  stdout.writeln('$_reportPath 저장');
}

/// 한 글자의 훈음과 구성원리 목록을 받는다.
///
/// 자동완성 결과에서 같은 글자의 표제어를 차례로 열어 보고, 구성원리가 있는 첫 표제어를 쓴다.
/// (음이 여럿인 글자는 표제어가 여럿이고, 구성원리는 대개 첫 표제어에 붙어 있다.)
Future<Map<String, dynamic>> _fetch(String hanja) async {
  final candidates = await _findEntries(hanja);
  if (candidates.isEmpty) {
    return {'reading': '', 'entryId': '', 'origins': const []};
  }

  Map<String, dynamic>? first;
  for (final (reading, entryId) in candidates) {
    final origins = await _fetchOrigins(entryId);
    final result = {'reading': reading, 'entryId': entryId, 'origins': origins};
    if (origins.isNotEmpty) return result;
    first ??= result;
  }
  return first!;
}

/// 자동완성 API 로 글자의 표제어 (훈음, entryId) 목록을 얻는다.
Future<List<(String, String)>> _findEntries(String hanja) async {
  final uri = Uri.parse(_acUrl)
      .replace(queryParameters: {'st': '111', 'r_lt': '111', 'q': hanja});
  final json = await _getJson(uri) as Map<String, dynamic>;
  final groups = json['items'] as List;
  if (groups.isEmpty) return const [];

  // 항목 하나: [[단어], [훈음], [..], [뜻], [entryId], [사전]]
  return [
    for (final item in (groups.first as List).cast<List>())
      if (item[0][0] == hanja && item[5][0] == 'ccko')
        (item[1][0] as String, item[4][0] as String),
  ];
}

/// 표제어 상세에서 learning_info_category 가 '한자 구성원리'인 항목만 골라낸다.
Future<List<Map<String, dynamic>>> _fetchOrigins(String entryId) async {
  final uri = Uri.parse(_entryUrl)
      .replace(queryParameters: {'entryId': entryId});
  final json = await _getJson(uri) as Map<String, dynamic>;
  final group =
      (json['entry'] as Map<String, dynamic>?)?['group']
          as Map<String, dynamic>?;
  final infos = [
    ...?group?['learnings'] as List?,
    ...?group?['learningMores'] as List?,
  ].cast<Map<String, dynamic>>();

  return [
    for (final info in infos)
      if (info['learning_info_category'] == '한자 구성원리')
        {
          'source':
              _sources[info['learning_info_cid']] ??
              '${info['learning_info_cid']}',
          'type': info['learning_info_category_1depth'] ?? '',
          'title': info['learning_info_title'] ?? '',
          ..._parseBody(info['learning_info_body'] as String? ?? ''),
        },
  ];
}

/// 구성원리 본문을 글·삽화·자형(소전, 해서 …)으로 나눈다.
///
/// 한자로드 본문은 스마트에디터 HTML (삽화 → 설명 → 자형 표) 이고,
/// 다른 출처는 평문이다.
Map<String, dynamic> _parseBody(String body) {
  if (!body.contains('se-component')) {
    return {'text': _plain(body), 'images': const [], 'glyphs': const []};
  }

  final paragraphs = <String>[];
  final images = <String>[];
  final glyphs = <Map<String, String>>[];

  // 컴포넌트 단위로 자른다: se-image (삽화), se-text (설명), se-table (자형 표).
  final components = body.split('<div class="se-component se-').skip(1);
  for (final component in components) {
    if (component.startsWith('image')) {
      images.addAll(_imageSources(component));
    } else if (component.startsWith('text')) {
      paragraphs.addAll(_paragraphs(component));
    } else if (component.startsWith('table')) {
      // 이미지가 있는 행 바로 아래 행이 그 이미지들의 이름표다.
      final rows = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true)
          .allMatches(component)
          .map(
            (m) => RegExp(
              r'<td[^>]*>(.*?)</td>',
              dotAll: true,
            ).allMatches(m[1]!).map((c) => c[1]!).toList(),
          )
          .toList();
      for (var r = 0; r < rows.length; r++) {
        final sources = rows[r].map(_imageSources).toList();
        if (sources.every((s) => s.isEmpty)) continue;
        final labels = r + 1 < rows.length
            ? rows[r + 1].map(_plain).toList()
            : const <String>[];
        for (var c = 0; c < sources.length; c++) {
          if (sources[c].isEmpty) continue;
          glyphs.add({
            'label': c < labels.length ? labels[c] : '',
            'url': sources[c].first,
          });
        }
        r++;
      }
    }
  }

  return {'text': paragraphs.join('\n'), 'images': images, 'glyphs': glyphs};
}

List<String> _imageSources(String html) =>
    RegExp(r'<img[^>]*\ssrc="([^"]+)"')
        .allMatches(html)
        .map((m) => _decodeEntities(m[1]!))
        .toList();

List<String> _paragraphs(String html) =>
    RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true)
        .allMatches(html)
        .map((m) => _plain(m[1]!))
        .where((p) => p.isNotEmpty)
        .toList();

/// 태그를 지우고 엔티티를 풀어 한 줄 글로 만든다.
String _plain(String html) => _decodeEntities(
  html
      .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
      .replaceAll(RegExp(r'<[^>]+>'), ' '),
).replaceAll(RegExp(r'\s+'), ' ').trim();

String _decodeEntities(String s) => s
    .replaceAllMapped(
      RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'),
      (m) => String.fromCharCode(
        m[1]!.startsWith('x')
            ? int.parse(m[1]!.substring(1), radix: 16)
            : int.parse(m[1]!),
      ),
    )
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

Future<Object?> _getJson(Uri uri) async {
  await Future<void>.delayed(_delay);
  final request = await _client.getUrl(uri);
  request.headers.set(
    HttpHeaders.refererHeader,
    'https://hanja.dict.naver.com/',
  );
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw HttpException('요청 실패 (${response.statusCode})', uri: uri);
  }
  return jsonDecode(body);
}

void _save(File out, Map<String, dynamic> saved) {
  final sorted = Map.fromEntries(
    saved.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  out.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
  );
}

/// 사전 순서대로 글자마다 한 줄: 한자, 훈음, 출처별 분류, 한자로드 본문.
void _writeReport(Map<String, dynamic> saved, Set<String> all) {
  final lines = ['한자\t훈음\t구성원리(한자로드)\t구성원리(기타)\t자형\t본문(한자로드)'];
  for (final hanja in all) {
    final data = saved[hanja] as Map<String, dynamic>?;
    if (data == null) {
      lines.add('$hanja\t\t\t\t\t(아직 받지 않음)');
      continue;
    }
    final origins = (data['origins'] as List).cast<Map<String, dynamic>>();
    final road = origins.where((o) => o['source'] == '한자로드').firstOrNull;
    final others = origins
        .where((o) => o['source'] != '한자로드')
        .map((o) => '${o['source']}:${o['type']}')
        .join(', ');
    final glyphs = ((road?['glyphs'] as List?) ?? const [])
        .map((g) => g['label'])
        .join(', ');
    // 탭·줄바꿈은 TSV 를 깨뜨리므로 공백 하나로 바꾼다.
    final text = '${road?['text'] ?? ''}'.replaceAll(RegExp(r'\s+'), ' ');
    lines.add(
      [
        hanja,
        data['reading'],
        road?['type'] ?? '',
        others,
        glyphs,
        text,
      ].join('\t'),
    );
  }
  File(_reportPath).writeAsStringSync('${lines.join('\n')}\n');
}
