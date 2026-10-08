import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/hanja_matcher.dart';
import '../../data/models/hanja_word.dart';
import '../../data/models/verse.dart';

/// 구절 본문에서 한자어를 강조하고, 누르면 [onWordTap] 을 호출한다.
class VerseText extends StatefulWidget {
  const VerseText({
    super.key,
    required this.verse,
    required this.showHanja,
    required this.onWordTap,
    this.style,
  });

  final Verse verse;
  final bool showHanja;
  final void Function(HanjaWord word) onWordTap;
  final TextStyle? style;

  @override
  State<VerseText> createState() => _VerseTextState();
}

class _VerseTextState extends State<VerseText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final p = context.palette;
    final base = widget.style ?? AppText.scripture(context);
    final highlight = base.copyWith(
      color: p.gold,
      backgroundColor: p.goldTint,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: p.gold,
    );

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in findWordMatches(widget.verse)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: widget.verse.text.substring(cursor, m.start)));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onWordTap(m.word);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: widget.showHanja
              ? '${m.word.korean}(${m.word.hanja})'
              : m.word.korean,
          style: highlight,
          recognizer: recognizer,
        ),
      );
      cursor = m.start + m.word.korean.length;
    }
    if (cursor < widget.verse.text.length) {
      spans.add(TextSpan(text: widget.verse.text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: base, children: spans));
  }
}

class WordMatch {
  const WordMatch(this.start, this.word);
  final int start;
  final HanjaWord word;
}

/// 본문에서 한자어 위치를 찾는다. 규칙은 [matchWords] (어절 첫머리, 긴 단어 우선).
List<WordMatch> findWordMatches(Verse verse) {
  final byKorean = {for (final w in verse.words) w.korean: w};
  return [
    for (final m in matchWords(verse.text, byKorean.keys))
      WordMatch(m.start, byKorean[m.word]!),
  ];
}
