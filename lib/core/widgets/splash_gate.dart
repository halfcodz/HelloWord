// 색을 AppColors에서 읽으므로 const로 만들지 않는다(테마 전환 시 다시 그리기 위해).
// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'cat_mascot.dart';

/// 앱을 열면 고양이 로고 스플래시를 잠깐(약 0.9초) 보여 주고 흐리게 사라진다.
///
/// 스플래시가 떠 있는 동안에도 아래 화면([child])은 미리 만들어져
/// 로그인 확인 같은 준비를 이어서 하므로, 스플래시 때문에 늦어지지 않는다.
class SplashGate extends StatefulWidget {
  SplashGate({super.key, required this.child});

  final Widget child;

  /// 스플래시를 보여 주는 시간(사라지는 시간 제외).
  static const Duration hold = Duration(milliseconds: 900);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _fading = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(SplashGate.hold, () {
      if (mounted) setState(() => _fading = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_gone)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _fading,
              child: AnimatedOpacity(
                opacity: _fading ? 0 : 1,
                duration: AppMotion.slow,
                curve: AppMotion.exit,
                onEnd: () {
                  if (_fading && mounted) setState(() => _gone = true);
                },
                child: _SplashView(),
              ),
            ),
          ),
      ],
    );
  }
}

class _SplashView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Material로 감싸야 글자 밑에 디버그용 노란 밑줄이 생기지 않는다.
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.background),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CatLogo(size: 112.w),
              SizedBox(height: AppSpace.md.h),
              Text(
                'HelloWord',
                style: AppTheme.display(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
