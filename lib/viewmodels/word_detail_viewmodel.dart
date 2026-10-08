import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/dictionary_entry.dart';
import '../data/models/hanja_char.dart';
import '../data/models/hanja_word.dart';
import '../providers.dart';

class WordDetailState {
  const WordDetailState({
    required this.entry,
    required this.chars,
    required this.isSaved,
  });

  final DictionaryEntry entry;
  final List<HanjaChar> chars;
  final bool isSaved;

  WordDetailState copyWith({bool? isSaved}) => WordDetailState(
    entry: entry,
    chars: chars,
    isSaved: isSaved ?? this.isSaved,
  );
}

class WordDetailViewModel extends AsyncNotifier<WordDetailState> {
  WordDetailViewModel(this.word);

  final HanjaWord word;

  @override
  Future<WordDetailState> build() async {
    final results = await Future.wait([
      ref.watch(dictionaryRepositoryProvider).lookup(word),
      ref.watch(bibleRepositoryProvider).getHanjaChars(word),
      ref.watch(wordbookRepositoryProvider).isSaved(word.korean),
    ]);
    return WordDetailState(
      entry: results[0] as DictionaryEntry,
      chars: results[1] as List<HanjaChar>,
      isSaved: results[2] as bool,
    );
  }

  Future<void> toggleSave(String verseRef) async {
    final current = state.value;
    if (current == null) return;
    final repo = ref.read(wordbookRepositoryProvider);
    if (current.isSaved) {
      await repo.remove(word.korean);
    } else {
      await repo.save(word, verseRef);
    }
    state = AsyncData(current.copyWith(isSaved: !current.isSaved));
  }
}

final wordDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<WordDetailViewModel, WordDetailState, HanjaWord>(
      WordDetailViewModel.new,
    );

/// 한자어의 글자별 훈음 (恩惠 → 은혜 은, 은혜 혜).
final hanjaCharsProvider = FutureProvider.family<List<HanjaChar>, HanjaWord>(
  (ref, word) => ref.watch(bibleRepositoryProvider).getHanjaChars(word),
);
