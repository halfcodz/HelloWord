import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// 선택한 테마 팔레트를 보관하고 기기에 저장한다.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._palette);

  static const _prefKey = 'app_palette';

  AppPalette _palette;
  AppPalette get palette => _palette;

  /// 저장된 팔레트를 불러와 컨트롤러를 만든다. (앱 시작 시 1회)
  static Future<ThemeController> load() async {
    AppPalette palette = AppPalette.pink;
    try {
      final prefs = await SharedPreferences.getInstance();
      palette = AppPaletteX.fromName(prefs.getString(_prefKey));
    } catch (_) {
      // 저장소 접근 실패 시 기본값.
    }
    AppColors.apply(palette);
    return ThemeController._(palette);
  }

  Future<void> setPalette(AppPalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    AppColors.apply(palette);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, palette.name);
    } catch (_) {}
  }
}
