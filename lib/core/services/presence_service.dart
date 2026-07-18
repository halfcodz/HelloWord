import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

/// 사용자의 접속 상태(online)를 Firestore에 실시간 반영한다.
/// 앱 생명주기(포그라운드/백그라운드)와 주기적 하트비트로 갱신한다.
class PresenceService with WidgetsBindingObserver {
  PresenceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  Timer? _heartbeat;
  String? _uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('users').doc(_uid);

  void start(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 45), (_) {
      _setOnline(true);
    });
  }

  Future<void> _setOnline(bool value) async {
    if (_uid == null) return;
    try {
      await _doc.set(
        {'online': value, 'lastActive': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {
      // 네트워크 오류는 무시.
    }
  }

  /// 시험(공부) 중 여부를 표시한다.
  Future<void> setStudying(bool value) async {
    if (_uid == null) return;
    try {
      await _doc.set({'studying': value}, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _setOnline(false);
        break;
    }
  }

  void dispose() {
    _heartbeat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
  }
}
