import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// 이 기기에서 한 번이라도 로그인한 계정.
///
/// 로그인 화면에 얼굴로 보여 주려고 이름·사진·역할까지 같이 들고 있다.
/// 비밀번호는 여기 들어 있지 않다([SavedAccounts] 참고).
class SavedAccount {
  const SavedAccount({
    required this.uid,
    required this.email,
    required this.name,
    this.roleName,
    this.photoBase64,
    this.savedAt = 0,
  });

  final String uid;
  final String email;
  final String name;

  /// 'elder' | 'younger'. 마스코트(🐰/🐥)를 고르는 데 쓴다.
  final String? roleName;

  /// 프로필 사진(base64 JPEG). 없으면 마스코트를 보여 준다.
  final String? photoBase64;

  /// 마지막으로 로그인한 시각(epoch ms). 최근 계정이 위로 오게 정렬한다.
  final int savedAt;

  UserRole? get role => UserRoleX.fromStorage(roleName);

  SavedAccount copyWith({
    String? email,
    String? name,
    String? roleName,
    String? photoBase64,
    int? savedAt,
  }) {
    return SavedAccount(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      roleName: roleName ?? this.roleName,
      photoBase64: photoBase64 ?? this.photoBase64,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        if (roleName != null) 'role': roleName,
        if (photoBase64 != null) 'photo': photoBase64,
        'savedAt': savedAt,
      };

  static SavedAccount? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final uid = raw['uid'];
    if (uid is! String || uid.isEmpty) return null;
    final photo = raw['photo'];
    return SavedAccount(
      uid: uid,
      email: raw['email'] as String? ?? '',
      name: raw['name'] as String? ?? '',
      roleName: raw['role'] as String?,
      photoBase64: (photo is String && photo.isNotEmpty) ? photo : null,
      savedAt: raw['savedAt'] as int? ?? 0,
    );
  }
}

/// 로그인 화면의 프로필 목록을 이 기기에 저장한다.
///
/// 프로필(이름·사진)은 [SharedPreferences]에, 비밀번호는 기기 금고
/// (iOS 키체인 · 안드로이드 EncryptedSharedPreferences · 웹 WebCrypto)에
/// 따로 넣는다. 프로필만 있고 비밀번호가 없으면 얼굴을 눌렀을 때
/// 비밀번호 한 줄만 받아서 들어간다.
///
/// 비밀번호는 '자동 로그인'을 켰을 때만 넣는다. 웹의 금고는 브라우저
/// 저장소를 암호로 감싸 둔 것이라 기기를 통째로 남에게 넘기면 안전하지
/// 않다. 그래서 켜고 끄는 것을 사용자가 정하게 두고, 로그인 화면의
/// ✕로 언제든 지울 수 있게 했다.
class SavedAccounts {
  SavedAccounts._();

  static const _prefKey = 'saved_accounts';
  static const _pwPrefix = 'pw_';

  /// 얼굴이 너무 많아지지 않게 최근 5개까지만 들고 있는다.
  static const _maxAccounts = 5;

  static const _secure = FlutterSecureStorage();

  /// 저장된 프로필 목록. 최근에 로그인한 계정이 앞에 온다.
  static Future<List<SavedAccount>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return const [];

    final List<SavedAccount> accounts = [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          final account = SavedAccount.fromMap(item);
          if (account != null) accounts.add(account);
        }
      }
    } catch (_) {
      // 형식이 깨졌으면 없는 셈 친다(다음 로그인 때 다시 쌓인다).
      return const [];
    }
    accounts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return accounts;
  }

  /// 로그인한 계정의 프로필을 저장하거나 갱신한다.
  /// 이름·사진을 바꾸면 다음 로그인 화면에도 그대로 보인다.
  static Future<void> remember(AppUser user) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final accounts = await list();
    SavedAccount? existing;
    for (final a in accounts) {
      if (a.uid == user.uid) {
        existing = a;
        break;
      }
    }

    final updated = SavedAccount(
      uid: user.uid,
      email: user.email.isNotEmpty ? user.email : (existing?.email ?? ''),
      name: user.name.isNotEmpty ? user.name : (existing?.name ?? ''),
      roleName: user.role?.storageValue ?? existing?.roleName,
      photoBase64: user.photoBase64,
      savedAt: now,
    );

    // 이미 맨 앞에 있고 바뀐 것도 없으면 굳이 다시 쓰지 않는다.
    // (온라인 여부처럼 자주 바뀌는 값 때문에 이 함수가 계속 불린다)
    if (existing != null &&
        accounts.first.uid == user.uid &&
        _sameProfile(existing, updated)) {
      return;
    }

    final next = [updated, ...accounts.where((a) => a.uid != user.uid)];
    await _write(next.take(_maxAccounts).toList());
  }

  static bool _sameProfile(SavedAccount a, SavedAccount b) {
    return a.email == b.email &&
        a.name == b.name &&
        a.roleName == b.roleName &&
        a.photoBase64 == b.photoBase64;
  }

  /// 이 기기에서 계정을 지운다(비밀번호도 같이).
  static Future<void> forget(String uid) async {
    final accounts = await list();
    await _write(accounts.where((a) => a.uid != uid).toList());
    await forgetPassword(uid);
  }

  static Future<void> _write(List<SavedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    if (accounts.isEmpty) {
      await prefs.remove(_prefKey);
      return;
    }
    await prefs.setString(
      _prefKey,
      jsonEncode(accounts.map((a) => a.toMap()).toList()),
    );
  }

  // ── 비밀번호(기기 금고) ──────────────────────────────────────────
  //
  // '자동 로그인'을 켜고 로그인했을 때만 넣는다. 꺼져 있으면 지운다.
  // 금고를 못 쓰는 환경(오래된 브라우저 등)에서는 조용히 실패하고
  // 비밀번호 한 줄을 받는 쪽으로 넘어간다.

  static Future<void> savePassword(String uid, String password) async {
    try {
      await _secure.write(key: '$_pwPrefix$uid', value: password);
    } catch (_) {
      // 금고를 못 쓰면 다음에 비밀번호를 받으면 된다.
    }
  }

  static Future<String?> password(String uid) async {
    try {
      return await _secure.read(key: '$_pwPrefix$uid');
    } catch (_) {
      return null;
    }
  }

  static Future<void> forgetPassword(String uid) async {
    try {
      await _secure.delete(key: '$_pwPrefix$uid');
    } catch (_) {
      // 지울 게 없으면 그만이다.
    }
  }

  /// 얼굴만 눌러서 바로 들어갈 수 있는 계정들의 uid.
  static Future<Set<String>> quickLoginUids(List<SavedAccount> accounts) async {
    final result = <String>{};
    for (final account in accounts) {
      try {
        if (await _secure.containsKey(key: '$_pwPrefix${account.uid}')) {
          result.add(account.uid);
        }
      } catch (_) {
        // 못 읽으면 비밀번호를 받는다.
      }
    }
    return result;
  }
}
