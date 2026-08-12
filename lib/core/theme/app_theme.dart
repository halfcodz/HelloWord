import 'package:flutter/material.dart';

/// ── HelloWord 디자인 시스템 ─────────────────────────────────────────
/// ui-ux-pro-max 스킬이 '영어 단어 시험·공부 앱(교육/퀴즈)' 기준으로 뽑아준
/// 디자인 시스템을 Flutter 토큰으로 옮긴 것.
///
/// - 스타일: Flat Design (그라디언트·큰 그림자 없이 색과 여백으로 위계를 만든다)
/// - 색: 퀴즈 블루(#2563EB) + 학습 보라(#7C3AED) + 성취 골드(#F59E0B)
/// - 타이포: Fredoka(제목·영어 단어·숫자) + Nunito(본문) + 한글은 Noto Sans KR
/// - 모션: 150~300ms, easeOutCubic 계열
///
/// 색은 반드시 [AppColors] 토큰으로 쓴다(화면에서 hex 직접 사용 금지).
/// 여백은 [AppSpace], 모서리는 [AppRadius], 시간·커브는 [AppMotion]을 쓴다.

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
  const _PaletteSpec({
    required this.primary,
    required this.primarySoft,
    required this.primaryDark,
  });

  /// 라이트 모드 포인트 색.
  final Color primary;

  /// 포인트 색의 옅은 배경(칩·뱃지 바탕).
  final Color primarySoft;

  /// 다크 모드에서 쓰는 밝은 변형(어두운 바탕에서 대비 확보용).
  final Color primaryDark;
}

// 교육/퀴즈 앱 팔레트: 신뢰감 있는 블루 계열을 기본으로 한다.
const Map<AppPalette, _PaletteSpec> _specs = {
  AppPalette.pink: _PaletteSpec(
    primary: Color(0xFF2563EB), // 퀴즈 블루(primary)
    primarySoft: Color(0xFFDBEAFE),
    primaryDark: Color(0xFF60A5FA),
  ),
  AppPalette.lavender: _PaletteSpec(
    primary: Color(0xFF4F46E5),
    primarySoft: Color(0xFFE0E7FF),
    primaryDark: Color(0xFF818CF8),
  ),
  AppPalette.mint: _PaletteSpec(
    primary: Color(0xFF16A34A),
    primarySoft: Color(0xFFDCFCE7),
    primaryDark: Color(0xFF4ADE80),
  ),
  AppPalette.sky: _PaletteSpec(
    primary: Color(0xFF0891B2),
    primarySoft: Color(0xFFCFFAFE),
    primaryDark: Color(0xFF38BDF8),
  ),
  AppPalette.peach: _PaletteSpec(
    primary: Color(0xFFEA8A0B),
    primarySoft: Color(0xFFFEF3C7),
    primaryDark: Color(0xFFFBBF24),
  ),
};

/// 중앙 색 토큰. [AppColors.apply]로 포인트 색을, [AppColors.applyMode]로
/// 라이트/다크 중성 색을 갱신한다.
class AppColors {
  AppColors._();

  // ── 포인트(브랜드) 색 ──
  // 이름(pink/mint)은 예전 코드 호환을 위해 유지하되 값은 퀴즈 블루다.
  static Color pink = _specs[AppPalette.pink]!.primary; // primary
  static Color pinkSoft = _specs[AppPalette.pink]!.primarySoft;
  static Color mint = _specs[AppPalette.pink]!.primary; // primary(별칭)
  static Color mintEnd = const Color(0xFF3B82F6); // primary 밝은 변형
  static Color mintDeep = const Color(0xFF1D4ED8); // primary 진한 변형(텍스트)

  /// 주요 버튼 배경. Flat 디자인이라 단색에 가깝게 둔다.
  static LinearGradient primaryButton = LinearGradient(
    colors: [pink, mintEnd],
  );

  /// 앱 배경(아주 옅은 블루). 움직이는 배경이 이 위에 그려진다.
  static LinearGradient background = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7FAFF), Color(0xFFEFF6FF)],
  );

  // ── 보조 색 ──
  static const Color purple = Color(0xFF7C3AED); // 학습/복습 계열 강조
  static const Color purpleSoft = Color(0xFFEDE9FE);
  static const Color gold = Color(0xFFF59E0B); // 성취·연속학습·D-DAY
  static const Color goldSoft = Color(0xFFFEF3C7);
  static const Color orange = gold; // 예전 이름 호환
  static const Color peach = gold;
  static const Color orangeSoft = goldSoft;

  // ── 잉크 네이비(다크 표면: 탭바·통화 패널·스낵바) ──
  static const Color navy = Color(0xFF0F172A);
  static const Color navySoft = Color(0xFF1E293B);
  static const Color onNavy = Color(0xFF94A3B8); // 네이비 위 보조 텍스트

  // ── 중성 토큰(라이트/다크에 따라 [applyMode]로 스왑) ──
  static Color cream = Colors.white; // 카드/다이얼로그/시트 표면
  static Color ink = const Color(0xFF0F172A); // 본문 텍스트
  static Color grayText = const Color(0xFF475569); // 진한 보조 텍스트
  static Color rowBg = const Color(0xFFF1F5FD); // 리스트 행 배경
  static Color fieldBg = const Color(0xFFEFF4FF); // 입력/칩 배경
  static Color border = const Color(0xFFE4ECFC); // 얇은 테두리
  static Color gray = const Color(0xFF64748B); // 보조 텍스트(대비 4.5:1)
  static Color hint = const Color(0xFF94A3B8); // 힌트/비활성
  static Color lavender = const Color(0xFF64748B); // 보조 아이콘(중성)
  static Color lavenderSoft = const Color(0xFFF1F5FD);
  static Color blueSoft = const Color(0xFFDBEAFE); // 포인트 소프트(아바타 배경)

  // ── 의미 색(정답·오답은 모드와 무관하게 유지) ──
  // 어두운 바탕에서는 같은 채도로 두면 눈에 안 박히므로 [applyMode]에서 밝게 바꾼다.
  static Color green = const Color(0xFF16A34A); // 정답/성공
  static Color greenSoft = const Color(0xFFDCFCE7);
  static Color danger = const Color(0xFFDC2626); // 오답/삭제/경고
  static Color dangerSoft = const Color(0xFFFEE2E2);
  static Color sunday = const Color(0xFFDC2626); // 달력 일요일

  /// 현재 다크 모드 여부(테마 생성 시 참조).
  static bool isDark = false;

  /// 현재 선택된 포인트 색(모드 전환 때 다시 계산하려고 기억해 둔다).
  static AppPalette _palette = AppPalette.pink;

  static void apply(AppPalette palette) {
    _palette = palette;
    _applyPalette();
  }

  static void _applyPalette() {
    final s = _specs[_palette]!;
    pink = isDark ? s.primaryDark : s.primary;
    pinkSoft = isDark
        ? Color.alphaBlend(s.primary.withValues(alpha: 0.22), navy)
        : s.primarySoft;
    mint = pink;
    mintEnd = isDark
        ? Color.lerp(pink, Colors.white, 0.18)!
        : Color.lerp(pink, Colors.white, 0.12)!;
    mintDeep = isDark ? Color.lerp(pink, Colors.white, 0.3)! : s.primary;
    blueSoft = pinkSoft;
    primaryButton = LinearGradient(colors: [pink, mintEnd]);
  }

  /// 라이트/다크 모드에 맞춰 중성 토큰과 배경을 스왑한다.
  static void applyMode(bool dark) {
    isDark = dark;
    if (dark) {
      ink = const Color(0xFFE8EDF7);
      cream = const Color(0xFF151E32); // 카드/시트 표면
      grayText = const Color(0xFFB6C0D4);
      gray = const Color(0xFF97A3BA);
      hint = const Color(0xFF6B7893);
      rowBg = const Color(0xFF111A2C);
      fieldBg = const Color(0xFF1B2740);
      border = const Color(0xFF26324F);
      lavender = const Color(0xFF97A3BA);
      lavenderSoft = const Color(0xFF1B2740);
      // 정답·오답 색은 어두운 바탕에서 대비가 나오도록 밝은 쪽으로.
      green = const Color(0xFF4ADE80);
      greenSoft = const Color(0xFF14301F);
      danger = const Color(0xFFF87171);
      dangerSoft = const Color(0xFF3A1A1A);
      sunday = const Color(0xFFF87171);
      background = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1526), Color(0xFF0B1220)],
      );
    } else {
      ink = const Color(0xFF0F172A);
      cream = Colors.white;
      grayText = const Color(0xFF475569);
      gray = const Color(0xFF64748B);
      hint = const Color(0xFF94A3B8);
      rowBg = const Color(0xFFF1F5FD);
      fieldBg = const Color(0xFFEFF4FF);
      border = const Color(0xFFE4ECFC);
      lavender = const Color(0xFF64748B);
      lavenderSoft = const Color(0xFFF1F5FD);
      green = const Color(0xFF16A34A);
      greenSoft = const Color(0xFFDCFCE7);
      danger = const Color(0xFFDC2626);
      dangerSoft = const Color(0xFFFEE2E2);
      sunday = const Color(0xFFDC2626);
      background = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF7FAFF), Color(0xFFEFF6FF)],
      );
    }
    _applyPalette();
  }

  /// 표면을 배경에서 살짝 띄우는 정도의 그림자.
  /// Flat 디자인이라 그림자는 '있는 듯 없는 듯'만 준다.
  static List<BoxShadow> softShadow({double blur = 14, double y = 4}) => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.05),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];
}

/// 4/8dp 리듬을 지키는 여백 토큰.
class AppSpace {
  AppSpace._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// 화면 좌우 기본 여백.
  static const double gutter = 20;
}

/// 모서리 반경 토큰. 종류를 섞지 않도록 이 단계만 쓴다.
class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// 마이크로 인터랙션 시간·커브. (150~300ms 유지)
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 300);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  /// 살짝 튕기는 느낌(칩·뱃지 등장). 정보성 목록에는 쓰지 않는다.
  static const Curve pop = Curves.easeOutBack;
}

/// 아이콘 크기 토큰(임의 크기 혼용 방지).
class AppIconSize {
  AppIconSize._();

  static const double sm = 18;
  static const double md = 24;
  static const double lg = 32;
}

class AppTheme {
  AppTheme._();

  /// 본문용 라틴 폰트. 앱에 직접 넣어 두었다(pubspec.yaml 참고).
  static const String bodyFamily = 'Nunito';

  /// 제목·영어 단어용 라틴 폰트.
  static const String displayFamily = 'Fredoka';

  /// 한글을 그리는 폰트.
  ///
  /// Nunito·Fredoka에는 한글 글리프가 아예 없다. 예전에는 여기에 기기에 깔린
  /// 폰트 이름('Apple SD Gothic Neo' 등)을 적어 뒀는데, **웹에서는 그런 이름이
  /// 통하지 않는다.** 브라우저의 그리기 엔진(CanvasKit)은 기기 폰트를 모르고
  /// 앱에 등록된 폰트만 알기 때문이다. 그래서 한글을 만날 때마다 엔진이
  /// 한글 폰트를 인터넷에서 따로 받아 왔고, 받아오는 동안 네모(□·⊠)가 보였다.
  /// 이제는 앱에 넣은 폰트를 지정해 그런 일이 없다.
  ///
  /// 이모지도 같은 이유로 앱에 넣었다(쓰는 것만 골라 41KB).
  /// 'Apple Color Emoji'는 아이폰·맥 앱에서만 통하므로 뒤에 둔다.
  static const List<String> koFallback = [
    'NotoSansKR',
    'NotoColorEmoji',
    'Apple Color Emoji',
  ];

  /// 본문 폰트(Nunito + 한글).
  static TextStyle font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: bodyFamily,
        fontFamilyFallback: koFallback,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// 제목·영어 단어·점수 숫자용 폰트(Fredoka, 둥글고 친근한 느낌).
  /// 단어 앱의 주인공인 영어 단어를 이 폰트로 그린다.
  static TextStyle display({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: displayFamily,
        fontFamilyFallback: koFallback,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// 숫자를 표에 나란히 세울 때(점수·개수) 쓰는 고정폭 숫자 스타일.
  static TextStyle tabularNumber({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      display(fontSize: fontSize, fontWeight: fontWeight, color: color)
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// 로딩 화면처럼 어떤 경우에도 글자가 보여야 하는 곳에 쓰는 스타일.
  /// 이제 폰트를 앱에 넣어 두어 기다릴 일이 없지만, 상위 스타일이 섞이지 않게
  /// 하려고 남겨 둔다. (inherit: false)
  static TextStyle systemFont({
    required double fontSize,
    required Color color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) =>
      TextStyle(
        inherit: false,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        fontFamilyFallback: koFallback,
      );

  /// 라이트/다크 공통 테마. [AppColors.applyMode]로 토큰을 스왑한 뒤 호출한다.
  static ThemeData build({bool dark = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pink,
      primary: AppColors.pink,
      onPrimary: Colors.white,
      secondary: AppColors.purple,
      tertiary: AppColors.gold,
      error: AppColors.danger,
      surface: AppColors.cream,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primaryContainer: AppColors.pinkSoft,
      onPrimaryContainer: AppColors.mintDeep,
      secondaryContainer: AppColors.purpleSoft,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.rowBg,
      outline: AppColors.border,
    );

    final baseText = ThemeData(brightness: Brightness.light).textTheme.apply(
          fontFamily: bodyFamily,
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
          fontFamilyFallback: koFallback,
        );

    // 제목 계열만 Fredoka로 바꿔 위계를 만든다.
    final textTheme = baseText.copyWith(
      displayLarge: display(fontSize: 40, color: AppColors.ink),
      displayMedium: display(fontSize: 32, color: AppColors.ink),
      displaySmall: display(fontSize: 28, color: AppColors.ink),
      headlineMedium:
          display(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.ink),
      headlineSmall:
          display(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleLarge:
          display(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleMedium: font(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
      titleSmall: font(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: font(fontSize: 16, height: 1.5, color: AppColors.ink),
      bodyMedium: font(fontSize: 14, height: 1.5, color: AppColors.ink),
      bodySmall: font(fontSize: 13, height: 1.45, color: AppColors.gray),
      labelLarge: font(fontSize: 15, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
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
        // 화면 배경(움직이는 배경)이 그대로 비치도록 투명하게 둔다.
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: display(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.hint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          // 최소 44pt 터치 영역.
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: font(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mintDeep,
          minimumSize: const Size(48, 44),
          textStyle: font(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grayText,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          textStyle: font(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.grayText,
          minimumSize: const Size(44, 44),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.pink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: TextStyle(color: AppColors.gray),
        floatingLabelStyle: TextStyle(color: AppColors.mintDeep),
        hintStyle: TextStyle(color: AppColors.hint),
        helperStyle: TextStyle(color: AppColors.gray, fontSize: 12),
        errorStyle: TextStyle(color: AppColors.danger, fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lavenderSoft,
        selectedColor: AppColors.pinkSoft,
        labelStyle: font(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: display(
            fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.ink),
        contentTextStyle:
            font(fontSize: 15, height: 1.5, color: AppColors.grayText),
        // 뒤 화면이 시각적으로 경쟁하지 않도록 충분히 어둡게.
        barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: font(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        actionTextColor: AppColors.mintEnd,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.pink,
        linearTrackColor: AppColors.border,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.cream,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.pink
              : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: font(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

/// 부드럽고 담백한 페이드 + 살짝 슬라이드 전환.
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
    // 시스템 '동작 줄이기'가 켜져 있으면 페이드만 준다.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    if (reduceMotion) {
      return FadeTransition(opacity: curved, child: child);
    }
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
