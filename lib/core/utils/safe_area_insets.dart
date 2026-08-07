// 플랫폼별 화면 가장자리 여백(노치·다이나믹 아일랜드·홈 인디케이터) 읽기.
// 앱(iOS/Android)은 Flutter가 알아서 알려주므로 웹에서만 직접 읽는다.
export 'safe_area_insets_stub.dart'
    if (dart.library.js_interop) 'safe_area_insets_web.dart';
