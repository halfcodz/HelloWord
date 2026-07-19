import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/app_user.dart';
import '../models/friend_invite.dart';

enum FriendAddResult { success, notFound, self, alreadyFriend, alreadyPending, error }

/// 친구 초대(승인/거절) 및 친구 상태 실시간 구독을 담당한다.
class FriendRepository {
  FriendRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('friendInvites');

  /// 이메일로 상대를 찾아 초대를 보낸다(상대가 승인하면 친구가 된다).
  Future<FriendAddResult> sendInvite({
    required String myUid,
    required String myName,
    required String email,
  }) async {
    try {
      final query =
          await _users.where('email', isEqualTo: email.trim()).limit(1).get();
      if (query.docs.isEmpty) return FriendAddResult.notFound;

      final target = query.docs.first;
      if (target.id == myUid) return FriendAddResult.self;

      final myFriends =
          ((await _users.doc(myUid).get()).data()?['friends'] as List?)
                  ?.cast<String>() ??
              const [];
      if (myFriends.contains(target.id)) return FriendAddResult.alreadyFriend;

      // 내가 그 상대에게 보낸 대기 중 초대가 이미 있는지 확인(단일 equality).
      final mine = await _invites.where('fromUid', isEqualTo: myUid).get();
      final already = mine.docs.any((d) =>
          d.data()['toUid'] == target.id && d.data()['status'] == 'pending');
      if (already) return FriendAddResult.alreadyPending;

      await _invites.add({
        'fromUid': myUid,
        'fromName': myName,
        'toUid': target.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return FriendAddResult.success;
    } catch (e) {
      // 대부분 Firestore 규칙(friendInvites 권한) 문제. 콘솔에 원인을 남긴다.
      debugPrint('sendInvite 오류: $e');
      return FriendAddResult.error;
    }
  }

  /// 내가 받은 대기 중 초대를 실시간 구독한다.
  Stream<List<FriendInvite>> watchIncomingInvites(String uid) {
    return _invites.where('toUid', isEqualTo: uid).snapshots().map((snap) => snap
        .docs
        .map(FriendInvite.fromDoc)
        .where((i) => i.status == 'pending')
        .toList());
  }

  /// 초대를 승인해 서로 친구가 된다.
  Future<void> acceptInvite(FriendInvite invite) async {
    await _users.doc(invite.toUid).set(
      {'friends': FieldValue.arrayUnion([invite.fromUid])},
      SetOptions(merge: true),
    );
    await _users.doc(invite.fromUid).set(
      {'friends': FieldValue.arrayUnion([invite.toUid])},
      SetOptions(merge: true),
    );
    await _invites.doc(invite.id).delete();
  }

  /// 초대를 거절한다.
  Future<void> rejectInvite(String inviteId) async {
    await _invites.doc(inviteId).delete();
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
