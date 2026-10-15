import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/shell_viewmodel.dart';
import '../splash/splash_screen.dart';

/// 모든 탭 위에 고정되는 머리글: 낙관 + 말씀한자 로고, 알림 설정 버튼.
///
/// [MainShell] 의 Scaffold.appBar 로 쓰여서 탭을 바꾸거나 화면을 스크롤해도 그대로 있다.
/// 로고를 누르면 스플래시 화면을 3초 보여 준 뒤 오늘(오늘의 말씀) 탭으로 간다.
class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  static const height = 64.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    // 로고(assets/images/logo02.png)는 글자색이 검정이라, 다크 테마에서는 밝은 바탕에 얹는다.
    final dark = Theme.of(context).brightness == Brightness.dark;
    // 너비를 원본 비율(777×253)로 고정해, 이미지를 불러오기 전에도 자리(누를 영역)가 있게 한다.
    final logo = Image.asset(
      'assets/images/logo02.png',
      height: 44,
      width: 44 * 777 / 253,
      fit: BoxFit.contain,
      semanticLabel: '말씀한자',
    );
    final logoButton = Semantics(
      button: true,
      label: '말씀한자 처음 화면으로',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // 스플래시 뒤에서 미리 오늘 탭으로 바꿔 두어, 스플래시가 걷히면 바로 보이게 한다.
          ref.read(selectedTabProvider.notifier).select(AppTab.today);
          replaySplash(context);
        },
        child: dark
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F5FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(padding: const EdgeInsets.all(3), child: logo),
              )
            : logo,
      ),
    );
    return Material(
      color: p.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              logoButton,
              const Spacer(),
              IconButton(
                tooltip: '알림 설정',
                style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
                icon: Icon(Icons.notifications_none, color: p.muted),
                onPressed: () =>
                    ref.read(selectedTabProvider.notifier).select(AppTab.my),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
