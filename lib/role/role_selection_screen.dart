import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../models/app_user.dart';

/// 사용자 문서에 역할이 없을 때(예: 회원가입 도중 중단) 역할을 지정하는 화면.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key, required this.uid});

  final String uid;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _auth = AuthService();
  bool _saving = false;

  Future<void> _choose(UserRole role) async {
    setState(() => _saving = true);
    try {
      await _auth.setRole(uid: widget.uid, role: role);
      // 저장 후 userStream이 갱신되어 AuthGate가 자동 전환한다.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('역할 저장에 실패했습니다. 다시 시도해 주세요.')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('역할 선택'),
        actions: [
          IconButton(
            onPressed: _auth.signOut,
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                '어떤 역할로 사용하시겠어요?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _RoleCard(
                icon: Icons.school_outlined,
                title: '언니 (출제자)',
                subtitle: '단어를 등록하고 시험을 감독합니다.',
                onTap: _saving ? null : () => _choose(UserRole.elder),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.edit_note_outlined,
                title: '동생 (응시자)',
                subtitle: '시험에 참여해 단어를 입력합니다.',
                onTap: _saving ? null : () => _choose(UserRole.younger),
              ),
              if (_saving) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
