import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../core/services/presence_service.dart';
import '../features/chat/repositories/chat_repository.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/app_refresh.dart';
import '../core/widgets/bouncy_tap.dart';
import '../features/chat/views/chat_list_view.dart';
import '../features/exam/views/exam_dashboard_view.dart';
import '../features/exam/views/exam_schedule_view.dart';
import '../features/exam/views/session_join_view.dart';
import '../features/profile/views/profile_view.dart';
import '../features/study/views/study_list_view.dart';
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
    _restoreTabAfterReload();
  }

  /// 새로고침(리로드) 직후라면 보던 탭으로 복원한다.
  Future<void> _restoreTabAfterReload() async {
    final tab = await AppRefresh.consumeRestoreTab();
    if (tab == null || !mounted) return;
    setState(() => _index = tab);
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
          ExamDashboardView(user: user),
          WordSetListView(user: user, title: '공부자료', enableAdd: true),
          ChatListView(user: user),
          ProfileView(user: user),
        ],
        items: const [
          _NavItem(Icons.home_rounded, '홈'),
          _NavItem(Icons.folder_rounded, '자료'),
          _NavItem(Icons.chat_bubble_rounded, '채팅'),
          _NavItem(Icons.person_rounded, '내 정보'),
        ],
      );
    }
    return (
      pages: [
        ExamScheduleView(user: user),
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
    AppRefresh.saveCurrentTab(i); // 새로고침 후 이 탭으로 복원되도록 저장
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 토글 시 하단바·현재 탭이 즉시 다시 그려지도록 테마를 구독한다.
    context.watch<ThemeController>();
    final config = _config();
    final chatIndex = config.items.indexWhere((it) => it.label == '채팅');
    // 각 탭을 당겨서 새로고침으로 감싼다. 새로고침 시 캐시를 비우고 리로드하되
    // 같은 탭으로 돌아온다(위 initState의 복원).
    final edgeOffset = MediaQuery.of(context).padding.top + kToolbarHeight;
    final pages = [
      for (final page in config.pages)
        RefreshIndicator(
          edgeOffset: edgeOffset,
          color: AppColors.pink,
          onRefresh: AppRefresh.refreshKeepingTab,
          child: page,
        ),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: StreamBuilder<bool>(
        stream: context.read<ChatRepository>().watchHasUnread(widget.user.uid),
        builder: (context, snapshot) {
          final hasUnread = snapshot.data ?? false;
          return _BlingBottomBar(
            index: _index,
            items: config.items,
            badgeIndex: hasUnread ? chatIndex : null,
            onTap: _onTab,
          );
        },
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
    this.badgeIndex,
  });

  final int index;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final int? badgeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
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
        minimum: EdgeInsets.only(bottom: 10.h),
        child: Padding(
          padding: EdgeInsets.fromLTRB(6.w, 8.h, 6.w, 4.h),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BarItem(
                    icon: items[i].icon,
                    label: items[i].label,
                    selected: index == i,
                    showBadge: i == badgeIndex,
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
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    // 선택: 포인트 색 / 비선택: 뉴트럴 그레이(토스풍).
    final color = selected ? AppColors.pink : const Color(0xFF8B95A1);
    return BouncyTap(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24.sp, color: color),
                if (showBadge)
                  Positioned(
                    right: -2.w,
                    top: -2.h,
                    child: Container(
                      width: 9.w,
                      height: 9.w,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
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
