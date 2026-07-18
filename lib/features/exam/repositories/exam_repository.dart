import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../word_sets/models/word_set.dart';
import '../models/exam_answer.dart';
import '../models/exam_session.dart';

/// 실시간 시험 세션에 대한 Firestore 데이터 접근 계층.
class ExamRepository {
  ExamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('sessions');

  CollectionReference<Map<String, dynamic>> _answers(String sessionId) =>
      _sessions.doc(sessionId).collection('answers');

  String _generateJoinCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  /// 언니가 단어 세트로 새 시험 세션을 만든다.
  Future<ExamSession> createSession({
    required WordSet wordSet,
    required String hostUid,
    required String hostName,
  }) async {
    final ref = _sessions.doc();
    final session = ExamSession(
      id: ref.id,
      joinCode: _generateJoinCode(),
      wordSetId: wordSet.id,
      title: wordSet.title,
      words: wordSet.words,
      hostUid: hostUid,
      hostName: hostName,
      status: SessionStatus.waiting,
      currentIndex: 0,
    );
    await ref.set(session.toMap());
    return session;
  }

  Stream<ExamSession?> watchSession(String sessionId) => _sessions
      .doc(sessionId)
      .snapshots()
      .map((doc) => doc.exists ? ExamSession.fromDoc(doc) : null);

  Stream<List<ExamAnswer>> watchAnswers(String sessionId) =>
      _answers(sessionId).snapshots().map((snap) {
        final list = snap.docs.map(ExamAnswer.fromDoc).toList();
        list.sort((a, b) => a.index.compareTo(b.index));
        return list;
      });

  /// 코드로 대기 중인 세션을 찾는다. (단일 equality 쿼리 → 복합 색인 불필요)
  Future<ExamSession?> findByJoinCode(String code) async {
    final query =
        await _sessions.where('joinCode', isEqualTo: code).limit(5).get();
    for (final doc in query.docs) {
      final session = ExamSession.fromDoc(doc);
      if (session.status == SessionStatus.waiting) return session;
    }
    return null;
  }

  /// 동생이 세션에 참여한다.
  Future<void> joinSession({
    required String sessionId,
    required String guestUid,
    required String guestName,
  }) async {
    await _sessions.doc(sessionId).update({
      'guestUid': guestUid,
      'guestName': guestName,
      'status': SessionStatus.active.name,
    });
  }

  /// 실시간 입력 중인 텍스트를 저장한다(디바운스는 ViewModel에서).
  Future<void> updateTyping({
    required String sessionId,
    required int index,
    required String typed,
  }) async {
    await _answers(sessionId).doc('$index').set(
      {'index': index, 'typed': typed},
      SetOptions(merge: true),
    );
  }

  /// 답을 제출하고 채점 결과를 저장한다.
  Future<void> submitAnswer({
    required String sessionId,
    required int index,
    required String submitted,
    required bool correct,
  }) async {
    await _answers(sessionId).doc('$index').set(
      {
        'index': index,
        'typed': submitted,
        'submitted': submitted,
        'correct': correct,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setCurrentIndex({
    required String sessionId,
    required int index,
  }) async {
    await _sessions.doc(sessionId).update({'currentIndex': index});
  }

  Future<void> finish({
    required String sessionId,
    required int score,
  }) async {
    await _sessions.doc(sessionId).update({
      'status': SessionStatus.finished.name,
      'score': score,
      'finishedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 동생이 시험(공부) 중인지 상태를 표시한다. 친구 프로필의 불꽃 표시에 쓰인다.
  Future<void> setStudying({
    required String uid,
    required bool studying,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {'studying': studying},
      SetOptions(merge: true),
    );
  }

  /// 세션과 하위 답안을 삭제한다(언니가 취소할 때).
  Future<void> deleteSession(String sessionId) async {
    final answers = await _answers(sessionId).get();
    for (final doc in answers.docs) {
      await doc.reference.delete();
    }
    await _sessions.doc(sessionId).delete();
  }
}
