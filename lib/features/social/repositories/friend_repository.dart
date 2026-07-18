import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/app_user.dart';

enum FriendAddResult { success, notFound, self, alreadyFriend, error }

/// 친구 연결(이메일로 추가) 및 친구 상태 실시간 구독을 담당한다.
class FriendRepository {
  FriendRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// 이메일로 상대를 찾아 서로의 친구 목록에 추가한다.
  Future<FriendAddResult> addByEmail({
    required String myUid,
    required String email,
  }) async {
    try {
      final query =
          await _users.where('email', isEqualTo: email.trim()).limit(1).get();
      if (query.docs.isEmpty) return FriendAddResult.notFound;

      final friendDoc = query.docs.first;
      if (friendDoc.id == myUid) return FriendAddResult.self;

      final myFriends =
          ((await _users.doc(myUid).get()).data()?['friends'] as List?)
                  ?.cast<String>() ??
              const [];
      if (myFriends.contains(friendDoc.id)) {
        return FriendAddResult.alreadyFriend;
      }

      await _users.doc(myUid).set(
        {'friends': FieldValue.arrayUnion([friendDoc.id])},
        SetOptions(merge: true),
      );
      await _users.doc(friendDoc.id).set(
        {'friends': FieldValue.arrayUnion([myUid])},
        SetOptions(merge: true),
      );
      return FriendAddResult.success;
    } catch (_) {
      return FriendAddResult.error;
    }
  }

  /// 내 친구들의 상태(접속·공부중)를 실시간으로 구독한다.
  Stream<List<AppUser>> watchFriends(String myUid) {
    return _users.doc(myUid).snapshots().asyncExpand((myDoc) {
      final friends =
          (myDoc.data()?['friends'] as List?)?.cast<String>() ?? const [];
      if (friends.isEmpty) return Stream.value(<AppUser>[]);
      return _users
          .where(FieldPath.documentId, whereIn: friends.take(10).toList())
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
    });
  }
}
