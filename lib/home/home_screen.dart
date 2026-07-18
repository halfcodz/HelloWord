import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.name}님, 환영합니다 👋',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('곧 언니가 낸 시험에 참여할 수 있어요. (Phase 2에서 구현)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
