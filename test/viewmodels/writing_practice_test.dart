import 'package:flutter_test/flutter_test.dart';
import 'package:malsseum_hanja/data/models/hanja_word.dart';
import 'package:malsseum_hanja/viewmodels/writing_practice_viewmodel.dart';

void main() {
  late WritingPracticeController c;
  setUp(
    () => c = WritingPracticeController(
      const HanjaWord(korean: '독생자', hanja: '獨生子', meaning: ''),
    ),
  );

  test('한 글자씩 연습하고, 글자를 옮기면 그린 획이 지워진다', () {
    expect((c.char, c.charCount, c.isFirst), ('獨', 3, true));

    c.startStroke(const Offset(0.1, 0.1));
    c.extendStroke(const Offset(0.5, 0.5));
    expect(c.strokes.single, hasLength(2));

    c.next();
    expect(c.char, '生');
    expect(c.strokes, isEmpty);

    c.next();
    c.next(); // 마지막 글자에서 더 가지 않는다
    expect((c.char, c.isLast), ('子', true));

    c.goTo(0);
    expect(c.char, '獨');
  });

  test('한 획 지우기, 모두 지우기, 본보기 켜고 끄기', () {
    c.startStroke(Offset.zero);
    c.startStroke(const Offset(1, 1));
    c.undo();
    expect(c.strokes, hasLength(1));
    c.clear();
    expect(c.strokes, isEmpty);

    expect(c.showGuide, isTrue);
    c.toggleGuide();
    expect(c.showGuide, isFalse);
  });
}
