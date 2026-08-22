import 'package:flutter_test/flutter_test.dart';
import 'package:helloword/core/services/version_watcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 서버가 돌려줄 버전을 마음대로 바꿔 가며 쓰는 가짜 응답.
class _FakeServer {
  String? version;
  int calls = 0;

  Future<String?> fetch(String cacheBuster) async {
    calls++;
    return version;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('VersionWatcher', () {
    test('서버 버전이 같으면 알리지 않는다', () async {
      final server = _FakeServer()..version = '2.8.0+19';
      final watcher = VersionWatcher(current: '2.8.0+19', fetch: server.fetch);

      await watcher.check();

      expect(watcher.updateAvailable, isFalse);
      expect(watcher.newVersion, isNull);
    });

    test('서버 버전이 다르면 새 버전이 있다고 알린다', () async {
      final server = _FakeServer()..version = '2.9.0+20';
      final watcher = VersionWatcher(current: '2.8.0+19', fetch: server.fetch);

      await watcher.check();

      expect(watcher.updateAvailable, isTrue);
      expect(watcher.newVersion, '2.9.0+20');
      // 화면에는 빌드 번호를 떼고 보여 준다.
      expect(watcher.newVersionLabel, '2.9.0');
    });

    test('닫으면 그 버전은 다시 알리지 않는다', () async {
      final server = _FakeServer()..version = '2.9.0+20';
      final watcher = VersionWatcher(current: '2.8.0+19', fetch: server.fetch);
      await watcher.check();

      await watcher.dismiss();

      expect(watcher.updateAvailable, isFalse);

      // 같은 버전을 또 봐도 조용하다.
      await watcher.check();
      expect(watcher.updateAvailable, isFalse);
    });

    test('닫은 뒤에 또 새 버전이 올라오면 다시 알린다', () async {
      final server = _FakeServer()..version = '2.9.0+20';
      final watcher = VersionWatcher(current: '2.8.0+19', fetch: server.fetch);
      await watcher.check();
      await watcher.dismiss();

      server.version = '3.0.0+21';
      await watcher.check();

      expect(watcher.updateAvailable, isTrue);
      expect(watcher.newVersionLabel, '3.0.0');
    });

    test('서버를 못 읽으면 알고 있던 것을 그대로 둔다', () async {
      final server = _FakeServer()..version = '2.9.0+20';
      final watcher = VersionWatcher(current: '2.8.0+19', fetch: server.fetch);
      await watcher.check();

      server.version = null; // 인터넷이 끊겼다
      await watcher.check();

      expect(watcher.updateAvailable, isTrue);
    });

    test('되돌려 배포해서 서버가 다시 같아지면 알림을 거둔다', () async {
      final server = _FakeServer()..version = '2.9.0+20';
      final watcher = VersionWatcher(current: '2.8.0+19', fetch: server.fetch);
      await watcher.check();
      expect(watcher.updateAvailable, isTrue);

      server.version = '2.8.0+19';
      await watcher.check();

      expect(watcher.updateAvailable, isFalse);
    });

    test('빌드에 버전이 안 심겨 있으면 아예 확인하지 않는다', () async {
      final server = _FakeServer()..version = '2.9.0+20';
      final watcher = VersionWatcher(current: '', fetch: server.fetch);

      await watcher.check();
      await watcher.start();

      expect(server.calls, 0);
      expect(watcher.updateAvailable, isFalse);
    });

    test('알림을 켜고 끌 때 화면에 알려 준다', () async {
      final server = _FakeServer()..version = '2.9.0+20';
      final watcher = VersionWatcher(current: '2.8.0+19', fetch: server.fetch);
      var notified = 0;
      watcher.addListener(() => notified++);

      await watcher.check();
      expect(notified, 1);

      // 같은 답이면 다시 그리지 않는다.
      await watcher.check();
      expect(notified, 1);

      await watcher.dismiss();
      expect(notified, 2);
    });
  });
}
