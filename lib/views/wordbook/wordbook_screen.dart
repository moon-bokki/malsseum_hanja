import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/saved_word.dart';
import '../../viewmodels/wordbook_viewmodel.dart';
import '../widgets/ui.dart';
import 'writing_practice_panel.dart';

class WordbookScreen extends ConsumerWidget {
  const WordbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final state = ref.watch(wordbookViewModelProvider);
    final filter = ref.watch(wordbookFilterProvider);
    final filterVm = ref.read(wordbookFilterProvider.notifier);
    final total = state.value?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: '나의 단어장',
                trailing: Text.rich(
                  TextSpan(
                    text: '저장한 한자어 ',
                    children: [
                      TextSpan(
                        text: '$total',
                        style: TextStyle(
                          color: p.accentStrong,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: '개'),
                    ],
                  ),
                  style: AppText.ui(context, 13, color: p.muted),
                ),
              ),
              const SizedBox(height: 14),
              SearchBar(
                hintText: '한글 또는 한자로 검색',
                leading: Icon(Icons.search, size: 20, color: p.muted),
                onChanged: filterVm.setQuery,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in WordbookSort.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: filter.sort == s,
                      onSelected: (_) => filterVm.setSort(s),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: state.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('오류: $e')),
                  data: (words) {
                    if (words.isEmpty) {
                      return Center(
                        child: Text(
                          '본문에서 한자어를 눌러\n단어장에 저장해 보세요.',
                          textAlign: TextAlign.center,
                          style: AppText.ui(context, 15, color: p.muted),
                        ),
                      );
                    }
                    final shown = filterWordbook(words, filter);
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        for (final s in shown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _WordRow(saved: s),
                          ),
                        if (shown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '검색 결과가 없습니다',
                              textAlign: TextAlign.center,
                              style: AppText.ui(context, 15, color: p.muted),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '누르면 쓰기 연습 · 왼쪽으로 밀면 삭제',
                          textAlign: TextAlign.center,
                          style: AppText.ui(context, 12, color: p.muted),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordRow extends ConsumerWidget {
  const _WordRow({required this.saved});

  final SavedWord saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = saved;
    return Dismissible(
      key: ValueKey(s.word.korean),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: p.wrongTint,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: p.wrong),
      ),
      onDismissed: (_) =>
          ref.read(wordbookViewModelProvider.notifier).remove(s.word.korean),
      child: SurfaceCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () =>
            showWritingPractice(context, word: s.word, verseRef: s.verseRef),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(s.word.hanja, style: AppText.hanja(context, 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.word.korean,
                    style: AppText.ui(context, 16, weight: FontWeight.w700),
                  ),
                  Text(
                    s.verseRef,
                    style: AppText.ui(context, 12, color: p.muted),
                  ),
                ],
              ),
            ),
            _Badge(
              text: '○ ${s.correctCount}',
              fg: p.correct,
              bg: p.correctTint,
            ),
            const SizedBox(width: 6),
            _Badge(text: '× ${s.wrongCount}', fg: p.wrong, bg: p.wrongTint),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.fg, required this.bg});

  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppText.ui(context, 12, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}
