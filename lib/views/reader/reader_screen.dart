import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bible_book.dart';
import '../../data/models/verse.dart';
import '../../viewmodels/reader_viewmodel.dart';
import '../widgets/ui.dart';
import '../widgets/verse_text.dart';
import '../word_detail/word_detail_sheet.dart';
import 'chapter_screen.dart';

void openChapter(
  BuildContext context,
  BibleBook book,
  int chapter, [
  int? verse,
]) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ChapterScreen(book: book, chapter: chapter, verse: verse),
  ),
);

/// '한자 병기' 글자와 스위치.
class HanjaToggle extends ConsumerWidget {
  const HanjaToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHanja = ref.watch(showHanjaProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('한자 병기', style: AppText.ui(context, 13)),
        const SizedBox(width: 4),
        Switch(
          value: showHanja,
          onChanged: (_) => ref.read(showHanjaProvider.notifier).toggle(),
        ),
      ],
    );
  }
}

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _controller.clear();
    ref.read(bibleSearchProvider.notifier).setText('');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final search = ref.watch(bibleSearchProvider);
    final counts = ref.watch(verseCountsProvider).value ?? const {};
    final searchVm = ref.read(bibleSearchProvider.notifier);
    final hasText = search.text.trim().isNotEmpty;
    final book = search.book;

    // 검색어가 있으면 결과 표, 책을 골랐으면 장 번호 표, 아니면 66권 책 목록.
    final Widget content;
    if (hasText) {
      content = const _Results();
    } else if (book != null) {
      content = _ChapterGrid(book: book);
    } else {
      content = _BookPicker(testament: search.testament, counts: counts);
    }

    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: const ScreenHeader(
                title: '성경 읽기',
                trailing: HanjaToggle(),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SearchBar(
                controller: _controller,
                hintText: '책, 장절, 본문, 한자어 (예: 요 3:16, 恩惠)',
                leading: Icon(Icons.search, size: 20, color: p.muted),
                trailing: [
                  if (search.text.isNotEmpty)
                    IconButton(
                      tooltip: '지우기',
                      icon: const Icon(Icons.close),
                      onPressed: _clearQuery,
                    ),
                ],
                onChanged: searchVm.setText,
              ),
            ),
            _ChipRow(
              children: [
                for (final t in [null, ...Testament.values])
                  ChoiceChip(
                    label: Text(t?.label ?? '전체'),
                    selected: search.testament == t,
                    onSelected: (_) => searchVm.setTestament(t),
                  ),
              ],
            ),
            if (book != null) _SelectedBookBar(book: book),
            const Divider(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

/// 66권 책 목록. 구약/신약으로 나눠 모든 책을 여러 줄에 보여 준다.
class _BookPicker extends ConsumerWidget {
  const _BookPicker({required this.testament, required this.counts});

  /// null 이면 구약과 신약을 모두 보여 준다.
  final Testament? testament;

  /// 책별 구절 수. 본문이 없는 책은 누를 수 없다.
  final Map<int, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final groups = testament == null ? Testament.values : [testament!];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final t in groups) ...[
            Text.rich(
              TextSpan(
                text: '${t.label} · ',
                children: [
                  TextSpan(
                    text: '${BibleBook.of(t).length}권',
                    style: TextStyle(color: p.accentText),
                  ),
                ],
              ),
              style: AppText.ui(context, 15, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in BibleBook.of(t))
                  FilterChip(
                    label: Text(b.name),
                    selected: false,
                    onSelected: counts[b.number] == null
                        ? null
                        : (_) => ref
                              .read(bibleSearchProvider.notifier)
                              .selectBook(b),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

/// 고른 책 이름과 '다른 책' 버튼 (누르면 책 목록으로 돌아간다).
class _SelectedBookBar extends ConsumerWidget {
  const _SelectedBookBar({required this.book});

  final BibleBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
      child: Row(
        children: [
          FilterChip(
            label: Text(book.name),
            selected: true,
            onSelected: (_) =>
                ref.read(bibleSearchProvider.notifier).selectBook(null),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () =>
                ref.read(bibleSearchProvider.notifier).selectBook(null),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('다른 책'),
          ),
        ],
      ),
    );
  }
}

/// 책을 고르면 보이는 장 번호 표 (한 줄에 [_columns]장).
class _ChapterGrid extends ConsumerWidget {
  const _ChapterGrid({required this.book});

  final BibleBook book;

  static const _columns = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final available =
        ref.watch(availableChaptersProvider(book)).value ?? const {};
    final rows = (book.chapterCount / _columns).ceil();

    Widget cell(int chapter) {
      if (chapter > book.chapterCount) return const SizedBox(height: 52);
      final enabled = available.contains(chapter);
      return InkWell(
        onTap: enabled ? () => openChapter(context, book, chapter) : null,
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              '$chapter',
              style: AppText.ui(
                context,
                16,
                weight: enabled ? FontWeight.w700 : FontWeight.w400,
                color: enabled ? p.accentStrong : p.outline,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: '${book.name} · ',
              children: [
                TextSpan(
                  text: '${book.chapterCount}장',
                  style: TextStyle(color: p.accentText),
                ),
              ],
            ),
            style: AppText.ui(context, 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                type: MaterialType.transparency,
                child: Table(
                  border: TableBorder.symmetric(
                    inside: BorderSide(color: p.border),
                  ),
                  children: [
                    for (var r = 0; r < rows; r++)
                      TableRow(
                        children: [
                          for (var c = 1; c <= _columns; c++)
                            cell(r * _columns + c),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(searchResultsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류: $e')),
          data: (results) {
            if (results.verses.isEmpty) return const _EmptyResult();
            final loadMore = results.hasMore
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: () =>
                            ref.read(searchResultsProvider.notifier).loadMore(),
                        child: Text(
                          '더 보기 (${results.verses.length} / ${results.total})',
                        ),
                      ),
                    ),
                  )
                : null;
            return _VerseTable(results: results, footer: loadMore);
          },
        );
  }
}

/// 검색어가 있을 때: 검색 결과 표. 본문은 장 읽기와 같이 한자어를 강조한다.
class _VerseTable extends ConsumerWidget {
  const _VerseTable({required this.results, this.footer});

  final SearchResults results;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final showHanja = ref.watch(showHanjaProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text.rich(
            TextSpan(
              text: '검색 결과 ',
              children: [
                TextSpan(
                  text: '${results.total}',
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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columnSpacing: 16,
                    horizontalMargin: 20,
                    dataRowMinHeight: 52,
                    // 본문 전체를 보여 주므로 행 높이는 본문 길이에 맞춘다.
                    dataRowMaxHeight: double.infinity,
                    columns: const [
                      DataColumn(label: Text('구분')),
                      DataColumn(label: Text('책')),
                      DataColumn(label: Text('장:절')),
                      DataColumn(label: Text('본문')),
                      DataColumn(label: Text('한자어')),
                    ],
                    rows: [
                      for (final v in results.verses)
                        _row(context, v, showHanja),
                    ],
                  ),
                ),
                ?footer,
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(BuildContext context, Verse v, bool showHanja) {
    final p = context.palette;
    final book = BibleBook.byName(v.book);
    final cell = AppText.ui(context, 14);
    return DataRow(
      onSelectChanged: book == null
          ? null
          : (_) => openChapter(context, book, v.chapter, v.verse),
      cells: [
        DataCell(
          Text(
            book?.testament.label ?? '-',
            style: AppText.ui(context, 12, color: p.muted),
          ),
        ),
        DataCell(
          Text(v.book, style: cell.copyWith(fontWeight: FontWeight.w700)),
        ),
        DataCell(
          Text(
            '${v.chapter}:${v.verse}',
            style: cell.copyWith(
              color: p.accentText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DataCell(
          Container(
            // 구분·책·장:절 칸 뒤에 남는 화면 폭에 맞춰, 가로로 밀지 않아도 본문이 보이게 한다.
            width: (MediaQuery.sizeOf(context).width - 207).clamp(180, 420),
            padding: const EdgeInsets.symmetric(vertical: 10),
            // 한자어를 누르면 상세 창, 그 밖의 곳을 누르면 행(장 읽기)으로 간다.
            child: VerseText(
              verse: v,
              showHanja: showHanja,
              style: AppText.scripture(context, size: 14).copyWith(height: 1.6),
              onWordTap: (w) =>
                  showWordDetailSheet(context, word: w, verseRef: v.reference),
            ),
          ),
        ),
        DataCell(
          Text(
            v.words.map((w) => w.hanja).join(' '),
            style: AppText.hanja(context, 15).copyWith(color: p.gold),
          ),
        ),
      ],
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: p.outline),
            const SizedBox(height: 12),
            Text('검색 결과가 없습니다', style: AppText.ui(context, 15, color: p.muted)),
          ],
        ),
      ),
    );
  }
}
