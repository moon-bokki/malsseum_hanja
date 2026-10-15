import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 앱을 시작할 때 [initialize](글꼴·Firebase 준비)가 끝날 때까지 스플래시 화면을 보여 주고,
/// 끝나면 [child](앱)로 넘어간다. 실패하면 오류와 '다시 시도' 버튼을 보여 준다.
///
/// 웹에서는 web/index.html 의 시작 화면이 같은 모양이라, 엔진이 뜬 뒤에도 끊김 없이 이어진다.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.initialize,
    required this.child,
    this.minimumDuration = const Duration(milliseconds: 800),
  });

  final Future<void> Function() initialize;
  final Widget child;

  /// 준비가 아주 빨리 끝나도 로고가 깜빡이고 사라지지 않게 보여 주는 최소 시간.
  final Duration minimumDuration;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  late Future<void> _ready = _start();

  Future<void> _start() => Future.wait([
    widget.initialize(),
    Future.delayed(widget.minimumDuration),
  ]);

  void _retry() {
    final ready = _start();
    setState(() {
      _ready = ready;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          final done = snapshot.connectionState == ConnectionState.done;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: done && !snapshot.hasError
                ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
                : MaterialApp(
                    key: const ValueKey('splash'),
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light(),
                    home: SplashScreen(
                      error: done ? snapshot.error : null,
                      onRetry: _retry,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// 로고(assets/images/logo02.png)와 로딩 막대. [error] 가 있으면 다시 시도 버튼을 보여 준다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = math.min(MediaQuery.sizeOf(context).width * 0.72, 320.0);
    return Scaffold(
      // 로고 글자가 검정이라 다크 테마에서도 밝은 바탕을 쓴다 (web/index.html 과 같은 색).
      backgroundColor: const Color(0xFFF6F5FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo02.png',
                width: width,
                semanticLabel: '말씀한자',
              ),
              const SizedBox(height: 28),
              if (error == null)
                Semantics(
                  label: '불러오는 중',
                  child: SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: p.gold,
                        backgroundColor: p.accentTint,
                      ),
                    ),
                  ),
                )
              else ...[
                Text(
                  '앱을 시작하지 못했습니다.\n인터넷 연결을 확인한 뒤 다시 시도해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.6, color: p.muted),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 스플래시 화면을 [duration] 동안 보여 주었다가 닫는다 (머리글 로고를 누를 때).
Future<void> replaySplash(
  BuildContext context, {
  Duration duration = const Duration(seconds: 3),
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => _TimedSplash(duration: duration),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _TimedSplash extends StatefulWidget {
  const _TimedSplash({required this.duration});

  final Duration duration;

  @override
  State<_TimedSplash> createState() => _TimedSplashState();
}

class _TimedSplashState extends State<_TimedSplash> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
