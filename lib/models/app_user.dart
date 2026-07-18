/// 앱 사용자의 역할. 언니는 출제자, 동생은 응시자.
enum UserRole { elder, younger }

extension UserRoleX on UserRole {
  /// Firestore에 저장되는 값 ('elder' | 'younger').
  String get storageValue => name;

  String get label => this == UserRole.elder ? '언니 (출제자)' : '동생 (응시자)';

  static UserRole? fromStorage(String? value) {
    if (value == null) return null;
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }
}

/// Firestore `users/{uid}` 문서에 대응하는 모델.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.role,
    this.online = false,
    this.studying = false,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole? role;

  /// 현재 앱에 접속 중인지.
  final bool online;

  /// 현재 시험(공부) 중인지.
  final bool studying;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: UserRoleX.fromStorage(map['role'] as String?),
      online: map['online'] as bool? ?? false,
      studying: map['studying'] as bool? ?? false,
    );
  }
}
