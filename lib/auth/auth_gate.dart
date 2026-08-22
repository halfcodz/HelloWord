import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/main_shell.dart';
import '../models/app_user.dart';
import '../role/role_selection_screen.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'saved_accounts.dart';

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
            // 로그인 화면의 얼굴 목록에 쓸 이름·사진을 기기에 남겨 둔다.
            return _RememberProfile(
              user: appUser,
              child: MainShell(user: appUser),
            );
          },
        );
      },
    );
  }
}

/// 로그인한 계정의 프로필을 이 기기에 저장해 둔다.
///
/// 다음에 로그인 화면이 나올 때 이름·사진이 얼굴 목록에 그대로 보이고,
/// 이름이나 사진을 바꾸면 여기서 바로 갱신된다.
class _RememberProfile extends StatefulWidget {
  const _RememberProfile({required this.user, required this.child});

  final AppUser user;
  final Widget child;

  @override
  State<_RememberProfile> createState() => _RememberProfileState();
}

class _RememberProfileState extends State<_RememberProfile> {
  @override
  void initState() {
    super.initState();
    SavedAccounts.remember(widget.user);
  }

  @override
  void didUpdateWidget(_RememberProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    SavedAccounts.remember(widget.user);
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
