import 'package:shared_preferences/shared_preferences.dart';

/// 외운 단어를 기기에 저장한다(동생 개인 학습 진행). 무료·로컬 저장.
/// 플래시카드에서 '외웠어요'를 누르면 여기에 기록되고,
/// '안 외운 단어 모아 공부'가 이 기록을 이용한다.
class MemorizedStore {
  MemorizedStore._();

  static const _key = 'memorized_words';
  static Set<String> _cache = {};
  static bool _loaded = false;

  static String _norm(String en) => en.toLowerCase().trim();

  /// 앱 시작 시 1회 불러온다.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cache = (prefs.getStringList(_key) ?? const []).toSet();
    } catch (_) {
      _cache = {};
    }
    _loaded = true;
  }

  static bool isMemorized(String english) => _cache.contains(_norm(english));

  static int get count => _cache.length;

  static Future<void> setMemorized(String english, bool value) async {
    final key = _norm(english);
    if (key.isEmpty) return;
    if (value) {
      if (!_cache.add(key)) return;
    } else {
      if (!_cache.remove(key)) return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _cache.toList());
    } catch (_) {}
  }
}
