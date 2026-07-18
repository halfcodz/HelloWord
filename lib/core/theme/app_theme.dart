import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 사용자가 설정에서 고를 수 있는 색 테마.
enum AppPalette { pink, lavender, mint, sky, peach }

extension AppPaletteX on AppPalette {
  String get label => switch (this) {
        AppPalette.pink => '핑크',
        AppPalette.lavender => '라벤더',
        AppPalette.mint => '민트',
        AppPalette.sky => '하늘',
        AppPalette.peach => '피치',
      };

  /// 스와치에 보여줄 대표색.
  Color get swatch => _specs[this]!.primary;

  static AppPalette fromName(String? name) {
    for (final p in AppPalette.values) {
      if (p.name == name) return p;
    }
    return AppPalette.pink;
  }
}

class _PaletteSpec {
  const _PaletteSpec({
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.secondarySoft,
    required this.button,
    required this.background,
  });

  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color secondarySoft;
  final List<Color> button;
  final List<Color> background;
}

const Map<AppPalette, _PaletteSpec> _specs = {
  AppPalette.pink: _PaletteSpec(
    primary: Color(0xFFFF7FB6),
    primarySoft: Color(0xFFFFC1DA),
    secondary: Color(0xFFB79CED),
    secondarySoft: Color(0xFFE4DAFF),
    button: [Color(0xFFFF8FBF), Color(0xFFB79CED)],
    background: [Color(0xFFFFF0F7), Color(0xFFF1ECFF)],
  ),
  AppPalette.lavender: _PaletteSpec(
    primary: Color(0xFF9B8CEC),
    primarySoft: Color(0xFFD9CFFF),
    secondary: Color(0xFFF48FC0),
    secondarySoft: Color(0xFFFAD4E8),
    button: [Color(0xFFA98FEE), Color(0xFFF48FC0)],
    background: [Color(0xFFF3EFFF), Color(0xFFFDEEF7)],
  ),
  AppPalette.mint: _PaletteSpec(
    primary: Color(0xFF4FCBA6),
    primarySoft: Color(0xFFBFEEDF),
    secondary: Color(0xFF7FC8E8),
    secondarySoft: Color(0xFFCDEBF7),
    button: [Color(0xFF57D6B0), Color(0xFF7FC8E8)],
    background: [Color(0xFFEBFBF5), Color(0xFFEAF6FB)],
  ),
  AppPalette.sky: _PaletteSpec(
    primary: Color(0xFF6FA8FF),
    primarySoft: Color(0xFFCFE0FF),
    secondary: Color(0xFF9B8CEC),
    secondarySoft: Color(0xFFDCD5F7),
    button: [Color(0xFF7FB0FF), Color(0xFF9B8CEC)],
    background: [Color(0xFFEDF4FF), Color(0xFFF1EEFF)],
  ),
  AppPalette.peach: _PaletteSpec(
    primary: Color(0xFFFF9166),
    primarySoft: Color(0xFFFFD6C2),
    secondary: Color(0xFFFFB27F),
    secondarySoft: Color(0xFFFFE6D3),
    button: [Color(0xFFFF9E7A), Color(0xFFFFC48F)],
    background: [Color(0xFFFFF3EC), Color(0xFFFFF6EF)],
  ),
};

/// 현재 팔레트에 따라 값이 바뀌는 색 토큰. [AppColors.apply]로 갱신한다.
class AppColors {
  AppColors._();

  // 팔레트 의존(가변) 토큰 — 기본은 핑크.
  static Color pink = _specs[AppPalette.pink]!.primary;
  static Color pinkSoft = _specs[AppPalette.pink]!.primarySoft;
  static Color lavender = _specs[AppPalette.pink]!.secondary;
  static Color lavenderSoft = _specs[AppPalette.pink]!.secondarySoft;

  static LinearGradient primaryButton = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF8FBF), Color(0xFFB79CED)],
  );
  static LinearGradient background = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF0F7), Color(0xFFF1ECFF)],
  );

  // 고정 토큰.
  static const Color mint = Color(0xFF8FE3C8);
  static const Color peach = Color(0xFFFFD3B6);
  static const Color cream = Color(0xFFFFF6FB);
  static const Color ink = Color(0xFF5B4A63);

  static void apply(AppPalette palette) {
    final s = _specs[palette]!;
    pink = s.primary;
    pinkSoft = s.primarySoft;
    lavender = s.secondary;
    lavenderSoft = s.secondarySoft;
    primaryButton = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: s.button,
    );
    background = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: s.background,
    );
  }

  static List<BoxShadow> softShadow({double blur = 24, double y = 10}) => [
        BoxShadow(
          color: pink.withValues(alpha: 0.18),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pink,
      primary: AppColors.pink,
      secondary: AppColors.lavender,
      tertiary: AppColors.mint,
      surface: Colors.white,
      brightness: Brightness.light,
    ).copyWith(
      primaryContainer: AppColors.pinkSoft,
      secondaryContainer: AppColors.lavenderSoft,
      onSurface: AppColors.ink,
    );

    final baseText = GoogleFonts.juaTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: baseText,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SoftPageTransitionsBuilder(),
          TargetPlatform.iOS: _SoftPageTransitionsBuilder(),
          TargetPlatform.macOS: _SoftPageTransitionsBuilder(),
          TargetPlatform.windows: _SoftPageTransitionsBuilder(),
          TargetPlatform.linux: _SoftPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.jua(fontSize: 20, color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: AppColors.pink.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.jua(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lavender,
          textStyle: GoogleFonts.jua(fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.pinkSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.pinkSoft.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.pink, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.ink),
        floatingLabelStyle: TextStyle(color: AppColors.pink),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lavenderSoft,
        labelStyle: const TextStyle(color: AppColors.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lavender,
        contentTextStyle: GoogleFonts.jua(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// 부드러운 페이드 + 살짝 위로 슬라이드 + 스케일 화면 전환.
class _SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
