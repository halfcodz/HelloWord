import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/services/presence_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/bouncy_tap.dart';
import '../features/chat/views/chat_list_view.dart';
import '../features/exam/views/session_join_view.dart';
import '../features/profile/views/profile_view.dart';
import '../features/study/views/study_list_view.dart';
import '../features/todo/views/todo_home_view.dart';
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
  final _presence = PresenceService();

  @override
  void initState() {
    super.initState();
    _presence.start(widget.user.uid);
    _updateStudying();
  }

  @override
  void dispose() {
    _presence.setStudying(false);
    _presence.dispose();
    super.dispose();
  }

  ({List<Widget> pages, List<_NavItem> items}) _config() {
    final user = widget.user;
    if (user.role == UserRole.elder) {
      return (
        pages: [
          CalendarHomeView(user: user),
          WordSetListView(user: user, title: '공부자료', enableAdd: true),
          WordSetListView(user: user, title: '시험 내기', enableAdd: false),
          ChatListView(user: user),
          ProfileView(user: user),
        ],
        items: const [
          _NavItem(Icons.home_rounded, '홈'),
          _NavItem(Icons.folder_rounded, '자료'),
          _NavItem(Icons.quiz_rounded, '시험'),
          _NavItem(Icons.chat_bubble_rounded, '채팅'),
          _NavItem(Icons.person_rounded, '내 정보'),
        ],
      );
    }
    return (
      pages: [
        TodoHomeView(user: user),
        StudyListView(user: user),
        SessionJoinView(user: user),
        ChatListView(user: user),
        ProfileView(user: user),
      ],
      items: const [
        _NavItem(Icons.home_rounded, '홈'),
        _NavItem(Icons.menu_book_rounded, '공부'),
        _NavItem(Icons.quiz_rounded, '시험'),
        _NavItem(Icons.chat_bubble_rounded, '채팅'),
        _NavItem(Icons.person_rounded, '내 정보'),
      ],
    );
  }

  /// 동생이 '공부' 탭(index 1)에 있을 때만 공부중 상태를 켠다.
  void _updateStudying() {
    final studying =
        widget.user.role == UserRole.younger && _index == 1;
    _presence.setStudying(studying);
  }

  void _onTab(int i) {
    setState(() => _index = i);
    _updateStudying();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _index, children: config.pages),
      bottomNavigationBar: _BlingBottomBar(
        index: _index,
        items: config.items,
        onTap: _onTab,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _BlingBottomBar extends StatelessWidget {
  const _BlingBottomBar({
    required this.index,
    required this.items,
    required this.onTap,
  });

  final int index;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 6.w),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BarItem(
                    icon: items[i].icon,
                    label: items[i].label,
                    selected: index == i,
                    onTap: () => onTap(i),
                  ),
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
    // 선택: 진한 핑크 / 비선택: 옅은 회보라 — 대비를 확실히.
    final color = selected ? AppColors.pink : const Color(0xFFB7B0C7);
    return BouncyTap(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.pinkSoft.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, size: 22.sp, color: color),
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 10.sp,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
