import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/shell_viewmodel.dart';

/// 하단 탭 바. [MainShell] 과, 그 위에 쌓인 화면(장 읽기 등)에서 함께 쓴다.
///
/// 쌓인 화면에서 탭을 누르면 첫 화면(MainShell)까지 돌아간 뒤 그 탭을 연다.
class AppNavigationBar extends ConsumerWidget {
  const AppNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.palette.border)),
      ),
      child: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(selectedTabProvider.notifier).select(AppTab.values[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '성경',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: '단어장',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: '퀴즈',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
