import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helloword/features/call/services/ice_config.dart';

/// 영상통화가 지나갈 길(ICE) 설정 확인.
/// 중계 서버(TURN)가 빠지면 서로 다른 망에서 영상·소리가 아예 가지 않으므로
/// .env를 제대로 읽는지 확실히 해 둔다.
void main() {
  setUp(IceConfig.resetCache);
  tearDown(IceConfig.resetCache);

  group('IceConfig', () {
    test('TURN 설정이 없으면 중계 서버 없이 STUN만 쓴다', () {
      dotenv.loadFromString(envString: '# 비어 있음\n');
      IceConfig.resetCache();

      expect(IceConfig.hasTurn, isFalse);
      final servers = IceConfig.peerConfig['iceServers'] as List;
      expect(servers, hasLength(1));
      expect((servers.first as Map)['urls'], isA<List<String>>());
    });

    test('아이디·비밀번호가 비면 중계 서버를 쓰지 않는다', () {
      dotenv.loadFromString(envString: 'TURN_URL=turn:example.com:3478\n');
      IceConfig.resetCache();

      expect(IceConfig.hasTurn, isFalse);
    });

    test('쉼표로 넣은 주소를 각각 따로 등록한다', () {
      dotenv.loadFromString(envString: '''
TURN_URL=turn:example.com:3478, turns:example.com:443?transport=tcp
TURN_USERNAME=sister
TURN_CREDENTIAL=secret
''');
      IceConfig.resetCache();

      expect(IceConfig.hasTurn, isTrue);
      final turn = IceConfig.turnServersForTest;
      expect(turn, hasLength(2));
      expect(turn[0]['urls'], 'turn:example.com:3478');
      expect(turn[1]['urls'], 'turns:example.com:443?transport=tcp');
      for (final s in turn) {
        expect(s['username'], 'sister');
        expect(s['credential'], 'secret');
      }
    });

    test('죽은 openrelay 주소가 남아 있지 않다', () {
      dotenv.loadFromString(envString: '# 비어 있음\n');
      IceConfig.resetCache();

      expect(IceConfig.peerConfig.toString(), isNot(contains('openrelay')));
    });

    test('중계 서버 두 곳을 각각 다른 계정으로 넣을 수 있다', () {
      dotenv.loadFromString(envString: '''
TURN_URL=turn:aaa.example.com:3478
TURN_USERNAME=aaa-id
TURN_CREDENTIAL=aaa-pw
TURN_URL_2=turn:bbb.example.com:443
TURN_USERNAME_2=bbb-id
TURN_CREDENTIAL_2=bbb-pw
''');
      IceConfig.resetCache();

      final turn = IceConfig.turnServersForTest;
      expect(turn, hasLength(2));
      expect(turn[0]['username'], 'aaa-id');
      expect(turn[1]['urls'], 'turn:bbb.example.com:443');
      expect(turn[1]['username'], 'bbb-id');
      expect(turn[1]['credential'], 'bbb-pw');
    });

    test('두 번째 중계 서버만 채워도 동작한다', () {
      dotenv.loadFromString(envString: '''
TURN_URL_2=turn:bbb.example.com:443
TURN_USERNAME_2=bbb-id
TURN_CREDENTIAL_2=bbb-pw
''');
      IceConfig.resetCache();

      expect(IceConfig.hasTurn, isTrue);
      expect(IceConfig.turnServersForTest, hasLength(1));
    });

    test('turn:이 빠진 주소는 붙여서 쓴다', () {
      // 대시보드에서 주소만 복사하면 앞의 turn:을 빠뜨리기 쉽다.
      // 그대로 두면 브라우저가 잘못된 주소로 보고 통째로 무시한다.
      dotenv.loadFromString(envString: '''
TURN_URL=free.expressturn.com:3478
TURN_USERNAME=sister
TURN_CREDENTIAL=secret
''');
      IceConfig.resetCache();

      expect(
        IceConfig.turnServersForTest.single['urls'],
        'turn:free.expressturn.com:3478',
      );
    });

    test('이미 turn:/turns:가 붙어 있으면 그대로 둔다', () {
      dotenv.loadFromString(envString: '''
TURN_URL=turn:a.example.com:3478, turns:b.example.com:443?transport=tcp
TURN_USERNAME=sister
TURN_CREDENTIAL=secret
''');
      IceConfig.resetCache();

      final turn = IceConfig.turnServersForTest;
      expect(turn[0]['urls'], 'turn:a.example.com:3478');
      expect(turn[1]['urls'], 'turns:b.example.com:443?transport=tcp');
    });

    test('STUN과 TURN이 함께 들어간다', () {
      dotenv.loadFromString(envString: '''
TURN_URL=turn:example.com:3478
TURN_USERNAME=sister
TURN_CREDENTIAL=secret
''');
      IceConfig.resetCache();

      final servers = IceConfig.peerConfig['iceServers'] as List;
      expect(servers, hasLength(2));
      expect(IceConfig.peerConfig['sdpSemantics'], 'unified-plan');
    });
  });
}
