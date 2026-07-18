import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/word_pair.dart';
import '../models/word_set.dart';

/// Firestore `wordSets` 컬렉션에 대한 데이터 접근 계층.
class WordSetRepository {
  WordSetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('wordSets');

  /// 특정 언니가 만든 단어 세트를 최신순으로 실시간 구독한다.
  ///
  /// 정렬은 클라이언트에서 처리해 Firestore 복합 색인이 필요 없도록 한다.
  Stream<List<WordSet>> watchByCreator(String uid) {
    return _collection
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(WordSet.fromDoc).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// 여러 작성자(친구=언니)의 단어 세트를 최신순으로 구독한다.
  /// 동생이 언니가 올린 단어를 혼자 공부할 때 쓴다.
  Stream<List<WordSet>> watchByCreators(List<String> uids) {
    if (uids.isEmpty) return Stream.value(const []);
    return _collection
        .where('createdBy', whereIn: uids.take(10).toList())
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(WordSet.fromDoc).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// 새 단어 세트를 저장하고 생성된 문서 id를 반환한다.
  Future<String> create({
    required String title,
    required DateTime date,
    required String message,
    required List<WordPair> words,
    required String createdBy,
  }) async {
    final draft = WordSet(
      id: '',
      title: title,
      date: date,
      message: message,
      words: words,
      createdBy: createdBy,
    );
    final ref = await _collection.add(draft.toMap());
    return ref.id;
  }

  Future<void> delete(String id) => _collection.doc(id).delete();
}
