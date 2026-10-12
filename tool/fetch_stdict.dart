// 한자어마다 국립국어원 표준국어대사전 뜻풀이를 받아 tool/data/stdict_meanings.json 으로 저장한다.
//
//   dart run tool/fetch_stdict.dart               ← 아직 받지 않은 단어만 받는다
//   dart run tool/fetch_stdict.dart 은혜 장로     ← 지정한 단어만 다시 받는다
//   dart run tool/fetch_stdict.dart --refresh     ← 전부 다시 받는다
//   dart run tool/build_bible_db.dart             ← 이어서 bible.db 를 다시 만든다
//
// 인증키는 --key=키, 환경 변수 STDICT_API_KEY, 프로젝트 루트의 .env (DIC_KEY=키) 순서로 찾는다.
// .env 는 .gitignore 에 들어 있어 커밋되지 않는다.
// 키 발급: https://stdict.korean.go.kr → 오픈 API → 인증키 신청
//
// 입력
//   tool/data/hanja_words.json   한자어 사전
//   tool/data/verses.json        손으로 검토한 구절별 한자어 (사전에 없는 단어도 함께 받는다)
//
// 출력
//   tool/data/stdict_meanings.json  "한글/한자" → 상태·품사·뜻풀이 (다시 실행하면 이어서 받는다)
//   tool/data/stdict_report.tsv     검토용 요약 (스프레드시트로 열기)
//
// 같은 한글 표제어가 여럿이므로(장로 長老 / 長路 …) 표제어 상세의 원어(한자)가
// 우리 한자와 같은 것만 쓴다. 맞는 표제어가 없으면 앱 내장 뜻풀이를 그대로 쓴다.
//
// 출처: 국립국어원 표준국어대사전 (CC BY-SA 2.0 KR, 앱에 출처 표시 필요)
import 'dart:convert';
import 'dart:io';

import 'package:malsseum_hanja/core/network/dio_client.dart';
import 'package:malsseum_hanja/data/datasources/remote/stdict_api.dart';
import 'package:malsseum_hanja/data/hanja_linker.dart';
import 'package:malsseum_hanja/data/models/hanja_word.dart';
import 'package:malsseum_hanja/data/models/verse.dart';

const _dictionaryPath = 'tool/data/hanja_words.json';
const _annotatedPath = 'tool/data/verses.json';
const _outPath = 'tool/data/stdict_meanings.json';
const _reportPath = 'tool/data/stdict_report.tsv';
const _envPath = '.env';

/// 요청 사이 간격.
const _delay = Duration(milliseconds: 300);

/// 상태 값. build_bible_db.dart 는 '일치' 인 것만 쓴다.
const _matched = '일치';
const _mismatch = '한자 불일치';
const _notFound = '검색 결과 없음';

Future<void> main(List<String> args) async {
  final key =
      args
          .where((a) => a.startsWith('--key='))
          .map((a) => a.substring(6))
          .firstOrNull ??
      Platform.environment['STDICT_API_KEY'] ??
      _envKey() ??
      '';
  if (key.isEmpty) {
    stderr.writeln(
      '인증키가 없습니다. .env 에 DIC_KEY=발급받은키 를 넣거나 --key=발급받은키 로 주세요.\n'
      '키 발급: https://stdict.korean.go.kr → 오픈 API → 인증키 신청',
    );
    exitCode = 64;
    return;
  }
  final refresh = args.contains('--refresh');
  final picked = args.where((a) => !a.startsWith('--')).toSet();

  final out = File(_outPath);
  final saved = out.existsSync()
      ? (jsonDecode(out.readAsStringSync()) as Map<String, dynamic>)
      : <String, dynamic>{};

  final words = _allWords();
  final targets = words
      .where(
        (w) => picked.isNotEmpty
            ? picked.contains(w.korean)
            : refresh || !saved.containsKey(_key(w)),
      )
      .toList();
  stdout.writeln(
    '받을 단어: ${targets.length}개 (전체 ${words.length}개, 저장됨 ${saved.length}개)',
  );

  final api = StdictApi(createDioClient(), apiKey: key);
  try {
    for (final (i, word) in targets.indexed) {
      final progress = '[${i + 1}/${targets.length}]';
      try {
        final result = await _fetch(api, word);
        saved[_key(word)] = result;
        stdout.writeln(
          '$progress ${word.korean} ${word.hanja} — ${result['status']}'
          '${result['status'] == _matched ? ' (${(result['definitions'] as List).length}개 뜻)' : ''}',
        );
      } on StdictException catch (e) {
        // 인증키 오류·사용량 초과는 다른 단어도 똑같이 실패하므로 멈춘다.
        stderr.writeln('$progress ${word.korean} 중단: $e');
        exitCode = 1;
        break;
      } on Exception catch (e) {
        // 저장하지 않으면 다음 실행 때 다시 받는다.
        stderr.writeln('$progress ${word.korean} 실패: $e');
      }
      _save(out, saved);
    }
  } finally {
    _save(out, saved);
  }

  _writeReport(saved, words);
  final ok = saved.values.where((v) => v['status'] == _matched).length;
  stdout.writeln('$_outPath 저장: ${saved.length}개 중 일치 $ok개');
  stdout.writeln('$_reportPath 저장 — 이어서 dart run tool/build_bible_db.dart');
}

/// .env 의 DIC_KEY (또는 STDICT_API_KEY). 키 값은 출력하지 않는다.
String? _envKey() {
  final file = File(_envPath);
  if (!file.existsSync()) return null;
  final lines = file
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toList();
  for (final (i, line) in lines.indexed) {
    final eq = line.indexOf('=');
    if (eq < 0) continue;
    final name = line.substring(0, eq).trim();
    if (name != 'DIC_KEY' && name != 'STDICT_API_KEY') continue;
    var value = line.substring(eq + 1).trim().replaceAll(RegExp('["\']'), '');
    // "DIC_KEY=" 다음 줄에 키만 적은 경우도 받아 준다.
    if (value.isEmpty && i + 1 < lines.length && !lines[i + 1].contains('=')) {
      value = lines[i + 1];
      stderr.writeln(
        '참고: .env 의 $name 값이 다음 줄에 있습니다. 한 줄($name=키)로 적는 것이 표준입니다.',
      );
    }
    if (value.isNotEmpty) return value;
  }
  return null;
}

String _key(HanjaWord w) => '${w.korean}/${w.hanja}';

/// 사전과 손으로 검토한 구절에 나오는 한자어 (중복 없이, 사전 순서 먼저).
List<HanjaWord> _allWords() {
  final dictionary =
      (jsonDecode(File(_dictionaryPath).readAsStringSync()) as List).map(
        (e) => HanjaDictEntry.fromJson(e as Map<String, dynamic>).word,
      );
  final annotated =
      (jsonDecode(File(_annotatedPath).readAsStringSync()) as List)
          .map((e) => Verse.fromJson(e as Map<String, dynamic>))
          .expand((v) => v.words);
  return {...dictionary, ...annotated}.toList();
}

/// 한글로 검색해 표제어와 원어(한자)가 모두 같은 항목을 고르고, 상세에서 모든 뜻풀이를 받는다.
/// (검색 결과에는 뜻풀이가 하나만 들어 있다.)
Future<Map<String, dynamic>> _fetch(StdictApi api, HanjaWord word) async {
  await Future<void>.delayed(_delay);
  final items = (await api.search(
    word.korean,
    num: 100,
  )).where((i) => i.word == word.korean).toList();
  if (items.isEmpty) return {'status': _notFound};

  // 이체자는 '/'로 함께 적혀 온다 (詛呪/咀呪).
  final item = items
      .where((i) => i.origin.split('/').contains(word.hanja))
      .firstOrNull;
  if (item == null) {
    return {
      'status': _mismatch,
      'candidates': [
        for (final o in {for (final i in items) i.origin})
          o.isEmpty ? '(고유어)' : o,
      ],
    };
  }

  await Future<void>.delayed(_delay);
  final entry = item.targetCode.isEmpty
      ? null
      : await api.view(item.targetCode);
  final definitions = entry?.definitions.isNotEmpty ?? false
      ? entry!.definitions
      : [
          for (final i in items)
            if (i.targetCode == item.targetCode) i.definition,
        ];
  return {
    'status': _matched,
    'targetCode': item.targetCode,
    'pos': entry?.pos ?? item.pos,
    'definitions': definitions,
  };
}

void _save(File out, Map<String, dynamic> saved) {
  final sorted = Map.fromEntries(
    saved.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  out.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
  );
}

/// 단어마다 한 줄: 한글, 한자, 상태, 품사, 첫 뜻풀이, (불일치면) 사전에 있는 원어들.
void _writeReport(Map<String, dynamic> saved, List<HanjaWord> words) {
  final lines = ['한글\t한자\t상태\t품사\t뜻풀이\t사전의 원어 후보'];
  for (final w in words) {
    final data = saved[_key(w)] as Map<String, dynamic>?;
    final definitions = (data?['definitions'] as List?)?.cast<String>() ?? [];
    lines.add(
      [
        w.korean,
        w.hanja,
        data?['status'] ?? '(아직 받지 않음)',
        data?['pos'] ?? '',
        // 뜻이 여럿이면 번호를 붙여 한 칸에 넣는다.
        [
          for (final (i, d) in definitions.indexed)
            definitions.length > 1 ? '${i + 1}. $d' : d,
        ].join(' '),
        ((data?['candidates'] as List?) ?? const []).join(', '),
      ].join('\t'),
    );
  }
  File(_reportPath).writeAsStringSync('${lines.join('\n')}\n');
}
