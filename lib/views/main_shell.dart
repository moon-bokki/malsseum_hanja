import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/shell_viewmodel.dart';
import 'home/home_screen.dart';
import 'mypage/mypage_screen.dart';
import 'quiz/quiz_screen.dart';
import 'reader/reader_screen.dart';
import 'widgets/app_header.dart';
import 'widgets/app_navigation_bar.dart';
import 'wordbook/wordbook_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    ReaderScreen(),
    WordbookScreen(),
    QuizScreen(),
    MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    return Scaffold(
      // 로고 머리글은 모든 탭 위에 고정된다.
      appBar: const AppHeader(),
      body: IndexedStack(index: tab.index, children: _screens),
      bottomNavigationBar: const AppNavigationBar(),
    );
  }
}
