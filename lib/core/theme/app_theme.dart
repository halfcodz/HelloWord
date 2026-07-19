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

  // ── 중성 토큰(라이트/다크 모드에 따라 [applyMode]로 스왑) ──
  static Color cream = Colors.white; // 카드/다이얼로그/시트 표면
  static Color ink = const Color(0xFF191F28); // 본문 텍스트
  static Color grayText = const Color(0xFF4E5968); // 진한 보조 텍스트
  static Color rowBg = const Color(0xFFF8F9FA); // 리스트 행 배경
  static Color fieldBg = const Color(0xFFF2F4F6); // 입력/칩 배경
  static Color border = const Color(0xFFE5E8EB); // 얇은 테두리

  // ── 고정 토큰(양쪽 모드에서 그대로 사용) ──
  static const Color gray = Color(0xFF8B95A1); // 보조 텍스트(중간 회색)
  static const Color hint = Color(0xFFB0B8C1); // 힌트/비활성
  static const Color blueSoft = Color(0xFFE8F3FF); // 블루 소프트
  static const Color green = Color(0xFF20C997); // 접속/정답
  static const Color greenSoft = Color(0xFFE6FCF5);
  static const Color danger = Color(0xFFFF4D6D); // 배지/에러
  static const Color dangerSoft = Color(0xFFFFEBEE);
  static const Color orangeSoft = Color(0xFFFFF0E1); // 동생 아바타 배경
  static const Color sunday = Color(0xFFFF6B8A); // 달력 일요일

  /// 현재 다크 모드 여부(테마 생성 시 참조).
  static bool isDark = false;

  static void apply(AppPalette palette) {
    final s = _specs[palette]!;
    pink = s.primary;
    pinkSoft = s.primarySoft;
    primaryButton =
        LinearGradient(colors: [s.primary, s.primary]);
    // 배경/보조 회색은 팔레트와 무관하게 유지.
  }

  /// 라이트/다크 모드에 맞춰 중성 토큰과 배경을 스왑한다.
  /// (포인트 색 [apply]와 독립적으로 동작)
  static void applyMode(bool dark) {
    isDark = dark;
    if (dark) {
      ink = const Color(0xFFE8EAED);
      cream = const Color(0xFF1B1E24); // 카드/시트 표면
      grayText = const Color(0xFFAEB6BF);
      rowBg = const Color(0xFF22262D);
      fieldBg = const Color(0xFF2A2F37);
      border = const Color(0xFF363B44);
      lavenderSoft = const Color(0xFF2A2F37);
      background = const LinearGradient(
        colors: [Color(0xFF0F1115), Color(0xFF0F1115)],
      );
    } else {
      ink = const Color(0xFF191F28);
      cream = Colors.white;
      grayText = const Color(0xFF4E5968);
      rowBg = const Color(0xFFF8F9FA);
      fieldBg = const Color(0xFFF2F4F6);
      border = const Color(0xFFE5E8EB);
      lavenderSoft = const Color(0xFFF2F4F6);
      background = const LinearGradient(colors: [Colors.white, Colors.white]);
    }
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
        backgroundColor: AppColors.cream,
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
        color: AppColors.cream,
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
        fillColor: AppColors.fieldBg,
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
        labelStyle: const TextStyle(color: AppColors.gray),
        floatingLabelStyle: TextStyle(color: AppColors.pink),
        hintStyle: const TextStyle(color: AppColors.hint),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lavenderSoft,
        labelStyle: TextStyle(color: AppColors.ink),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
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
