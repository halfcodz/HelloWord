import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

/// 두 사람 사이의 1:1 채팅을 담당한다.
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  /// 두 uid로 항상 같은 방 id를 만든다(정렬 후 결합).
  String roomIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  Stream<List<ChatMessage>> watchMessages(String roomId) => _chats
      .doc(roomId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());

  Future<void> send({
    required String roomId,
    required List<String> participants,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final room = _chats.doc(roomId);
    await room.set({
      'participants': participants,
      'lastMessage': trimmed,
      'lastSenderId': senderId,
      'lastAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await room.collection('messages').add({
      'senderId': senderId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 채팅방을 열었을 때 읽음 시각을 기록한다.
  Future<void> markRead({required String roomId, required String uid}) async {
    await _chats.doc(roomId).set(
      {'read_$uid': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// 안 읽은 메시지가 하나라도 있는지 실시간 구독(채팅 탭 배지용).
  Stream<bool> watchHasUnread(String uid) {
    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final d = doc.data();
        final lastAt = d['lastAt'] as Timestamp?;
        final lastSender = d['lastSenderId'] as String?;
        final read = d['read_$uid'] as Timestamp?;
        if (lastAt == null || lastSender == uid) continue;
        if (read == null || lastAt.compareTo(read) > 0) return true;
      }
      return false;
    });
  }
}
