// 플랫폼별 앱 새로고침. 웹은 페이지 리로드, 그 외는 no-op.
export 'app_reload_stub.dart'
    if (dart.library.js_interop) 'app_reload_web.dart';
