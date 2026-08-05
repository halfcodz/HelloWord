import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import '../home/main_shell.dart';
import '../models/app_user.dart';
import '../role/role_selection_screen.dart';
import 'auth_service.dart';
import 'login_screen.dart';

/// 로그인 상태와 역할 지정 여부에 따라 진입 화면을 결정하는 라우터.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        final firebaseUser = authSnap.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        // 로그인 완료 → 사용자 문서(역할 포함)를 실시간 구독.
        return StreamBuilder<AppUser?>(
          stream: auth.userStream(firebaseUser.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScaffold();
            }

            final appUser = userSnap.data;
            if (appUser == null || appUser.role == null) {
              return RoleSelectionScreen(uid: firebaseUser.uid);
            }
            return MainShell(user: appUser);
          },
        );
      },
    );
  }
}

/// 로딩 화면. 배경 애니메이션 위에 카드 하나만 띄우고,
/// 로고가 살짝 통통 뛰며 점 세 개가 차례로 깜빡인다.
class _LoadingScaffold extends StatefulWidget {
  const _LoadingScaffold();

  @override
  State<_LoadingScaffold> createState() => _LoadingScaffoldState();
}

class _LoadingScaffoldState extends State<_LoadingScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 26.h),
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  // 0~1을 오르내리게 만들어 통통 뛰는 느낌을 준다.
                  final t = _c.value;
                  final bounce = (1 - (2 * t - 1).abs());
                  final eased = Curves.easeOut.transform(bounce);
                  return Transform.translate(
                    offset: Offset(0, -8.h * eased),
                    child: Transform.rotate(
                      angle: 0.06 * (eased - 0.5),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 76.w,
                  height: 76.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 38.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              // 로딩 화면은 구글 폰트를 내려받기 전에 보이는 화면이므로,
              // 기기 기본 폰트로 그려 글자가 □로 보이지 않게 한다.
              Text(
                'HelloWord',
                style: AppTheme.systemFont(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '자매 영어 단어 시험',
                style: AppTheme.systemFont(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray,
                ),
              ),
              SizedBox(height: 20.h),
              // 점 세 개가 차례로 커졌다 작아진다.
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) SizedBox(width: 7.w),
                      _dot(i),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int index) {
    final phase = (_c.value + index * 0.22) % 1.0;
    final pop = (1 - (2 * phase - 1).abs());
    return Container(
      width: 8.w + 3.w * pop,
      height: 8.w + 3.w * pop,
      decoration: BoxDecoration(
        color: AppColors.pink.withValues(alpha: 0.35 + 0.5 * pop),
        shape: BoxShape.circle,
      ),
    );
  }
}
