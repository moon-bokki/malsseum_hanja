import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_query.dart';
import '../../data/models/hanja_char.dart';
import '../../data/models/hanja_word.dart';
import '../../viewmodels/reader_viewmodel.dart';
import '../../viewmodels/word_detail_viewmodel.dart';
import '../reader/reader_screen.dart' show openChapter;
import '../widgets/ui.dart';

Future<void> showWordDetailSheet(
  BuildContext context, {
  required HanjaWord word,
  required String verseRef,
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => WordDetailSheet(word: word, verseRef: verseRef),
  );
}

class WordDetailSheet extends ConsumerWidget {
  const WordDetailSheet({
    super.key,
    required this.word,
    required this.verseRef,
  });

  final HanjaWord word;
  final String verseRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = wordDetailViewModelProvider(word);
    final state = ref.watch(provider);
    final p = context.palette;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: state.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('불러오지 못했습니다: $e'),
          data: (s) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(word.hanja, style: AppText.hanja(context, 48)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        word.korean,
                        style: AppText.ui(context, 24, weight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: s.isSaved ? '단어장에서 빼기' : '단어장에 저장',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: s.isSaved ? p.accent : p.accentTint,
                        foregroundColor: s.isSaved
                            ? p.onAccent
                            : p.accentStrong,
                      ),
                      icon: Icon(
                        s.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      onPressed: () =>
                          ref.read(provider.notifier).toggleSave(verseRef),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (final (i, c) in s.chars.indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: _CharCard(char: c)),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      '뜻풀이',
                      style: AppText.ui(context, 15, weight: FontWeight.w700),
                    ),
                    if (s.entry.pos != null) ...[
                      const SizedBox(width: 8),
                      Pill(s.entry.pos!),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                for (final (i, d) in s.entry.definitions.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${i + 1}. $d',
                      style: AppText.ui(context, 15).copyWith(height: 1.7),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  s.entry.fromApi ? '출처: 국립국어원 표준국어대사전' : '출처: 앱 내장 사전',
                  style: AppText.ui(context, 12, color: p.muted),
                ),
                if (verseRef.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    '이 단어가 나온 구절',
                    style: AppText.ui(context, 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _VerseLink(verseRef: verseRef),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharCard extends StatelessWidget {
  const _CharCard({required this.char});

  final HanjaChar char;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      color: p.background,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          Text(char.char, style: AppText.hanja(context, 40)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: '${char.hun} ',
              children: [
                TextSpan(
                  text: char.eum,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: AppText.ui(context, 15, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// 단어가 나온 구절. 누르면 그 장을 연다.
class _VerseLink extends ConsumerWidget {
  const _VerseLink({required this.verseRef});

  final String verseRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final verse = ref.watch(verseByRefProvider(verseRef)).value;
    final parsed = BibleReference.parse(verseRef);
    final preview = verse == null ? '' : ' · ${verse.text}';
    return Material(
      color: p.goldTint,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: parsed == null
            ? null
            : () {
                final navigator = Navigator.of(context);
                navigator.pop();
                openChapter(
                  navigator.context,
                  parsed.book,
                  parsed.chapter,
                  parsed.verse,
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$verseRef$preview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.ui(
                    context,
                    14,
                    weight: FontWeight.w500,
                    color: p.goldStrong,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: p.goldStrong),
            ],
          ),
        ),
      ),
    );
  }
}
