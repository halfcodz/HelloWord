import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// 웹: 서비스워커 등록을 해제하고 캐시를 모두 비운 뒤 새로고침한다.
/// PWA(홈 화면에 추가)로 쓰더라도 항상 최신 배포를 불러오게 한다.
void reloadApp() {
  _hardReload();
}

Future<void> _hardReload() async {
  // 1) 서비스워커 등록 해제 (이전 버전 캐시 제공 중단).
  try {
    final container = web.window.navigator.serviceWorker;
    final regs = (await container.getRegistrations().toDart).toDart;
    for (final reg in regs) {
      await reg.unregister().toDart;
    }
  } catch (_) {
    // 서비스워커를 못 건드려도 아래 캐시 삭제/리로드는 계속 진행.
  }

  // 2) 캐시 스토리지 전체 삭제 (오래된 JS/자원 제거).
  try {
    final keys = (await web.window.caches.keys().toDart).toDart;
    for (final key in keys) {
      await web.window.caches.delete(key.toDart).toDart;
    }
  } catch (_) {}

  // 3) 새로고침 — 이제 서버에서 최신 버전을 새로 내려받는다.
  web.window.location.reload();
}
