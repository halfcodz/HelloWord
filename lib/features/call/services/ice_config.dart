import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 영상통화가 지나갈 길(ICE 서버) 설정.
///
/// **STUN만으로는 부족하다.** STUN은 "내 공인 IP가 뭔지" 알려줄 뿐이고,
/// 두 기기가 서로 직접 만날 수 있을 때만 통한다. 통신사 LTE·5G나 회사·학교
/// 와이파이처럼 포트가 매번 바뀌는 망(symmetric NAT)에서는 직접 만나지 못해서
/// **중계 서버(TURN)가 없으면 영상도 소리도 상대에게 아예 가지 않는다.**
/// 신호(offer/answer)는 Firestore로 잘 오가기 때문에 "연결 중"만 계속 뜬다.
///
/// 예전에 쓰던 무료 공개 중계 서버(openrelay.metered.ca)는 문을 닫았다.
/// 지금은 그 주소의 80 포트에 웹서버가 떠 있고 443 포트는 연결을 거부한다.
/// 그래서 중계 자격증명은 `.env`에 직접 넣어 쓴다(public 저장소라 커밋 금지).
///
/// ```
/// TURN_URL=turn:relay1.expressturn.com:3478,turns:relay1.expressturn.com:443?transport=tcp
/// TURN_USERNAME=발급받은_아이디
/// TURN_CREDENTIAL=발급받은_비밀번호
/// ```
///
/// 자세한 발급 방법은 `.env.example`에 적어 두었다.
class IceConfig {
  const IceConfig._();

  /// 어디서나 잘 붙는 공개 STUN 서버들.
  static const List<String> _stunUrls = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun2.l.google.com:19302',
    'stun:stun3.l.google.com:19302',
  ];

  /// `.env`에 중계 서버(TURN)가 설정되어 있는지.
  /// 없으면 같은 와이파이처럼 서로 직접 만날 수 있는 상황에서만 통화가 된다.
  static bool get hasTurn => _turnServers.isNotEmpty;

  static List<Map<String, dynamic>>? _cachedTurn;

  static List<Map<String, dynamic>> get _turnServers {
    return _cachedTurn ??= _buildTurnServers();
  }

  /// .env를 다시 읽게 한다(테스트용).
  @visibleForTesting
  static void resetCache() => _cachedTurn = null;

  /// 설정된 중계 서버 목록(테스트용).
  @visibleForTesting
  static List<Map<String, dynamic>> get turnServersForTest => _turnServers;

  static String _env(String key) {
    // dotenv를 불러오지 못한 경우(파일 없음)에도 앱이 죽지 않게 한다.
    try {
      return dotenv.env[key]?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static List<Map<String, dynamic>> _buildTurnServers() {
    final urls = _env('TURN_URL')
        .split(',')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    final username = _env('TURN_USERNAME');
    final credential = _env('TURN_CREDENTIAL');

    if (urls.isEmpty) return const [];
    if (username.isEmpty || credential.isEmpty) {
      debugPrint(
        'TURN_URL은 있는데 TURN_USERNAME/TURN_CREDENTIAL이 비어 있습니다. '
        '중계 서버 없이 연결을 시도합니다.',
      );
      return const [];
    }

    // 서버를 하나씩 따로 넣는다. 한 주소가 죽어도 나머지를 계속 시도한다.
    return [
      for (final url in urls)
        {'urls': url, 'username': username, 'credential': credential},
    ];
  }

  /// PeerConnection에 넘길 설정.
  static Map<String, dynamic> get peerConfig => {
        'sdpSemantics': 'unified-plan',
        // 후보를 미리 모아 두면 첫 연결이 조금 더 빠르다.
        'iceCandidatePoolSize': 2,
        'bundlePolicy': 'max-bundle',
        'iceServers': [
          {'urls': _stunUrls},
          ..._turnServers,
        ],
      };

  /// 설정 상태를 로그로 남긴다(연결이 안 될 때 원인을 찾기 위해).
  static void logStatus() {
    if (hasTurn) {
      debugPrint('영상통화: 중계 서버(TURN) ${_turnServers.length}개 설정됨.');
    } else {
      debugPrint(
        '영상통화: 중계 서버(TURN)가 없습니다. 서로 다른 망(LTE 등)에 있으면 '
        '영상·소리가 상대에게 가지 않을 수 있습니다. .env에 TURN_URL/'
        'TURN_USERNAME/TURN_CREDENTIAL을 넣어 주세요.',
      );
    }
  }
}
