import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_book.dart';
import '../../data/models/hanja_word.dart';
import '../../data/models/verse.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/quiz_viewmodel.dart';
import '../../viewmodels/reader_viewmodel.dart';
import '../../viewmodels/shell_viewmodel.dart';
import '../../viewmodels/word_detail_viewmodel.dart';
import '../reader/chapter_screen.dart';
import '../widgets/ui.dart';
import '../widgets/verse_text.dart';
import '../word_detail/word_detail_sheet.dart';

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류: $e')),
          data: (verse) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const _Header(),
              const SizedBox(height: 20),
              _TodayVerse(verse: verse),
              const SizedBox(height: 20),
              _TodayWords(verse: verse),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  ref.read(selectedTabProvider.notifier).select(AppTab.quiz);
                  ref.read(quizViewModelProvider.notifier).start();
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('한자어 퀴즈 풀기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final now = DateTime.now();
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '言',
            style: AppText.hanja(context, 20).copyWith(color: p.onAccent),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '말씀한자',
                style: AppText.ui(context, 18, weight: FontWeight.w700),
              ),
              Text(
                '${now.month}월 ${now.day}일 ${_weekdays[now.weekday - 1]}요일',
                style: AppText.ui(context, 12, color: p.muted),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: '알림 설정',
          style: IconButton.styleFrom(
            backgroundColor: p.surface,
            side: BorderSide(color: p.border),
            minimumSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.notifications_none, size: 20),
          onPressed: () =>
              ref.read(selectedTabProvider.notifier).select(AppTab.my),
        ),
      ],
    );
  }
}

class _TodayVerse extends ConsumerWidget {
  const _TodayVerse({required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final showHanja = ref.watch(showHanjaProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: '오늘의 말씀',
          trailing: Pill(
            showHanja ? '한자 병기 켜짐' : '한자 병기 꺼짐',
            onTap: () => ref.read(showHanjaProvider.notifier).toggle(),
          ),
        ),
        const SizedBox(height: 10),
        SurfaceCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VerseText(
                verse: verse,
                showHanja: showHanja,
                style: AppText.scripture(context, size: 18),
                onWordTap: (w) => showWordDetailSheet(
                  context,
                  word: w,
                  verseRef: verse.reference,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '밑줄 친 단어를 눌러 보세요',
                      style: AppText.ui(context, 12, color: p.muted),
                    ),
                  ),
                  Text(
                    verse.reference,
                    style: AppText.ui(
                      context,
                      14,
                      weight: FontWeight.w700,
                      color: p.accentStrong,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayWords extends StatelessWidget {
  const _TodayWords({required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final book = BibleBook.byName(verse.book);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '오늘의 한자어 ',
                  children: [
                    TextSpan(
                      text: '${verse.words.length}',
                      style: TextStyle(color: p.accentText),
                    ),
                  ],
                ),
                style: AppText.ui(context, 17, weight: FontWeight.w700),
              ),
            ),
            if (book != null)
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChapterScreen(
                      book: book,
                      chapter: verse.chapter,
                      verse: verse.verse,
                    ),
                  ),
                ),
                child: Text(
                  '본문 전체 보기',
                  style: AppText.ui(
                    context,
                    13,
                    weight: FontWeight.w500,
                    color: p.accentText,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final w in verse.words)
              _WordCard(word: w, verseRef: verse.reference),
          ],
        ),
      ],
    );
  }
}

class _WordCard extends ConsumerWidget {
  const _WordCard({required this.word, required this.verseRef});

  final HanjaWord word;
  final String verseRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final chars = ref.watch(hanjaCharsProvider(word)).value ?? const [];
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      onTap: () => showWordDetailSheet(context, word: word, verseRef: verseRef),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(child: Text(word.hanja, style: AppText.hanja(context, 28))),
          const SizedBox(height: 4),
          Text(
            word.korean,
            style: AppText.ui(context, 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            chars.map((c) => c.hunEum).join(' · '),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.ui(context, 11, color: p.muted),
          ),
        ],
      ),
    );
  }
}
