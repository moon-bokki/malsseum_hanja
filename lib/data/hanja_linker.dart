import 'hanja_matcher.dart';
import 'models/hanja_word.dart';
import 'models/verse.dart';

/// 한자어 사전(tool/data/hanja_words.json)의 한 항목.
class HanjaDictEntry {
  const HanjaDictEntry(
    this.word, {
    this.forms = const [],
    this.except = const [],
  });

  final HanjaWord word;

  /// 동음이의어일 때 이 한자로 정하는 어절 첫머리 (예: 仁慈 ← '인자하', '인자함').
  final List<String> forms;

  /// 이 어절로 시작하면 다른 낱말이다 (예: 天下 ← '천하게' 는 賤하다).
  final List<String> except;

  factory HanjaDictEntry.fromJson(Map<String, dynamic> json) => HanjaDictEntry(
    HanjaWord.fromJson(json),
    forms: [...?(json['forms'] as List?)?.cast<String>()],
    except: [...?(json['except'] as List?)?.cast<String>()],
  );
}

/// 한자어 사전을 구절에 자동으로 연결한 결과 (tool/build_bible_db.dart 에서 쓴다).
class HanjaLinks {
  const HanjaLinks(this.verses, this.unreviewed);

  /// 검토된 한자어가 붙은 구절 (앱에 보인다).
  final List<Verse> verses;

  /// 구절 id → 검토가 필요한 한자어 (동음이의어 등, 앱에 보이지 않는다).
  final Map<String, List<HanjaWord>> unreviewed;
}

/// [dictionary] 의 단어를 본문에서 찾아([matchWords] 규칙) 구절에 붙인다.
///
/// - 한글 표기가 사전에 하나뿐인 단어 → 자동 연결 (검토 완료로 본다).
/// - 동음이의어 (인자 仁慈/人子) → 어절이 한 항목의 forms 로 시작하면 그 한자로,
///   아니면 검토 필요.
/// - 어절이 except 로 시작하면 다른 낱말이므로 그 구절에는 이 단어를 붙이지 않는다.
///   (같은 구절에 맞는 쓰임이 함께 있어도 화면에서 잘못 강조되지 않게 통째로 뺀다.)
/// - 한 구절 안에서 같은 한글이 서로 다른 한자로 판정되면 검토 필요.
/// - 구절에 이미 손으로 넣은 단어(verses.json)가 있으면 그것이 우선이다.
/// - [exclude] (구절 id → 한글 표기) 에 있는 단어는 그 구절에 붙이지 않는다.
HanjaLinks linkHanjaWords(
  List<Verse> verses,
  List<HanjaDictEntry> dictionary, {
  Map<String, Set<String>> exclude = const {},
}) {
  final byKorean = <String, List<HanjaDictEntry>>{};
  for (final e in dictionary) {
    final list = byKorean.putIfAbsent(e.word.korean, () => []);
    if (!list.any((x) => x.word == e.word)) list.add(e);
  }

  final linked = <Verse>[];
  final unreviewed = <String, List<HanjaWord>>{};
  for (final v in verses) {
    final manual = {for (final w in v.words) w.korean: w};
    final skip = exclude[v.id] ?? const <String>{};

    // 한글 표기별로, 구절 안의 모든 쓰임에서 판정된 한자 후보를 모은다.
    final resolved = <String, Set<HanjaWord>>{};
    final blocked = <String>{};
    final order = <String>[];

    for (final m in matchWords(v.text, {...manual.keys, ...byKorean.keys})) {
      final korean = m.word;
      if (skip.contains(korean) || blocked.contains(korean)) continue;
      if (!order.contains(korean)) order.add(korean);

      if (manual[korean] case final w?) {
        (resolved[korean] ??= {}).add(w);
        continue;
      }
      final eojeol = _eojeolAt(v.text, m.start);
      final entries = byKorean[korean]!;
      if (entries.any((e) => e.except.any(eojeol.startsWith))) {
        blocked.add(korean);
        continue;
      }
      final byForm = entries
          .where((e) => e.forms.any(eojeol.startsWith))
          .toList();
      final chosen = entries.length == 1
          ? entries
          : byForm.length == 1
          ? byForm
          : entries;
      (resolved[korean] ??= {}).addAll(chosen.map((e) => e.word));
    }

    final words = <HanjaWord>[];
    final pending = <HanjaWord>[];
    for (final korean in order) {
      if (blocked.contains(korean)) continue;
      final candidates = resolved[korean] ?? const <HanjaWord>{};
      (candidates.length == 1 ? words : pending).addAll(candidates);
    }
    // 본문에서 찾지 못한 손 입력 단어도 버리지 않는다.
    for (final w in v.words) {
      if (!words.contains(w)) words.add(w);
    }

    linked.add(
      Verse(
        id: v.id,
        book: v.book,
        chapter: v.chapter,
        verse: v.verse,
        text: v.text,
        words: words,
      ),
    );
    if (pending.isNotEmpty) unreviewed[v.id] = pending;
  }
  return HanjaLinks(linked, unreviewed);
}

/// [start] 에서 시작하는 어절 (다음 공백·문장부호 전까지).
String _eojeolAt(String text, int start) {
  final end = text.indexOf(RegExp(r'[\s,.;:?!"()]'), start);
  return text.substring(start, end == -1 ? text.length : end);
}
