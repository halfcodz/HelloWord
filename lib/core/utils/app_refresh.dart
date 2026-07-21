import 'package:shared_preferences/shared_preferences.dart';

import 'app_reload.dart';

/// 전체 새로고침(서비스워커·캐시 비우고 리로드) 및 탭 복원 유틸.
/// 새로고침 버튼과 '당겨서 새로고침'이 공통으로 사용한다.
class AppRefresh {
  AppRefresh._();

  static const _restoreKey = 'restore_tab_on_reload';
  static const _currentTabKey = 'current_tab';

  /// 현재 탭을 저장한다(리로드 후 복원용).
  static Future<void> saveCurrentTab(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentTabKey, index);
    } catch (_) {}
  }

  /// 전체 새로고침. 리로드 후 지금 보던 탭으로 돌아오도록 표시한 뒤,
  /// 기존 새로고침 버튼과 동일하게 서비스워커·캐시를 비우고 리로드한다.
  static Future<void> refreshKeepingTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_restoreKey, true);
    } catch (_) {}
    // 캐시는 지우되 localStorage(위 설정)는 남으므로 복원 정보가 유지된다.
    reloadApp();
  }

  /// 리로드 직후 복원할 탭 번호. 없으면 null. (복원 플래그를 소비한다)
  static Future<int?> consumeRestoreTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_restoreKey) != true) return null;
      await prefs.remove(_restoreKey);
      return prefs.getInt(_currentTabKey);
    } catch (_) {
      return null;
    }
  }
}
