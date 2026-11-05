import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../auth/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_components.dart';
import '../core/widgets/cat_mascot.dart';
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
          padding: EdgeInsets.all(AppSpace.lg.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpace.xs.h),
              Center(child: CatMascot(size: 72.w)),
              SizedBox(height: AppSpace.sm.h),
              Text(
                '어떤 역할로 쓸까?',
                textAlign: TextAlign.center,
                style: AppTheme.display(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: AppSpace.lg.h),
              _RoleCard(
                icon: Icons.school_rounded,
                title: '언니 (출제자)',
                subtitle: '단어를 올리고 시험을 지켜봐요',
                onTap: _saving ? null : () => _choose(UserRole.elder),
              ),
              SizedBox(height: AppSpace.sm.h),
              _RoleCard(
                icon: Icons.edit_rounded,
                title: '동생 (응시자)',
                subtitle: '시험에 들어가서 단어를 써요',
                onTap: _saving ? null : () => _choose(UserRole.younger),
              ),
              if (_saving) ...[
                SizedBox(height: AppSpace.lg.h),
                Center(child: CatLoader(width: 120.w)),
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
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(AppSpace.md.w + 2),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.pinkSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppIconSize.md.sp, color: AppColors.pink),
          ),
          SizedBox(width: AppSpace.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: AppSpace.xxs.h),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.hint),
        ],
      ),
    );
  }
}
