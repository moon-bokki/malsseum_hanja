import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/verse.dart';
import '../providers.dart';

class HomeViewModel extends AsyncNotifier<Verse> {
  @override
  Future<Verse> build() =>
      ref.watch(bibleRepositoryProvider).getTodayVerse(DateTime.now());
}

final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, Verse>(
  HomeViewModel.new,
);
