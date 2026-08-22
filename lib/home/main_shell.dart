import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../core/services/presence_service.dart';
import '../core/services/version_watcher.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/app_refresh.dart';
import '../core/widgets/bouncy_tap.dart';
import '../core/widgets/update_banner.dart';
import '../features/exam/repositories/exam_repository.dart';
import '../features/exam/views/exam_dashboard_view.dart';
import '../features/exam/views/exam_schedule_view.dart';
import '../features/exam/views/session_exam_view.dart';
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

  /// 한 번이라도 열어 본 탭. IndexedStack은 자식을 전부 만들기 때문에
  /// 그냥 두면 보지도 않는 탭의 Firestore 구독까지 함께 열린다
  /// (무료 사용량을 그만큼 더 쓴다). 그래서 처음 연 탭만 만들고,
  /// 한 번 만든 탭은 그대로 두어 스크롤 위치와 상태를 지킨다.
  final Set<int> _visited = {0};

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => elder
            ? SessionMonitorView(sessionId: session.id)
            : SessionExamView(sessionId: session.id, user: widget.user),
      ),
    );
  }

  /// 새로고침(리로드) 직후라면 보던 탭으로 복원한다.
  Future<void> _restoreTabAfterReload() async {
    final tab = await AppRefresh.consumeRestoreTab();
    if (tab == null || !mounted) return;
    setState(() {
      _index = tab;
      _visited.add(tab);
    });
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
        ProfileView(user: user),
      ],
      items: const [
        _NavItem(Icons.home_rounded, '홈'),
        _NavItem(Icons.menu_book_rounded, '공부'),
        _NavItem(Icons.person_rounded, '내 정보'),
      ],
    );
  }

  /// 동생이 '공부' 탭(index 1)에 있을 때만 공부중 상태를 켠다.
  void _updateStudying() {
    final studying = widget.user.role == UserRole.younger && _index == 1;
    _presence.setStudying(studying);
  }

  void _onTab(int i) {
    setState(() {
      _index = i;
      _visited.add(i);
    });
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
      for (var i = 0; i < config.pages.length; i++)
        if (_visited.contains(i))
          RefreshIndicator(
            edgeOffset: edgeOffset,
            color: AppColors.pink,
            onRefresh: AppRefresh.refreshKeepingTab,
            child: config.pages[i],
          )
        else
          // 아직 안 열어 본 탭은 만들지 않는다(구독도 열리지 않는다).
          const SizedBox.shrink(),
    ];
    // 시험 초대는 팝업으로 튀어나오지 않고 동생 홈의 '오늘 시험'에 쌓인다.
    final Widget body = IndexedStack(index: _index, children: pages);

    // 새 버전이 있으면 맨 위에 띠를 얹는다. 띠가 상태바 자리를 대신 맡으므로
    // 아래 화면들이 상태바 여백을 한 번 더 넣지 않도록 걷어 낸다.
    final showUpdate = context.watch<VersionWatcher>().updateAvailable;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: showUpdate
          ? Column(
              children: [
                const UpdateBanner(),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: body,
                  ),
                ),
              ],
            )
          : body,
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
    // 학습 앱 표준: 아이콘 + 글자 라벨을 함께 둔 하단 탭바.
    // (아이콘만 있으면 무슨 탭인지 알기 어렵고 스크린리더도 읽어 주지 못한다.)
    //
    // 배경은 불투명하게 채운다. 예전에는 반투명 + 뒤 흐리기(BackdropFilter)를
    // 썼는데, 탭바가 모든 화면에 항상 떠 있는 데다 뒤에서 배경이 움직이므로
    // 매 프레임 화면 아래쪽을 통째로 다시 흐려야 했다. 아이폰 사파리에서는
    // 이 비용이 커서 화면이 버벅이고 터치까지 씹혔다.
    //
    // 홈 인디케이터 쪽으로 너무 내려가지 않게 아래 여백을 조금 줄이고
    // 대신 탭 자체를 키워 누르기 편하게 했다.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: 4.h),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 4.h),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BarItem(
                    item: items[i],
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
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.pink : AppColors.gray;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: BouncyTap(
        onTap: onTap,
        // 최소 터치 영역은 확보하되, 글자 크기 설정을 키워도 잘리지 않도록
        // 고정 높이가 아니라 '최소 높이 + 내용에 맞춤'으로 둔다.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 60.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 선택 표시는 색과 옅은 배경 두 가지로 준다(색만으로 구분하지 않기).
              AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.enter,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: selected ? AppColors.pinkSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                ),
                child: Icon(item.icon, size: 24.sp, color: color),
              ),
              SizedBox(height: 3.h),
              Text(
                item.label,
                style: AppTheme.font(
                  fontSize: 12.sp,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
