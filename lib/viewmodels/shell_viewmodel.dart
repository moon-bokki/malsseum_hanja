import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 하단 탭.
enum AppTab { today, bible, wordbook, quiz, my }

class SelectedTabViewModel extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.today;

  void select(AppTab tab) => state = tab;
}

final selectedTabProvider = NotifierProvider<SelectedTabViewModel, AppTab>(
  SelectedTabViewModel.new,
);
