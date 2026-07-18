import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/todo.dart';

/// 개인 투두를 담당한다. Firestore `users/{uid}/todos`.
class TodoRepository {
  TodoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _todos(String uid) =>
      _firestore.collection('users').doc(uid).collection('todos');

  /// 특정 월의 투두를 실시간 구독한다. (단일 필드 range → 복합 색인 불필요)
  Stream<List<Todo>> watchMonth(String uid, DateTime month) {
    final start = Timestamp.fromDate(DateTime(month.year, month.month, 1));
    final end = Timestamp.fromDate(DateTime(month.year, month.month + 1, 1));
    return _todos(uid)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .snapshots()
        .map((snap) => snap.docs.map(Todo.fromDoc).toList());
  }

  Future<void> add({
    required String uid,
    required String text,
    required DateTime date,
  }) async {
    await _todos(uid).add({
      'text': text.trim(),
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'done': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDone({
    required String uid,
    required String id,
    required bool done,
  }) async {
    await _todos(uid).doc(id).update({'done': done});
  }

  Future<void> delete({required String uid, required String id}) async {
    await _todos(uid).doc(id).delete();
  }
}
