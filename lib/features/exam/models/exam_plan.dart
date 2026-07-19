import 'package:cloud_firestore/cloud_firestore.dart';

/// 언니가 배정한 예정된 시험. Firestore `examPlans/{id}` 문서에 대응한다.
class ExamPlan {
  const ExamPlan({
    required this.id,
    required this.hostUid,
    required this.hostName,
    required this.guestUids,
    required this.wordSetId,
    required this.title,
    required this.wordCount,
    required this.scheduledDate,
    this.done = false,
    this.createdAt,
  });

  final String id;

  /// 출제자(언니).
  final String hostUid;
  final String hostName;

  /// 시험을 볼 동생들의 uid.
  final List<String> guestUids;

  final String wordSetId;
  final String title;
  final int wordCount;

  /// 시험 예정일.
  final DateTime scheduledDate;

  /// 시험을 완료했는지(결과가 기록되면 true로 표시).
  final bool done;

  final DateTime? createdAt;

  /// 예정일까지 남은 일수. 오늘이면 0, 지났으면 음수.
  int dDay(DateTime today) {
    final d0 = DateTime(today.year, today.month, today.day);
    final d1 = DateTime(
        scheduledDate.year, scheduledDate.month, scheduledDate.day);
    return d1.difference(d0).inDays;
  }

  Map<String, dynamic> toMap() => {
        'hostUid': hostUid,
        'hostName': hostName,
        'guestUids': guestUids,
        'wordSetId': wordSetId,
        'title': title,
        'wordCount': wordCount,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'done': done,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ExamPlan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ExamPlan(
      id: doc.id,
      hostUid: d['hostUid'] as String? ?? '',
      hostName: d['hostName'] as String? ?? '',
      guestUids: (d['guestUids'] as List?)?.cast<String>() ?? const [],
      wordSetId: d['wordSetId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      wordCount: d['wordCount'] as int? ?? 0,
      scheduledDate:
          (d['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      done: d['done'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
