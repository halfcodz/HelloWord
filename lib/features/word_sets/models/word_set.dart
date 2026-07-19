import 'package:cloud_firestore/cloud_firestore.dart';

import 'word_pair.dart';

/// 언니가 등록한 단어 세트. Firestore `wordSets/{id}` 문서에 대응한다.
class WordSet {
  const WordSet({
    required this.id,
    required this.title,
    required this.date,
    required this.message,
    required this.words,
    required this.createdBy,
    this.sharedWith = const [],
    this.createdAt,
  });

  final String id;

  /// 세트 제목.
  final String title;

  /// 시험 날짜 (사용자가 지정, 기본값 오늘).
  final DateTime date;

  /// 언니의 한마디.
  final String message;

  final List<WordPair> words;

  /// 만든 사람(언니)의 uid.
  final String createdBy;

  /// 이 세트를 공부할 수 있는 친구(동생)들의 uid.
  final List<String> sharedWith;

  /// 서버 저장 시각.
  final DateTime? createdAt;

  int get wordCount => words.length;

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': Timestamp.fromDate(date),
        'message': message,
        'words': words.map((w) => w.toMap()).toList(),
        'wordCount': words.length,
        'createdBy': createdBy,
        'sharedWith': sharedWith,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory WordSet.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawWords = (data['words'] as List<dynamic>? ?? []);
    return WordSet(
      id: doc.id,
      title: data['title'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      message: data['message'] as String? ?? '',
      words: rawWords
          .map((e) => WordPair.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdBy: data['createdBy'] as String? ?? '',
      sharedWith:
          (data['sharedWith'] as List?)?.cast<String>() ?? const [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
