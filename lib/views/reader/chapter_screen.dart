import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_book.dart';
import '../../data/models/verse.dart';
import '../../viewmodels/reader_viewmodel.dart';
import '../../viewmodels/word_detail_viewmodel.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/ui.dart';
import '../widgets/verse_text.dart';
import '../word_detail/word_detail_sheet.dart';
import 'reader_screen.dart' show HanjaToggle;

/// 한 장 읽기. [verse] 를 주면 그 절로 이동해 강조한다.
class ChapterScreen extends ConsumerStatefulWidget {
  const ChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.verse,
  });

  final BibleBook book;
  final int chapter;
  final int? verse;

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  late int _chapter = widget.chapter;
  late int? _verse = widget.verse;
  final _targetKey = GlobalKey();
  bool _scrolled = false;

  void _goTo(int chapter) => setState(() {
    _chapter = chapter;
    _verse = null;
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final book = widget.book;
    final state = ref.watch(chapterProvider((book, _chapter)));
    final showHanja = ref.watch(showHanjaProvider);

    if (_verse != null && !_scrolled && state.hasValue) {
      _scrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _targetKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.2);
      });
    }

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        backgroundColor: p.surface,
        titleSpacing: 0,
        title: Text('${book.name} $_chapter장'),
        actions: const [HanjaToggle(), SizedBox(width: 8)],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (verses) => verses.isEmpty
            ? Center(
                child: Text(
                  '이 장의 본문이 아직 없습니다',
                  style: AppText.ui(context, 15, color: p.muted),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final v in verses)
                      // 구절을 누르면 선택되고, 그 구절의 한자어 카드가 아래에 나온다.
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(
                          () => _verse = _verse == v.verse ? null : v.verse,
                        ),
                        child: Container(
                          key: v.verse == _verse ? _targetKey : null,
                          padding: const EdgeInsets.fromLTRB(8, 14, 8, 18),
                          decoration: BoxDecoration(
                            color: v.verse == _verse ? p.accentTint : null,
                            borderRadius: v.verse == _verse
                                ? BorderRadius.circular(12)
                                : null,
                            border: v.verse == _verse
                                ? null
                                : Border(bottom: BorderSide(color: p.divider)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.reference,
                                style: AppText.ui(
                                  context,
                                  12,
                                  weight: FontWeight.w700,
                                  color: p.accentText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              VerseText(
                                verse: v,
                                showHanja: showHanja,
                                onWordTap: (w) => showWordDetailSheet(
                                  context,
                                  word: w,
                                  verseRef: v.reference,
                                ),
                              ),
                              if (v.verse == _verse) ...[
                                const SizedBox(height: 12),
                                _VerseWords(verse: v),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      // 이전/다음 장 버튼 아래에 앱 하단 탭을 둔다 (아래쪽 안전 영역은 탭 바가 맡는다).
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _chapter > 1 ? () => _goTo(_chapter - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('이전 장'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _chapter < book.chapterCount
                        ? () => _goTo(_chapter + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('다음 장'),
                  ),
                ],
              ),
            ),
          ),
          const AppNavigationBar(),
        ],
      ),
    );
  }
}

/// 선택한 구절의 한자어 카드 (한자 · 한글 · 훈음). 누르면 상세 창이 열린다.
class _VerseWords extends ConsumerWidget {
  const _VerseWords({required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    if (verse.words.isEmpty) {
      return Text(
        '이 구절에는 아직 표시할 한자어가 없습니다',
        style: AppText.ui(context, 12, color: p.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이 구절의 한자어 ${verse.words.length}',
          style: AppText.ui(
            context,
            12,
            weight: FontWeight.w700,
            color: p.accentStrong,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in verse.words)
              SurfaceCard(
                radius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onTap: () => showWordDetailSheet(
                  context,
                  word: w,
                  verseRef: verse.reference,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(w.hanja, style: AppText.hanja(context, 22)),
                    Text(
                      w.korean,
                      style: AppText.ui(context, 13, weight: FontWeight.w700),
                    ),
                    Text(
                      (ref.watch(hanjaCharsProvider(w)).value ?? const [])
                          .map((c) => c.hunEum)
                          .join(' · '),
                      style: AppText.ui(context, 11, color: p.muted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
