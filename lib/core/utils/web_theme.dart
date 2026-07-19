// 플랫폼별 웹 테마색 적용. 웹은 body/theme-color 갱신, 그 외는 no-op.
export 'web_theme_stub.dart'
    if (dart.library.js_interop) 'web_theme_web.dart';
