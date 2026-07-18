import 'package:cloud_firestore/cloud_firestore.dart';

/// 친구 초대. Firestore `friendInvites/{id}` 문서.
class FriendInvite {
  const FriendInvite({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    this.status = 'pending',
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String status;

  factory FriendInvite.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FriendInvite(
      id: doc.id,
      fromUid: d['fromUid'] as String? ?? '',
      fromName: d['fromName'] as String? ?? '',
      toUid: d['toUid'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
    );
  }
}
