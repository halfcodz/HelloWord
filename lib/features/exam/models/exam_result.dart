import 'package:cloud_firestore/cloud_firestore.dart';

/// 채점된 문항 하나.
class ExamResultItem {
  const ExamResultItem({
    required this.index,
    required this.english,
    required this.korean,
    required this.submitted,
    required this.correct,
  });

  final int index;
  final String english;
  final String korean;
  final String submitted;
  final bool correct;

  Map<String, dynamic> toMap() => {
        'index': index,
        'en': english,
        'ko': korean,
        'submitted': submitted,
        'correct': correct,
      };

  factory ExamResultItem.fromMap(Map<String, dynamic> m) => ExamResultItem(
        index: m['index'] as int? ?? 0,
        english: m['en'] as String? ?? '',
        korean: m['ko'] as String? ?? '',
        submitted: m['submitted'] as String? ?? '',
        correct: m['correct'] as bool? ?? false,
      );
}

/// 완료된 시험의 채점 결과. Firestore `examResults/{id}` 문서에 대응한다.
/// 실시간 세션이 삭제돼도 결과는 남아 언니가 나중에 확인할 수 있다.
class ExamResult {
  const ExamResult({
    required this.id,
    required this.hostUid,
    required this.guestUid,
    required this.guestName,
    required this.wordSetId,
    required this.title,
    required this.total,
    required this.score,
    required this.items,
    this.createdAt,
  });

  final String id;
  final String hostUid;
  final String guestUid;
  final String guestName;
  final String wordSetId;
  final String title;
  final int total;
  final int score;
  final List<ExamResultItem> items;
  final DateTime? createdAt;

  /// 정답률(%). 문항이 없으면 0.
  int get percent => total == 0 ? 0 : ((score / total) * 100).round();

  Map<String, dynamic> toMap() => {
        'hostUid': hostUid,
        'guestUid': guestUid,
        'guestName': guestName,
        'wordSetId': wordSetId,
        'title': title,
        'total': total,
        'score': score,
        'items': items.map((e) => e.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ExamResult.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawItems = d['items'] as List<dynamic>? ?? [];
    return ExamResult(
      id: doc.id,
      hostUid: d['hostUid'] as String? ?? '',
      guestUid: d['guestUid'] as String? ?? '',
      guestName: d['guestName'] as String? ?? '',
      wordSetId: d['wordSetId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      total: d['total'] as int? ?? 0,
      score: d['score'] as int? ?? 0,
      items: rawItems
          .map((e) => ExamResultItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
