import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'auth/auth_gate.dart';
import 'features/exam/repositories/exam_repository.dart';
import 'features/word_sets/repositories/word_set_repository.dart';

class HelloWordApp extends StatelessWidget {
  const HelloWordApp({super.key});

  /// 콘텐츠 최대 폭. 모바일 사파리에서는 화면 전체, 데스크톱 브라우저에서는
  /// 이 폭의 "폰 컬럼"이 가운데 정렬된다.
  static const double maxContentWidth = 480;

  /// 반응형 계산 기준(iPhone 13/14).
  static const Size _designSize = Size(390, 844);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WordSetRepository>(create: (_) => WordSetRepository()),
        Provider<ExamRepository>(create: (_) => ExamRepository()),
      ],
      child: MaterialApp(
        title: 'HelloWord',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF6C63FF),
          useMaterial3: true,
        ),
        builder: (context, child) => _ResponsiveShell(child: child),
        home: const AuthGate(),
      ),
    );
  }
}

/// 웹/데스크톱에서도 모바일 기준 스케일을 유지하도록 폭을 제한하고,
/// 넓은 화면에서는 가운데 폰 컬럼으로 배치한다.
class _ResponsiveShell extends StatelessWidget {
  const _ResponsiveShell({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final isWide = fullWidth > HelloWordApp.maxContentWidth;
        final contentWidth =
            isWide ? HelloWordApp.maxContentWidth : fullWidth;

        // ScreenUtil이 실제 창 폭이 아니라 제한된 폭 기준으로 스케일하도록
        // 직접 configure한다. (ScreenUtilInit은 창 크기를 읽어 데스크톱에서 과대 스케일됨)
        final clampedMedia = MediaQuery.of(context).copyWith(
          size: Size(contentWidth, constraints.maxHeight),
        );
        ScreenUtil.configure(
          data: clampedMedia,
          designSize: HelloWordApp._designSize,
          minTextAdapt: true,
          splitScreenMode: true,
        );

        final content = MediaQuery(
          data: clampedMedia,
          child: child ?? const SizedBox.shrink(),
        );

        if (!isWide) return content;

        // 데스크톱: 옅은 배경 위에 그림자를 준 폰 컬럼을 가운데 배치.
        return ColoredBox(
          color: const Color(0xFFE9E7F3),
          child: Center(
            child: Container(
              width: contentWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
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
}
