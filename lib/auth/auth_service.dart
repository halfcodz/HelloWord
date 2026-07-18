import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/app_user.dart';

/// 이메일/비밀번호 기반 자체 로그인과 사용자 프로필(역할) 관리를 담당한다.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// `users/{uid}` 문서를 실시간으로 구독한다. 역할이 바뀌면 즉시 반영된다.
  Stream<AppUser?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return AppUser.fromMap(uid, data);
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _users.doc(cred.user!.uid).set({
      'email': email.trim(),
      'name': name.trim(),
      'role': role.storageValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    // 웹에서 자동 로그인 여부에 따라 지속성을 설정한다.
    // (모바일은 기본적으로 로그인이 유지되므로 설정 불필요)
    if (kIsWeb) {
      await _auth.setPersistence(
        rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    }
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// 역할 미지정 사용자를 위한 보정 저장(회원가입 시 지정하지만 예외 대비).
  Future<void> setRole({required String uid, required UserRole role}) async {
    await _users.doc(uid).set(
      {'role': role.storageValue},
      SetOptions(merge: true),
    );
  }

  /// 사용자 이름(별명)을 수정한다.
  Future<void> updateName({required String uid, required String name}) async {
    await _users.doc(uid).set(
      {'name': name.trim()},
      SetOptions(merge: true),
    );
  }

  /// 프로필 사진(base64 JPEG)을 저장한다.
  Future<void> updatePhoto({
    required String uid,
    required String base64,
  }) async {
    await _users.doc(uid).set(
      {'photo': base64},
      SetOptions(merge: true),
    );
  }

  Future<void> signOut() => _auth.signOut();
}

/// FirebaseAuthException 코드를 한국어 메시지로 변환한다.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return '이메일 형식이 올바르지 않습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 가입된 이메일입니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해 주세요.';
      default:
        return '오류가 발생했습니다. (${error.code})';
    }
  }
  return '알 수 없는 오류가 발생했습니다.';
}
