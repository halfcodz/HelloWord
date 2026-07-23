import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../core/services/presence_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/app_refresh.dart';
import '../core/widgets/bouncy_tap.dart';
import '../features/exam/models/exam_session.dart';
import '../features/exam/repositories/exam_repository.dart';
import '../features/exam/views/exam_dashboard_view.dart';
import '../features/exam/views/exam_schedule_view.dart';
import '../features/exam/views/session_exam_view.dart';
import '../features/exam/views/session_join_view.dart';
import '../features/exam/views/session_monitor_view.dart';
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
    _reconnectIfNeeded();
  }

  /// 앱 시작(재접속) 시 진행 중인 시험이 있으면 자동으로 다시 들어간다.
  Future<void> _reconnectIfNeeded() async {
    final repo = context.read<ExamRepository>();
    final elder = widget.user.role == UserRole.elder;
    final session = elder
        ? await repo.watchMyActiveExamAsHost(widget.user.uid).first
        : await repo.watchMyActiveExamAsGuest(widget.user.uid).first;
    if (session == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => elder
          ? SessionMonitorView(sessionId: session.id)
          : SessionExamView(sessionId: session.id, user: widget.user),
    ));
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
          ProfileView(user: user),
        ],
        items: const [
          _NavItem(Icons.home_rounded, '홈'),
          _NavItem(Icons.folder_rounded, '자료'),
          _NavItem(Icons.person_rounded, '내 정보'),
        ],
      );
    }
    return (
      pages: [
        ExamScheduleView(user: user),
        StudyListView(user: user),
        SessionJoinView(user: user),
        ProfileView(user: user),
      ],
      items: const [
        _NavItem(Icons.home_rounded, '홈'),
        _NavItem(Icons.menu_book_rounded, '공부'),
        _NavItem(Icons.quiz_rounded, '시험'),
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
    // 동생이면 어느 탭에서든 시험 초대가 오면 팝업으로 알린다.
    Widget body = IndexedStack(index: _index, children: pages);
    if (widget.user.role == UserRole.younger) {
      body = _InviteWatcher(user: widget.user, child: body);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
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
    // 말해보카풍: 하단 중앙에 떠 있는 네이비 필 탭바(아이콘 전용).
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: 14.h, top: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(999.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++)
                  _BarItem(
                    icon: items[i].icon,
                    selected: index == i,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56.w,
        height: 46.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.mint : Colors.transparent,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Icon(icon,
            size: 23.sp,
            color: selected ? Colors.white : const Color(0xFF5D6580)),
      ),
    );
  }
}

/// 동생 화면 전역: 언니가 보낸 시험 초대가 오면 팝업으로 승인/거절을 받는다.
class _InviteWatcher extends StatefulWidget {
  const _InviteWatcher({required this.user, required this.child});

  final AppUser user;
  final Widget child;

  @override
  State<_InviteWatcher> createState() => _InviteWatcherState();
}

class _InviteWatcherState extends State<_InviteWatcher>
    with WidgetsBindingObserver {
  StreamSubscription<List<ExamSession>>? _sub;
  final _handled = <String>{};
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = context
        .read<ExamRepository>()
        .watchInvitesForGuest(widget.user.uid)
        .listen(_onInvites);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 앞으로 오면(백그라운드 중 온 초대) 새로고침 없이 바로 확인한다.
    if (state == AppLifecycleState.resumed && mounted) {
      context
          .read<ExamRepository>()
          .watchInvitesForGuest(widget.user.uid)
          .first
          .then(_onInvites)
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  void _onInvites(List<ExamSession> invites) {
    if (_dialogOpen || !mounted) return;
    ExamSession? fresh;
    for (final s in invites) {
      if (!_handled.contains(s.id)) {
        fresh = s;
        break;
      }
    }
    if (fresh == null) return;
    _handled.add(fresh.id);
    _showInvite(fresh);
  }

  Future<void> _showInvite(ExamSession s) async {
    _dialogOpen = true;
    final choice = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '시험 초대',
      barrierColor: AppColors.navy.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) => _InviteFullCard(session: s),
      transitionBuilder: (context, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child),
        );
      },
    );
    _dialogOpen = false;
    if (!mounted) return;
    final repo = context.read<ExamRepository>();
    if (choice == true) {
      await repo.joinSession(
        sessionId: s.id,
        guestUid: widget.user.uid,
        guestName: widget.user.name,
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SessionExamView(sessionId: s.id, user: widget.user),
      ));
    } else if (choice == false) {
      await repo.declineInvite(s.id);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 시험 초대 전면 카드(말해보카풍 · 네이비 배경 + 바운스 마스코트).
class _InviteFullCard extends StatelessWidget {
  const _InviteFullCard({required this.session});

  final ExamSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 110.w,
                height: 110.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mintEnd, width: 4),
                ),
                child: Text('🐰', style: TextStyle(fontSize: 54.sp)),
              ),
              SizedBox(height: 22.h),
              Text('언니가 시험에\n초대했어요! 📩',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 23.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              SizedBox(height: 10.h),
              Text('${session.title} · ${session.total}문제 · 영상통화',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onNavy)),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButton,
                    borderRadius: BorderRadius.circular(999.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mint.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text('수락하고 시작하기',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 1.5),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text('지금은 어려워요',
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onNavy)),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
