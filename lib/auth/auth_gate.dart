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

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76.w,
              height: 76.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Text('📖', style: TextStyle(fontSize: 38.sp)),
            ),
            SizedBox(height: 18.h),
            Text('HelloWord',
                style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.ink)),
            SizedBox(height: 6.h),
            Text('자매 영어 단어 시험',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayText)),
            SizedBox(height: 28.h),
            SizedBox(
              width: 34.w,
              height: 34.w,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.mint),
                backgroundColor: AppColors.mint.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
