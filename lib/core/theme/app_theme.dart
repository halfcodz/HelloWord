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
    primary: Color(0xFF00C48C), // 말해보카풍 민트(primary)
    primarySoft: Color(0xFFEAFBF4),
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

  // 포인트 색(민트 primary).
  static Color pink = _specs[AppPalette.pink]!.primary; // primary(민트)
  static Color pinkSoft = _specs[AppPalette.pink]!.primarySoft;

  // 보조/회색 계열.
  static Color lavender = const Color(0xFF9AA1B5); // 보조 텍스트/아이콘 회색
  static Color lavenderSoft = const Color(0xFFF1F3F8); // 옅은 회색 배경

  // 주요 버튼: 민트 그라디언트.
  static LinearGradient primaryButton = const LinearGradient(
    colors: [Color(0xFF00C48C), Color(0xFF00E0A0)],
  );

  // 배경: 연한 블루그레이.
  static LinearGradient background = const LinearGradient(
    colors: [Color(0xFFF6F7FB), Color(0xFFF6F7FB)],
  );

  // ── v2 시그니처 색(잉크 네이비 + 민트) ──
  static const Color navy = Color(0xFF1B2340); // 다크 카드/탭바/강조 버튼
  static const Color navySoft = Color(0xFF232A45); // 네이비 위 표면
  static const Color mint = Color(0xFF00C48C); // 민트 primary
  static const Color mintEnd = Color(0xFF00E0A0); // 민트 그라디언트 끝
  static const Color mintDeep = Color(0xFF00A878); // 진한 민트 텍스트
  static const Color orange = Color(0xFFFF7A3D); // D-DAY 배지
  static const Color peach = Color(0xFFFF922B);
  static const Color onNavy = Color(0xFF8B93B0); // 네이비 위 보조 텍스트

  // ── 중성 토큰(라이트/다크 모드에 따라 [applyMode]로 스왑) ──
  static Color cream = Colors.white; // 카드/다이얼로그/시트 표면
  static Color ink = const Color(0xFF1B2340); // 본문 텍스트(잉크 네이비)
  static Color grayText = const Color(0xFF5D6580); // 진한 보조 텍스트
  static Color rowBg = const Color(0xFFF6F7FB); // 리스트 행 배경
  static Color fieldBg = const Color(0xFFF1F3F8); // 입력/칩 배경
  static Color border = const Color(0xFFE6E9F2); // 얇은 테두리

  // ── 고정 토큰(양쪽 모드에서 그대로 사용) ──
  static const Color gray = Color(0xFF9AA1B5); // 보조 텍스트(중간 회색)
  static const Color hint = Color(0xFFC4C9D6); // 힌트/비활성
  static const Color blueSoft = Color(0xFFEAFBF4); // 민트 소프트(아바타/칩 배경)
  static const Color green = Color(0xFF00C48C); // 정답/성공
  static const Color greenSoft = Color(0xFFEAFBF4);
  static const Color danger = Color(0xFFFF5A5A); // 배지/에러
  static const Color dangerSoft = Color(0xFFFFF0F0);
  static const Color orangeSoft = Color(0xFFFFEFE0); // 오렌지 소프트
  static const Color sunday = Color(0xFFFF5A5A); // 달력 일요일

  /// 현재 다크 모드 여부(테마 생성 시 참조).
  static bool isDark = false;

  static void apply(AppPalette palette) {
    final s = _specs[palette]!;
    pink = s.primary;
    pinkSoft = s.primarySoft;
    primaryButton = const LinearGradient(
      colors: [Color(0xFF00C48C), Color(0xFF00E0A0)],
    );
  }

  /// 라이트/다크 모드에 맞춰 중성 토큰과 배경을 스왑한다.
  static void applyMode(bool dark) {
    isDark = dark;
    if (dark) {
      ink = const Color(0xFFEAECF3);
      cream = const Color(0xFF232A45); // 카드/시트 표면(네이비 톤)
      grayText = const Color(0xFFAEB4C4);
      rowBg = const Color(0xFF1E2540);
      fieldBg = const Color(0xFF2A3252);
      border = const Color(0xFF33406B);
      lavenderSoft = const Color(0xFF2A3252);
      background = const LinearGradient(
        colors: [Color(0xFF141A30), Color(0xFF141A30)],
      );
    } else {
      ink = const Color(0xFF1B2340);
      cream = Colors.white;
      grayText = const Color(0xFF5D6580);
      rowBg = const Color(0xFFF6F7FB);
      fieldBg = const Color(0xFFF1F3F8);
      border = const Color(0xFFE6E9F2);
      lavenderSoft = const Color(0xFFF1F3F8);
      background = const LinearGradient(
        colors: [Color(0xFFF6F7FB), Color(0xFFF6F7FB)],
      );
    }
  }

  /// 은은한 네이비 톤 그림자.
  static List<BoxShadow> softShadow({double blur = 14, double y = 4}) => [
        BoxShadow(
          color: const Color(0xFF1B2340).withValues(alpha: 0.07),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  /// 라이트/다크 공통 테마. [AppColors.applyMode]로 토큰을 스왑한 뒤 호출한다.
  static ThemeData build({bool dark = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pink,
      primary: AppColors.pink,
      secondary: AppColors.pink,
      tertiary: AppColors.mint,
      surface: AppColors.cream,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primaryContainer: AppColors.pinkSoft,
      secondaryContainer: AppColors.lavenderSoft,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
    );

    final baseText = GoogleFonts.notoSansKrTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
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
        // 화면 배경과 자연스럽게 이어지도록 배경색과 동일.
        backgroundColor: dark ? const Color(0xFF141A30) : const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 20,
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle:
              GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mintDeep,
          textStyle:
              GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grayText,
          side: BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          textStyle:
              GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.mint, width: 1.8),
        ),
        labelStyle: const TextStyle(color: AppColors.gray),
        floatingLabelStyle: TextStyle(color: AppColors.mintDeep),
        hintStyle: const TextStyle(color: AppColors.hint),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lavenderSoft,
        labelStyle: TextStyle(color: AppColors.ink),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle:
            GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
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
