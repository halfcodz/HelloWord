import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 사용자가 설정에서 고를 수 있는 포인트 색.
enum AppPalette { pink, lavender, mint, sky, peach }

extension AppPaletteX on AppPalette {
  String get label => switch (this) {
        AppPalette.pink => '블루',
        AppPalette.lavender => '인디고',
        AppPalette.mint => '그린',
        AppPalette.sky => '스카이',
        AppPalette.peach => '오렌지',
      };

  Color get swatch => _specs[this]!.primary;

  static AppPalette fromName(String? name) {
    for (final p in AppPalette.values) {
      if (p.name == name) return p;
    }
    return AppPalette.pink;
  }
}

class _PaletteSpec {
  const _PaletteSpec({required this.primary, required this.primarySoft});
  final Color primary;
  final Color primarySoft;
}

// 토스풍: 흰/회색 바탕에 깔끔한 포인트 색.
const Map<AppPalette, _PaletteSpec> _specs = {
  AppPalette.pink: _PaletteSpec(
    primary: Color(0xFF3182F6), // Toss-like blue
    primarySoft: Color(0xFFE8F3FF),
  ),
  AppPalette.lavender: _PaletteSpec(
    primary: Color(0xFF4C6EF5),
    primarySoft: Color(0xFFEAEDFF),
  ),
  AppPalette.mint: _PaletteSpec(
    primary: Color(0xFF20C997),
    primarySoft: Color(0xFFE6FCF5),
  ),
  AppPalette.sky: _PaletteSpec(
    primary: Color(0xFF15AABF),
    primarySoft: Color(0xFFE3FAFC),
  ),
  AppPalette.peach: _PaletteSpec(
    primary: Color(0xFFFF922B),
    primarySoft: Color(0xFFFFF0E1),
  ),
};

/// 중앙 색 토큰. [AppColors.apply]로 포인트 색을 갱신한다.
/// (이름은 기존 호환을 위해 유지하되 값은 토스풍으로 재정의)
class AppColors {
  AppColors._();

  // 포인트 색(팔레트 의존).
  static Color pink = _specs[AppPalette.pink]!.primary; // primary
  static Color pinkSoft = _specs[AppPalette.pink]!.primarySoft;

  // 보조/회색 계열(고정).
  static Color lavender = const Color(0xFF8B95A1); // 보조 텍스트/아이콘 회색
  static Color lavenderSoft = const Color(0xFFF2F4F6); // 옅은 회색 배경

  // 주요 버튼: 단색(그라데이션 형태지만 같은 색 두 개).
  static LinearGradient primaryButton = const LinearGradient(
    colors: [Color(0xFF3182F6), Color(0xFF3182F6)],
  );

  // 배경: 흰색.
  static LinearGradient background = const LinearGradient(
    colors: [Colors.white, Colors.white],
  );

  static const Color mint = Color(0xFF20C997);
  static const Color peach = Color(0xFFFF922B);
  static const Color cream = Colors.white; // 다이얼로그/시트 흰색
  static const Color ink = Color(0xFF191F28); // 거의 검정 텍스트

  static void apply(AppPalette palette) {
    final s = _specs[palette]!;
    pink = s.primary;
    pinkSoft = s.primarySoft;
    primaryButton =
        LinearGradient(colors: [s.primary, s.primary]);
    // 배경/보조 회색은 팔레트와 무관하게 유지.
  }

  /// 아주 은은한 회색 그림자(흰 배경 위에서도 보이도록).
  static List<BoxShadow> softShadow({double blur = 16, double y = 4}) => [
        BoxShadow(
          color: const Color(0xFF191F28).withValues(alpha: 0.08),
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
      secondary: AppColors.pink,
      tertiary: AppColors.mint,
      surface: Colors.white,
      brightness: Brightness.light,
    ).copyWith(
      primaryContainer: AppColors.pinkSoft,
      secondaryContainer: AppColors.lavenderSoft,
      onSurface: AppColors.ink,
    );

    final baseText = GoogleFonts.notoSansKrTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: baseText,
      splashFactory: NoSplash.splashFactory,
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 18,
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle:
              GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pink,
          textStyle:
              GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F4F6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.pink, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8B95A1)),
        floatingLabelStyle: TextStyle(color: AppColors.pink),
        hintStyle: const TextStyle(color: Color(0xFFB0B8C1)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lavenderSoft,
        labelStyle: const TextStyle(color: AppColors.ink),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF333D4B),
        contentTextStyle:
            GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E8EB),
        thickness: 1,
      ),
    );
  }
}

/// 부드럽고 담백한 페이드 + 살짝 슬라이드 전환(토스풍).
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
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
