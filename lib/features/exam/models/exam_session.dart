import 'package:cloud_firestore/cloud_firestore.dart';

import '../../word_sets/models/word_pair.dart';

enum SessionStatus { waiting, active, finished }

SessionStatus _statusFrom(String? value) {
  switch (value) {
    case 'active':
      return SessionStatus.active;
    case 'finished':
      return SessionStatus.finished;
    default:
      return SessionStatus.waiting;
  }
}

/// 실시간 시험 세션. Firestore `sessions/{sessionId}` 문서에 대응한다.
///
/// 시험에 쓰이는 단어 목록을 세션에 복사(임베드)해 자체 완결적으로 만든다.
class ExamSession {
  const ExamSession({
    required this.id,
    required this.joinCode,
    required this.wordSetId,
    required this.title,
    required this.words,
    required this.hostUid,
    required this.hostName,
    required this.status,
    required this.currentIndex,
    this.guestUid,
    this.guestName,
    this.score,
    this.createdAt,
  });

  final String id;

  /// 동생이 입력해 참여하는 6자리 코드.
  final String joinCode;

  final String wordSetId;
  final String title;
  final List<WordPair> words;

  /// 출제자(언니).
  final String hostUid;
  final String hostName;

  final SessionStatus status;

  /// 동생이 현재 풀고 있는 문제 번호.
  final int currentIndex;

  /// 응시자(동생). 참여 전에는 null.
  final String? guestUid;
  final String? guestName;

  /// 완료 시 최종 점수(맞은 개수).
  final int? score;

  final DateTime? createdAt;

  int get total => words.length;
  bool get hasGuest => guestUid != null;

  Map<String, dynamic> toMap() => {
        'joinCode': joinCode,
        'wordSetId': wordSetId,
        'title': title,
        'words': words.map((w) => w.toMap()).toList(),
        'hostUid': hostUid,
        'hostName': hostName,
        'status': status.name,
        'currentIndex': currentIndex,
        'guestUid': guestUid,
        'guestName': guestName,
        'score': score,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ExamSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawWords = d['words'] as List<dynamic>? ?? [];
    return ExamSession(
      id: doc.id,
      joinCode: d['joinCode'] as String? ?? '',
      wordSetId: d['wordSetId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      words: rawWords
          .map((e) => WordPair.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      hostUid: d['hostUid'] as String? ?? '',
      hostName: d['hostName'] as String? ?? '',
      status: _statusFrom(d['status'] as String?),
      currentIndex: d['currentIndex'] as int? ?? 0,
      guestUid: d['guestUid'] as String?,
      guestName: d['guestName'] as String?,
      score: d['score'] as int?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
