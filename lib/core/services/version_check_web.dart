import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// 서버에 올라가 있는 version.json을 읽어 '2.8.0+19' 꼴로 돌려준다.
///
/// 빌드할 때 플러터가 만들어 주는 파일이라 따로 관리할 것이 없다.
/// 주소에 [cacheBuster]를 붙여서 서비스워커·브라우저가 예전에 받아 둔
/// 사본을 내주지 못하게 한다(그러면 새 버전을 영영 못 본다).
Future<String?> fetchServerVersion(String cacheBuster) async {
  try {
    final response = await web.window
        .fetch(
          'version.json?v=$cacheBuster'.toJS,
          web.RequestInit(cache: 'no-store'),
        )
        .toDart;
    if (!response.ok) return null;

    final body = (await response.text().toDart).toDart;
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;

    final version = decoded['version'];
    if (version is! String || version.isEmpty) return null;
    final build = decoded['build_number'];
    return (build is String && build.isNotEmpty) ? '$version+$build' : version;
  } catch (_) {
    // 인터넷이 잠깐 끊겼거나 파일이 없으면 조용히 넘어간다.
    return null;
  }
}
