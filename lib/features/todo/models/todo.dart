import 'package:cloud_firestore/cloud_firestore.dart';

/// 투두 항목. Firestore `users/{uid}/todos/{id}` 문서.
class Todo {
  const Todo({
    required this.id,
    required this.text,
    required this.date,
    this.done = false,
  });

  final String id;
  final String text;
  final DateTime date;
  final bool done;

  factory Todo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Todo(
      id: doc.id,
      text: d['text'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      done: d['done'] as bool? ?? false,
    );
  }
}
