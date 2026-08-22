import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helloword/auth/saved_accounts.dart';
import 'package:helloword/models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppUser _user(
  String uid, {
  String name = '이름',
  String email = 'a@b.com',
  UserRole role = UserRole.younger,
  String? photo,
}) {
  return AppUser(
    uid: uid,
    email: email,
    name: name,
    role: role,
    photoBase64: photo,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SavedAccounts', () {
    test('처음에는 저장된 계정이 없다', () async {
      expect(await SavedAccounts.list(), isEmpty);
    });

    test('로그인한 계정을 이름·사진까지 저장한다', () async {
      await SavedAccounts.remember(
        _user('u1', name: '예린', email: 'yerin@x.com', photo: 'abc'),
      );

      final saved = await SavedAccounts.list();
      expect(saved.single.uid, 'u1');
      expect(saved.single.name, '예린');
      expect(saved.single.email, 'yerin@x.com');
      expect(saved.single.photoBase64, 'abc');
      expect(saved.single.role, UserRole.younger);
    });

    test('같은 계정을 다시 저장해도 하나로 유지하고 이름을 갱신한다', () async {
      await SavedAccounts.remember(_user('u1', name: '예린'));
      await SavedAccounts.remember(_user('u1', name: '예린공주'));

      final saved = await SavedAccounts.list();
      expect(saved.length, 1);
      expect(saved.single.name, '예린공주');
    });

    test('최근에 로그인한 계정이 목록 앞에 온다', () async {
      await SavedAccounts.remember(_user('u1', name: '언니'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await SavedAccounts.remember(_user('u2', name: '동생'));

      final saved = await SavedAccounts.list();
      expect(saved.map((a) => a.uid), ['u2', 'u1']);
    });

    test('계정은 최근 5개까지만 들고 있는다', () async {
      for (var i = 0; i < 7; i++) {
        await SavedAccounts.remember(_user('u$i'));
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      final saved = await SavedAccounts.list();
      expect(saved.length, 5);
      expect(saved.first.uid, 'u6');
      expect(saved.map((a) => a.uid), isNot(contains('u0')));
    });

    test('지우면 목록에서 빠진다', () async {
      await SavedAccounts.remember(_user('u1'));
      await SavedAccounts.remember(_user('u2'));

      await SavedAccounts.forget('u1');

      final saved = await SavedAccounts.list();
      expect(saved.single.uid, 'u2');
    });

    test('저장된 값이 깨져 있으면 빈 목록으로 본다', () async {
      SharedPreferences.setMockInitialValues({'saved_accounts': '{망가짐'});
      expect(await SavedAccounts.list(), isEmpty);
    });

    test('uid 없는 항목은 건너뛴다', () async {
      SharedPreferences.setMockInitialValues({
        'saved_accounts': jsonEncode([
          {'email': 'no-uid@x.com'},
          {'uid': 'u1', 'email': 'ok@x.com', 'name': '언니', 'savedAt': 1},
        ]),
      });

      final saved = await SavedAccounts.list();
      expect(saved.single.uid, 'u1');
    });

    test('기기 금고를 못 쓰면 바로 로그인할 계정이 없다고 본다', () async {
      // 테스트 환경에는 금고 플러그인이 없다. 예외를 삼키고 빈 값을 준다.
      await SavedAccounts.remember(_user('u1'));
      final saved = await SavedAccounts.list();
      expect((await SavedAccounts.quickLogin(saved)).ready, isEmpty);
      expect(await SavedAccounts.password('u1'), isNull);
    });

    test('저장에 실패하면 false를 주고, 저장 안 되는 계정으로 표시한다', () async {
      await SavedAccounts.remember(_user('u1'));

      // 금고가 없으니 저장은 실패한다.
      expect(await SavedAccounts.savePassword('u1', 'pw1234'), isFalse);

      final saved = await SavedAccounts.list();
      final quick = await SavedAccounts.quickLogin(saved);
      expect(quick.ready, isEmpty);
      // '넣으려고 했다'는 표시가 남아 화면에서 이유를 말해 줄 수 있다.
      expect(quick.broken, {'u1'});
    });

    test('저장을 포기하면 저장 안 되는 계정 표시도 지운다', () async {
      await SavedAccounts.remember(_user('u1'));
      await SavedAccounts.savePassword('u1', 'pw1234');

      await SavedAccounts.forgetPassword('u1');

      final saved = await SavedAccounts.list();
      final quick = await SavedAccounts.quickLogin(saved);
      expect(quick.ready, isEmpty);
      expect(quick.broken, isEmpty);
    });
  });
}
