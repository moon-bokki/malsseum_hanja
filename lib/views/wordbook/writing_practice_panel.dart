import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/hanja_word.dart';
import '../../viewmodels/word_detail_viewmodel.dart';
import '../../viewmodels/writing_practice_viewmodel.dart';
import '../word_detail/word_detail_sheet.dart';

/// 화면 오른쪽에서 밀려 나오는 쓰기 연습 패널을 연다.
Future<void> showWritingPractice(
  BuildContext context, {
  required HanjaWord word,
  required String verseRef,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '닫기',
    barrierColor: const Color(0x7A1F1B2D),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => Align(
      alignment: Alignment.centerRight,
      child: WritingPracticePanel(word: word, verseRef: verseRef),
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class WritingPracticePanel extends ConsumerStatefulWidget {
  const WritingPracticePanel({
    super.key,
    required this.word,
    required this.verseRef,
  });

  final HanjaWord word;
  final String verseRef;

  @override
  ConsumerState<WritingPracticePanel> createState() =>
      _WritingPracticePanelState();
}

class _WritingPracticePanelState extends ConsumerState<WritingPracticePanel> {
  late final _controller = WritingPracticeController(widget.word);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final word = widget.word;
    final chars = ref.watch(hanjaCharsProvider(word)).value ?? const [];
    final width = math.min(MediaQuery.sizeOf(context).width * 0.92, 420.0);

    return Material(
      color: p.surface,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: SafeArea(
          left: false,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final c = _controller;
              final info = c.index < chars.length ? chars[c.index] : null;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('쓰기 연습', style: AppText.title(context)),
                        ),
                        IconButton(
                          tooltip: '닫기',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(word.hanja, style: AppText.hanja(context, 28)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            word.korean,
                            style: AppText.ui(
                              context,
                              17,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => showWordDetailSheet(
                            context,
                            word: word,
                            verseRef: widget.verseRef,
                          ),
                          child: const Text('뜻 보기'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 글자 고르기 (恩惠 → [恩] [惠])
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final (i, ch) in word.chars.indexed)
                          ChoiceChip(
                            label: Text(
                              ch,
                              style: AppText.hanja(context, 16).copyWith(
                                color: i == c.index
                                    ? p.onAccent
                                    : p.accentStrong,
                              ),
                            ),
                            selected: i == c.index,
                            onSelected: (_) => c.goTo(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${c.char}  ',
                            style: AppText.hanja(context, 20),
                          ),
                          TextSpan(
                            text: info == null ? '' : info.hunEum,
                            style: AppText.ui(
                              context,
                              16,
                              weight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '   ${c.index + 1} / ${c.charCount}',
                            style: AppText.ui(context, 13, color: p.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _WritingPad(controller: c),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ToolButton(
                          icon: Icons.undo,
                          label: '한 획 지우기',
                          onPressed: c.strokes.isEmpty ? null : c.undo,
                        ),
                        _ToolButton(
                          icon: Icons.delete_outline,
                          label: '모두 지우기',
                          onPressed: c.strokes.isEmpty ? null : c.clear,
                        ),
                        _ToolButton(
                          icon: c.showGuide
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                          label: c.showGuide ? '본보기 끄기' : '본보기 켜기',
                          onPressed: c.toggleGuide,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: c.isFirst ? null : c.previous,
                            child: const Text('이전 글자'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: c.isLast
                                ? () => Navigator.of(context).pop()
                                : c.next,
                            child: Text(c.isLast ? '마치기' : '다음 글자'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = onPressed == null ? p.outline : p.accentStrong;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 2),
              Text(label, style: AppText.ui(context, 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 따라 쓰는 칸: 십자 안내선 + 흐린 본보기 글자 + 손으로 그린 획.
class _WritingPad extends StatelessWidget {
  const _WritingPad({required this.controller});

  final WritingPracticeController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, box) {
        final side = box.maxWidth;
        Offset norm(Offset local) => Offset(
          (local.dx / side).clamp(0.0, 1.0),
          (local.dy / side).clamp(0.0, 1.0),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: p.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border, width: 1.5),
          ),
          child: GestureDetector(
            key: const ValueKey('writing-pad'),
            onPanStart: (d) => controller.startStroke(norm(d.localPosition)),
            onPanUpdate: (d) => controller.extendStroke(norm(d.localPosition)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _GridPainter(p.outline)),
                if (controller.showGuide)
                  Center(
                    child: Text(
                      controller.char,
                      style: AppText.hanja(context, side * 0.72).copyWith(
                        color: p.ink.withValues(alpha: 0.12),
                        height: 1,
                      ),
                    ),
                  ),
                CustomPaint(
                  painter: _StrokePainter(
                    controller.strokes,
                    p.accentStrong,
                    width: side * 0.035,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 가운데 십자 점선 (田 자 칸).
class _GridPainter extends CustomPainter {
  _GridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    const dash = 6.0;
    for (var t = 0.0; t < size.width; t += dash * 2) {
      final y = size.height / 2;
      canvas.drawLine(Offset(t, y), Offset(t + dash, y), paint);
    }
    for (var t = 0.0; t < size.height; t += dash * 2) {
      final x = size.width / 2;
      canvas.drawLine(Offset(x, t), Offset(x, t + dash), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes, this.color, {required this.width});

  final List<List<Offset>> strokes;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      final points = [
        for (final o in stroke) Offset(o.dx * size.width, o.dy * size.height),
      ];
      if (points.length == 1) {
        canvas.drawCircle(
          points.first,
          width / 2,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final pt in points.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  // 컨트롤러가 같은 목록을 고쳐 쓰므로 항상 다시 그린다.
  @override
  bool shouldRepaint(_StrokePainter old) => true;
}
