import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

/// 로그인 상태를 확인하는 잠깐 동안 보이는 화면.
///
/// 웹 껍데기(index.html)가 이미 로고 로딩 화면을 보여 주므로 여기서 또
/// 카드를 띄우면 로딩 화면이 두 번 나온 것처럼 보인다. 그래서 배경만 두고
/// 아무것도 그리지 않는다.
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Colors.transparent);
}
