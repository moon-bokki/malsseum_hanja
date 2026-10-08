import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../data/models/hanja_word.dart';

/// 한자 쓰기 연습 상태: 지금 쓰는 글자와 손으로 그린 획.
///
/// 한자어를 한 글자씩 연습한다 (恩惠 → 恩, 惠).
/// 획은 0~1 로 맞춘 좌표로 저장해서, 칸 크기가 바뀌어도 그대로 그린다.
class WritingPracticeController extends ChangeNotifier {
  WritingPracticeController(this.word);

  final HanjaWord word;

  int _index = 0;
  final List<List<Offset>> _strokes = [];
  bool _showGuide = true;

  /// 지금 쓰는 글자 순번 (0부터).
  int get index => _index;
  String get char => word.chars[_index];
  int get charCount => word.chars.length;
  bool get isFirst => _index == 0;
  bool get isLast => _index == charCount - 1;

  /// 그린 획 (각 획은 0~1 좌표의 점 목록).
  List<List<Offset>> get strokes => List.unmodifiable(_strokes);

  /// 칸에 흐리게 보이는 본보기 글자 (따라 쓰기).
  bool get showGuide => _showGuide;

  void startStroke(Offset point) {
    _strokes.add([point]);
    notifyListeners();
  }

  void extendStroke(Offset point) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(point);
    notifyListeners();
  }

  /// 마지막 획 지우기.
  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  void clear() {
    if (_strokes.isEmpty) return;
    _strokes.clear();
    notifyListeners();
  }

  void toggleGuide() {
    _showGuide = !_showGuide;
    notifyListeners();
  }

  /// 다른 글자로 옮기면 그린 획은 지운다.
  void goTo(int index) {
    if (index < 0 || index >= charCount || index == _index) return;
    _index = index;
    _strokes.clear();
    notifyListeners();
  }

  void next() => goTo(_index + 1);

  void previous() => goTo(_index - 1);
}
