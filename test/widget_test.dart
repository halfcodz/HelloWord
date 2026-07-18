// Firebase 초기화가 필요 없는 순수 모델 단위 테스트.
// 위젯 스모크 테스트는 Firebase 연결 후 별도로 추가한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:helloword/models/app_user.dart';

void main() {
  group('UserRole', () {
    test('storageValue는 enum 이름과 같다', () {
      expect(UserRole.elder.storageValue, 'elder');
      expect(UserRole.younger.storageValue, 'younger');
    });

    test('fromStorage는 저장값을 역할로 복원한다', () {
      expect(UserRoleX.fromStorage('elder'), UserRole.elder);
      expect(UserRoleX.fromStorage('younger'), UserRole.younger);
    });

    test('fromStorage는 알 수 없는 값이면 null을 반환한다', () {
      expect(UserRoleX.fromStorage(null), isNull);
      expect(UserRoleX.fromStorage('unknown'), isNull);
    });
  });

  group('AppUser.fromMap', () {
    test('누락된 필드는 기본값으로 채운다', () {
      final user = AppUser.fromMap('uid1', {});
      expect(user.uid, 'uid1');
      expect(user.email, '');
      expect(user.name, '');
      expect(user.role, isNull);
    });

    test('저장된 맵을 올바르게 파싱한다', () {
      final user = AppUser.fromMap('uid2', {
        'email': 'a@b.com',
        'name': '동생',
        'role': 'younger',
      });
      expect(user.email, 'a@b.com');
      expect(user.name, '동생');
      expect(user.role, UserRole.younger);
    });
  });
}
