import 'package:cloud_firestore/cloud_firestore.dart';

/// 시험 중 한 문제에 대한 동생의 답안.
/// Firestore `sessions/{sessionId}/answers/{index}` 문서에 대응한다.
class ExamAnswer {
  const ExamAnswer({
    required this.index,
    this.typed = '',
    this.submitted,
    this.correct,
  });

  final int index;

  /// 실시간으로 입력 중인 텍스트(디바운스 저장). 언니가 이걸 실시간으로 본다.
  final String typed;

  /// 제출된 답. null이면 아직 제출 전.
  final String? submitted;

  /// 채점 결과. 미제출이면 null.
  final bool? correct;

  bool get isSubmitted => submitted != null;

  factory ExamAnswer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ExamAnswer(
      index: d['index'] as int? ?? int.tryParse(doc.id) ?? 0,
      typed: d['typed'] as String? ?? '',
      submitted: d['submitted'] as String?,
      correct: d['correct'] as bool?,
    );
  }
}
