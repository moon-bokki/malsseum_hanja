import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../viewmodels/quiz_viewmodel.dart';
import '../../viewmodels/word_detail_viewmodel.dart';
import '../widgets/ui.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final state = ref.watch(quizViewModelProvider);
    final vm = ref.read(quizViewModelProvider.notifier);
    final inProgress = state.status == QuizStatus.inProgress;

    final Widget body = switch (state.status) {
      QuizStatus.idle => _Message(
        hanja: '問',
        title: '한자 퀴즈',
        text: '한자를 보고 읽기를 고르는 5문제입니다.\n단어장에 4개 이상 저장하면 단어장에서 나옵니다.',
        button: '퀴즈 시작',
        onPressed: vm.start,
      ),
      QuizStatus.loading => const Center(child: CircularProgressIndicator()),
      QuizStatus.finished => _Message(
        hanja: '終',
        title: '${state.questions.length}문제 중 ${state.score}개 정답',
        text: '틀린 한자어는 단어장에 기록되었습니다.',
        button: '다시 풀기',
        onPressed: vm.start,
      ),
      QuizStatus.inProgress => _QuestionView(state: state, vm: vm),
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            ScreenHeader(
              title: '한자 퀴즈',
              trailing: inProgress
                  ? Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${state.index + 1}',
                            style: TextStyle(
                              color: p.accentStrong,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' / ${state.questions.length} · 정답 ${state.score}',
                          ),
                        ],
                      ),
                      style: AppText.ui(context, 14, color: p.muted),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            body,
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.hanja,
    required this.title,
    required this.text,
    required this.button,
    required this.onPressed,
  });

  final String hanja;
  final String title;
  final String text;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            children: [
              Text(hanja, style: AppText.hanja(context, 56)),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppText.ui(context, 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppText.ui(context, 14, color: p.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: onPressed, child: Text(button)),
      ],
    );
  }
}

class _QuestionView extends ConsumerWidget {
  const _QuestionView({required this.state, required this.vm});

  final QuizState state;
  final QuizViewModel vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final q = state.current!;
    final isLast = state.index + 1 >= state.questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (state.index + 1) / state.questions.length,
          ),
        ),
        const SizedBox(height: 18),
        SurfaceCard(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            children: [
              Text(
                '다음 한자어의 읽기는?',
                style: AppText.ui(context, 14, color: p.muted),
              ),
              const SizedBox(height: 8),
              FittedBox(
                child: Text(
                  q.answer.hanja,
                  style: AppText.hanja(context, 72).copyWith(letterSpacing: 4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 64,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (i, option) in q.options.indexed)
              _OptionButton(
                label: option,
                result: !state.answered
                    ? null
                    : i == q.answerIndex
                    ? true
                    : i == state.selected
                    ? false
                    : null,
                onPressed: state.answered ? null : () => vm.select(i),
              ),
          ],
        ),
        if (state.answered) ...[
          const SizedBox(height: 18),
          _Explanation(state: state),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: vm.next,
            child: Text(isLast ? '결과 보기' : '다음 문제'),
          ),
        ],
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.result,
    required this.onPressed,
  });

  final String label;

  /// true: 정답 표시, false: 고른 오답, null: 기본.
  final bool? result;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, border, fg, mark) = switch (result) {
      true => (p.correctTint, p.correct, p.correctText, '○ '),
      false => (p.wrongTint, p.wrong, p.wrongText, '× '),
      null => (p.surface, p.border, p.ink, ''),
    };
    return Semantics(
      label: switch (result) {
        true => '$label, 정답',
        false => '$label, 오답',
        null => null,
      },
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg,
          foregroundColor: fg,
          disabledForegroundColor: fg,
          side: BorderSide(color: border, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppText.ui(context, 20, weight: FontWeight.w700),
        ),
        child: Text('$mark$label'),
      ),
    );
  }
}

class _Explanation extends ConsumerWidget {
  const _Explanation({required this.state});

  final QuizState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final word = state.current!.answer;
    final correct = state.selected == state.current!.answerIndex;
    final chars = ref.watch(hanjaCharsProvider(word)).value ?? const [];
    final parts = [
      '${word.korean}(${word.hanja})',
      if (chars.isNotEmpty) chars.map((c) => c.hunEum).join(' + '),
      if (word.meaning.isNotEmpty) word.meaning,
    ];
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? '정답입니다!' : '아쉬워요. 정답은 ${word.korean}입니다.',
            style: AppText.ui(context, 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            parts.join(' · '),
            style: AppText.ui(context, 14, color: p.muted),
          ),
        ],
      ),
    );
  }
}
