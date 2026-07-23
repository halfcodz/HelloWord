import 'package:shared_preferences/shared_preferences.dart';

/// 동생이 '새 자료 알림'을 마지막으로 확인한 시각(ms)을 기기에 저장한다.
/// 언니가 올린 단어 세트의 createdAt이 이 시각보다 나중이면 '새 자료'로 본다.
class SeenMaterialsStore {
  SeenMaterialsStore._();

  static const _key = 'materials_last_seen_ms';
  static int _lastSeenMs = 0;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastSeenMs = prefs.getInt(_key) ?? 0;
      // 첫 실행이면 지금까지의 자료는 '읽음'으로 처리(과거 자료 배지 방지).
      if (_lastSeenMs == 0) {
        _lastSeenMs = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(_key, _lastSeenMs);
      }
    } catch (_) {
      _lastSeenMs = 0;
    }
    _loaded = true;
  }

  static int get lastSeenMs => _lastSeenMs;

  /// 알림을 열었을 때 호출 → 지금까지 온 자료를 모두 확인 처리.
  static Future<void> markSeenNow() async {
    _lastSeenMs = DateTime.now().millisecondsSinceEpoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, _lastSeenMs);
    } catch (_) {}
  }
}
