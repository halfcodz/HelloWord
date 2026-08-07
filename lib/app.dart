import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'auth/auth_gate.dart';
import 'core/services/sfx_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/safe_area_insets.dart';
import 'core/widgets/animated_background.dart';
import 'features/chat/repositories/chat_repository.dart';
import 'features/exam/repositories/exam_repository.dart';
import 'features/social/repositories/friend_repository.dart';
import 'features/todo/repositories/todo_repository.dart';
import 'features/word_sets/repositories/word_set_repository.dart';

class HelloWordApp extends StatelessWidget {
  const HelloWordApp({
    super.key,
    required this.themeController,
    required this.sfx,
  });

  final ThemeController themeController;
  final SfxService sfx;

  /// 콘텐츠 최대 폭. 모바일 사파리에서는 화면 전체, 데스크톱 브라우저에서는
  /// 이 폭의 "폰 컬럼"이 가운데 정렬된다.
  static const double maxContentWidth = 480;

  /// 반응형 계산 기준(디자인 프레임 402×874).
  static const Size _designSize = Size(402, 874);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WordSetRepository>(create: (_) => WordSetRepository()),
        Provider<ExamRepository>(create: (_) => ExamRepository()),
        Provider<FriendRepository>(create: (_) => FriendRepository()),
        Provider<ChatRepository>(create: (_) => ChatRepository()),
        Provider<TodoRepository>(create: (_) => TodoRepository()),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<SfxService>.value(value: sfx),
      ],
      // 팔레트가 바뀌면 테마를 다시 계산해 앱 전체에 반영한다.
      child: Consumer<ThemeController>(
        builder: (context, controller, child) => MaterialApp(
          title: 'HelloWord',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(dark: controller.isDark),
          builder: (context, child) => _ResponsiveShell(child: child),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// 웹/데스크톱에서도 모바일 기준 스케일을 유지하도록 폭을 제한하고,
/// 넓은 화면에서는 가운데 폰 컬럼으로 배치한다.
///
/// 화면 가장자리 여백(노치·홈 인디케이터)도 여기서 채워 넣는다. 자세한 이유는
/// [readSafeAreaInsets] 설명 참고 — 홈 화면에 추가해 쓸 때 하단 탭바가
/// 홈 인디케이터 구역에 깔려 눌리지 않던 문제를 막는다.
class _ResponsiveShell extends StatefulWidget {
  const _ResponsiveShell({required this.child});

  final Widget? child;

  @override
  State<_ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<_ResponsiveShell>
    with WidgetsBindingObserver {
  /// 브라우저에서 읽어 온 가장자리 여백. 앱(iOS/Android)에서는 항상 0이고
  /// Flutter가 주는 값을 그대로 쓴다.
  EdgeInsets _safeArea = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _safeArea = readSafeAreaInsets();
  }

  @override
  void didChangeMetrics() {
    // 화면을 돌리거나 창 크기가 바뀌면 여백도 달라진다.
    final next = readSafeAreaInsets();
    if (next != _safeArea && mounted) setState(() => _safeArea = next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final isWide = fullWidth > HelloWordApp.maxContentWidth;
        final contentWidth =
            isWide ? HelloWordApp.maxContentWidth : fullWidth;

        final base = MediaQuery.of(context);
        // Flutter가 주는 값과 브라우저에서 읽은 값 중 큰 쪽을 쓴다.
        // 이러면 앱에서는 원래 동작 그대로고, 웹에서만 값이 채워진다.
        final viewPadding = _merge(base.viewPadding, _safeArea);
        // 키보드가 올라오면 아래 여백은 키보드가 대신 차지한다(Flutter 기본 규칙).
        final padding = EdgeInsets.fromLTRB(
          viewPadding.left,
          viewPadding.top,
          viewPadding.right,
          (viewPadding.bottom - base.viewInsets.bottom).clamp(
            0.0,
            viewPadding.bottom,
          ),
        );

        // ScreenUtil이 실제 창 폭이 아니라 제한된 폭 기준으로 스케일하도록
        // 직접 configure한다. (ScreenUtilInit은 창 크기를 읽어 데스크톱에서 과대 스케일됨)
        final clampedMedia = base.copyWith(
          size: Size(contentWidth, constraints.maxHeight),
          padding: padding,
          viewPadding: viewPadding,
        );
        ScreenUtil.configure(
          data: clampedMedia,
          designSize: HelloWordApp._designSize,
          minTextAdapt: true,
          splitScreenMode: true,
        );

        final content = MediaQuery(
          data: clampedMedia,
          child: AnimatedBackground(
            child: widget.child ?? const SizedBox.shrink(),
          ),
        );

        if (!isWide) return content;

        // 데스크톱: 옅은 블루그레이 배경 위에 폰 컬럼을 가운데 배치.
        return ColoredBox(
          color: AppColors.isDark
              ? const Color(0xFF070C17)
              : const Color(0xFFE2EAF8),
          child: Center(
            child: Container(
              width: contentWidth,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.18),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
          ),
        );
      },
    );
  }

  /// 두 여백 중 각 변마다 큰 쪽을 고른다.
  static EdgeInsets _merge(EdgeInsets a, EdgeInsets b) => EdgeInsets.fromLTRB(
        math.max(a.left, b.left),
        math.max(a.top, b.top),
        math.max(a.right, b.right),
        math.max(a.bottom, b.bottom),
      );
}
