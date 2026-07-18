import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../models/app_user.dart';

/// Phase 0의 임시 홈. 로그인/역할이 정상 동작하는지 확인하는 용도이며
/// Phase 1에서 단어 세트 목록 화면으로 대체된다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final isElder = user.role == UserRole.elder;
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
              const SizedBox(height: 8),
              Chip(
                avatar: Icon(
                  isElder ? Icons.school_outlined : Icons.edit_note_outlined,
                  size: 18,
                ),
                label: Text(user.role?.label ?? '역할 미지정'),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✅ Phase 0 완료: 로그인 · 역할 설정'),
                      const SizedBox(height: 12),
                      Text(
                        isElder
                            ? '다음 단계에서 단어 파일을 올리고 시험을 만들 수 있어요.'
                            : '다음 단계에서 언니가 낸 시험에 참여할 수 있어요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
