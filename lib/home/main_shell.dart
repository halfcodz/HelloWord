import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/bouncy_tap.dart';
import '../core/widgets/gradient_button.dart';
import '../features/exam/views/session_join_view.dart';
import '../features/profile/views/profile_view.dart';
import '../features/word_sets/views/calendar_home_view.dart';
import '../features/word_sets/views/word_set_list_view.dart';
import '../models/app_user.dart';

/// 로그인 후 메인 화면. 하단바(홈·시험·내 정보)로 역할별 화면을 전환한다.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user});

  final AppUser user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<Widget> _pages() {
    final user = widget.user;
    if (user.role == UserRole.elder) {
      return [
        CalendarHomeView(user: user),
        WordSetListView(user: user, title: '시험 내기 📝', enableAdd: false),
        ProfileView(user: user),
      ];
    }
    return [
      _YoungerHomeTab(
        user: user,
        onStart: () => setState(() => _index = 1),
      ),
      SessionJoinView(user: user),
      ProfileView(user: user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final examLabel = widget.user.role == UserRole.elder ? '시험 내기' : '시험 참여';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _index, children: _pages()),
      bottomNavigationBar: _BlingBottomBar(
        index: _index,
        examLabel: examLabel,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BlingBottomBar extends StatelessWidget {
  const _BlingBottomBar({
    required this.index,
    required this.examLabel,
    required this.onTap,
  });

  final int index;
  final String examLabel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: '홈'),
      (icon: Icons.quiz_rounded, label: examLabel),
      (icon: Icons.person_rounded, label: '내 정보'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26.r),
          topRight: Radius.circular(26.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _BarItem(
                  icon: items[i].icon,
                  label: items[i].label,
                  selected: index == i,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryButton : null,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22.sp,
              color: selected ? Colors.white : AppColors.lavender,
            ),
            if (selected) ...[
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(fontSize: 13.sp, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 동생 홈 탭: 환영 + 시험 참여 유도.
class _YoungerHomeTab extends StatelessWidget {
  const _YoungerHomeTab({required this.user, required this.onStart});

  final AppUser user;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HelloWord ✨')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${user.name}님, 안녕! 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24.sp, color: AppColors.ink)),
                SizedBox(height: 40.h),
                Container(
                  width: 130.w,
                  height: 130.w,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButton,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.softShadow(),
                  ),
                  child: Icon(Icons.school_rounded,
                      size: 64.sp, color: Colors.white),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(
                        begin: 0,
                        end: -10,
                        duration: 1500.ms,
                        curve: Curves.easeInOut),
                SizedBox(height: 28.h),
                Text(
                  '언니가 시험을 열고 코드를 알려주면\n아래 버튼으로 참여해요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.sp, color: AppColors.ink),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: '시험 참여하기',
                    icon: Icons.login_rounded,
                    onPressed: onStart,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }
}
