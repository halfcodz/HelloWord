// 플랫폼별 새 버전 확인. 웹만 실제로 확인하고 그 외에는 no-op.
export 'version_check_stub.dart'
    if (dart.library.js_interop) 'version_check_web.dart';
