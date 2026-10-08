import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/hanja_word.dart';
import '../models/saved_word.dart';

abstract class WordbookRepository {
  Stream<List<SavedWord>> watchWords();
  Future<bool> isSaved(String korean);
  Future<void> save(HanjaWord word, String verseRef);
  Future<void> remove(String korean);
  Future<void> recordQuizResult(String korean, {required bool correct});
}

/// Firestore: users/{uid}/wordbook/{korean}
class FirestoreWordbookRepository implements WordbookRepository {
  FirestoreWordbookRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('wordbook');

  @override
  Stream<List<SavedWord>> watchWords() => _col
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => SavedWord.fromJson(d.data())).toList());

  @override
  Future<bool> isSaved(String korean) async =>
      (await _col.doc(korean).get()).exists;

  @override
  Future<void> save(HanjaWord word, String verseRef) => _col
      .doc(word.korean)
      .set(
        SavedWord(
          word: word,
          verseRef: verseRef,
          savedAt: DateTime.now(),
        ).toJson(),
      );

  @override
  Future<void> remove(String korean) => _col.doc(korean).delete();

  @override
  Future<void> recordQuizResult(String korean, {required bool correct}) async {
    final doc = _col.doc(korean);
    if (!(await doc.get()).exists) return;
    await doc.update({
      correct ? 'correctCount' : 'wrongCount': FieldValue.increment(1),
    });
  }
}

/// Firebase 설정 전이나 테스트에서 쓰는 메모리 저장소.
class InMemoryWordbookRepository implements WordbookRepository {
  final Map<String, SavedWord> _words = {};
  final _controller = StreamController<List<SavedWord>>.broadcast();

  List<SavedWord> get _snapshot =>
      _words.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  void _emit() => _controller.add(_snapshot);

  @override
  Stream<List<SavedWord>> watchWords() async* {
    yield _snapshot;
    yield* _controller.stream;
  }

  @override
  Future<bool> isSaved(String korean) async => _words.containsKey(korean);

  @override
  Future<void> save(HanjaWord word, String verseRef) async {
    _words[word.korean] = SavedWord(
      word: word,
      verseRef: verseRef,
      savedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> remove(String korean) async {
    _words.remove(korean);
    _emit();
  }

  @override
  Future<void> recordQuizResult(String korean, {required bool correct}) async {
    final w = _words[korean];
    if (w == null) return;
    _words[korean] = correct
        ? w.copyWith(correctCount: w.correctCount + 1)
        : w.copyWith(wrongCount: w.wrongCount + 1);
    _emit();
  }
}
