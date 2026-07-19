import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/web_theme.dart';
import 'app_theme.dart';

/// 선택한 포인트 색과 다크 모드 여부를 보관하고 기기에 저장한다.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._palette, this._dark);

  static const _prefKey = 'app_palette';
  static const _prefDark = 'dark_mode';

  AppPalette _palette;
  AppPalette get palette => _palette;

  bool _dark;
  bool get isDark => _dark;

  /// 저장된 설정을 불러와 컨트롤러를 만든다. (앱 시작 시 1회)
  static Future<ThemeController> load() async {
    AppPalette palette = AppPalette.pink;
    bool dark = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      palette = AppPaletteX.fromName(prefs.getString(_prefKey));
      dark = prefs.getBool(_prefDark) ?? false;
    } catch (_) {
      // 저장소 접근 실패 시 기본값.
    }
    AppColors.applyMode(dark);
    AppColors.apply(palette);
    applyWebThemeColor(AppColors.background.colors.first);
    return ThemeController._(palette, dark);
  }

  Future<void> setPalette(AppPalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    AppColors.apply(palette);
    applyWebThemeColor(AppColors.background.colors.first);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, palette.name);
    } catch (_) {}
  }

  Future<void> setDark(bool dark) async {
    if (_dark == dark) return;
    _dark = dark;
    // 중성 토큰을 스왑한 뒤 포인트 색을 다시 입힌다.
    AppColors.applyMode(dark);
    AppColors.apply(_palette);
    applyWebThemeColor(AppColors.background.colors.first);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefDark, dark);
    } catch (_) {}
  }
}
