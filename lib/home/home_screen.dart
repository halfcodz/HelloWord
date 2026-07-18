import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../auth/auth_service.dart';
import '../features/exam/views/session_join_view.dart';
import '../features/word_sets/views/word_set_list_view.dart';
import '../models/app_user.dart';

/// 로그인 후 역할에 맞는 첫 화면을 보여준다.
/// - 언니(출제자): 단어 세트 목록
/// - 동생(응시자): 시험 참여 안내(Phase 2에서 구현)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    if (user.role == UserRole.elder) {
      return WordSetListView(user: user);
    }
    return _YoungerHome(user: user);
  }
}

class _YoungerHome extends StatelessWidget {
  const _YoungerHome({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelloWord'),
        actions: [
          IconButton(
            onPressed: AuthService().signOut,
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${user.name}님, 환영합니다 👋',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 40.h),
              Icon(
                Icons.school_outlined,
                size: 72.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 16.h),
              Text(
                '언니가 시험을 열고 코드를 알려주면\n아래 버튼으로 참여하세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 32.h),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SessionJoinView(user: user),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: const Text('시험 참여하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
