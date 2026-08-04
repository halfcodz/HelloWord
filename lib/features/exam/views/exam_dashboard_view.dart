import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/history_calendar_view.dart';
import '../../../core/widgets/app_components.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
import '../../word_sets/models/word_set.dart';
import '../../word_sets/repositories/word_set_repository.dart';
import '../../word_sets/views/word_set_detail_view.dart';
import '../models/exam_plan.dart';
import '../models/exam_result.dart';
import '../repositories/exam_repository.dart';
import 'exam_result_detail_view.dart';
import 'exam_result_widgets.dart';
import 'result_section.dart';

/// 언니 홈: 시험 관리 대시보드.
/// 예정된 시험(D-DAY)과 동생이 친 지난 시험 결과를 한눈에 정리한다.
class ExamDashboardView extends StatelessWidget {
  const ExamDashboardView({super.key, required this.user});

  final AppUser user;

  ExamRepository _exam(BuildContext c) => c.read<ExamRepository>();
  WordSetRepository _wordSets(BuildContext c) => c.read<WordSetRepository>();

  Future<void> _assignExam(BuildContext context) async {
    final examRepo = _exam(context);
    final wordSetRepo = _wordSets(context);
    final sets = await wordSetRepo.watchByCreator(user.uid).first;
    if (!context.mounted) return;
    if (sets.isEmpty) {
      showToast(context, '먼저 단어 세트를 만들어 주세요. (자료 탭)');
      return;
    }
    final assigned = await showDialog<_Assignment>(
      context: context,
      builder: (_) => _AssignDialog(sets: sets),
    );
    if (assigned == null || !context.mounted) return;
    try {
      await examRepo.createPlan(
        ExamPlan(
          id: '',
          hostUid: user.uid,
          hostName: user.name,
          guestUids: assigned.set.sharedWith,
          wordSetId: assigned.set.id,
          title: assigned.set.title,
          wordCount: assigned.set.wordCount,
          scheduledDate: assigned.date,
        ),
      );
      // 이 자료가 "시험에 배정한 자료"라는 표시를 남긴다(자료 목록·상세에 배지로 보임).
      await wordSetRepo.markExamAssigned(
        id: assigned.set.id,
        scheduledDate: assigned.date,
      );
      if (context.mounted) showToast(context, '시험을 배정했어요! 자료에 배정 표시를 남겼어요.');
    } catch (_) {
      if (context.mounted) {
        showToast(context, '배정에 실패했어요. (examPlans 규칙 확인)', isError: true);
      }
    }
  }

  Future<void> _startExam(BuildContext context, ExamPlan plan) async {
    final set = await _wordSets(context).getById(plan.wordSetId);
    if (!context.mounted) return;
    if (set == null) {
      showToast(context, '단어 세트를 찾을 수 없어요. 삭제되었을 수 있어요.', isError: true);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WordSetDetailView(set: set, user: user),
      ),
    );
  }

  Future<void> _planMenu(BuildContext context, ExamPlan plan) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_fill_rounded),
              title: const Text('이 시험 시작하기'),
              onTap: () => Navigator.of(sheet).pop('start'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('예정 삭제', style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.of(sheet).pop('delete'),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
    if (action == 'start' && context.mounted) {
      await _startExam(context, plan);
    } else if (action == 'delete' && context.mounted) {
      await _exam(context).deletePlan(plan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = _exam(context);
    final today = DateTime.now();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        // 같은 화면 묶음(IndexedStack)에 FAB이 여러 개라 태그를 구분해 준다.
        heroTag: 'fab-assign-exam',
        onPressed: () => _assignExam(context),
        icon: const Icon(Icons.event_note_rounded),
        label: const Text('시험 배정'),
      ),
      // 헤더가 상태바 뒤까지 색을 채우도록 위쪽 SafeArea는 헤더가 직접 처리한다.
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: StreamBuilder<List<ExamPlan>>(
              stream: exam.watchPlansByHost(user.uid),
              builder: (context, planSnap) {
                final allPlans = planSnap.data ?? const <ExamPlan>[];
                final todayPlans = allPlans
                    .where((p) => !p.done && _isToday(p.scheduledDate))
                    .toList();
                final upcoming = allPlans
                    .where((p) => !p.done && p.dDay(today) > 0)
                    .toList();

                return StreamBuilder<List<ExamResult>>(
                  stream: exam.watchResultsByHost(user.uid),
                  builder: (context, resultSnap) {
                    final results = resultSnap.data ?? const <ExamResult>[];
                    final todayR = results
                        .where((r) => _isToday(r.createdAt))
                        .toList();
                    final pastR = results
                        .where((r) => !_isToday(r.createdAt))
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(context, todayPlans, upcoming, results),
                        SizedBox(height: AppSpace.md.h),
                        FriendBar(me: user),
                        SectionHeader(
                          icon: Icons.event_available_rounded,
                          label: '오늘 시험',
                          actionLabel: todayPlans.isEmpty ? null : '시험 배정',
                          onAction: todayPlans.isEmpty
                              ? null
                              : () => _assignExam(context),
                        ),
                        if (todayPlans.isEmpty)
                          EmptyState(
                            icon: Icons.event_note_rounded,
                            text: '오늘 예정된 시험이 없어요.\n동생에게 시험을 내볼까요?',
                            actionLabel: '시험 배정하기',
                            onAction: () => _assignExam(context),
                          )
                        else
                          for (final plan in todayPlans)
                            _PlanCard(
                              plan: plan,
                              today: today,
                              onTap: () => _planMenu(context, plan),
                            ),
                        if (upcoming.isNotEmpty) ...[
                          SectionHeader(
                            icon: Icons.upcoming_rounded,
                            label: '다가오는 시험',
                          ),
                          SizedBox(
                            height: 104.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpace.gutter.w,
                              ),
                              itemCount: upcoming.length,
                              separatorBuilder: (_, _) =>
                                  SizedBox(width: AppSpace.sm.w),
                              itemBuilder: (context, i) => _UpcomingCard(
                                plan: upcoming[i],
                                today: today,
                                onTap: () => _planMenu(context, upcoming[i]),
                              ),
                            ),
                          ),
                        ],
                        SectionHeader(
                          icon: Icons.fact_check_rounded,
                          label: '시험 결과',
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpace.gutter.w,
                          ),
                          // 두 카드의 높이를 맞추려고 stretch를 쓰는데, 스크롤 안에서는
                          // 높이가 무한이라 stretch가 그대로 터진다(화면이 안 그려짐).
                          // IntrinsicHeight로 '가장 큰 카드 높이'를 정해 준 뒤 늘린다.
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ResultNavCard(
                                    emoji: '📊',
                                    label: '오늘 시험 결과',
                                    count: todayR.length,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TodayResultsView(
                                          results: todayR,
                                          emptyText:
                                              '오늘 채점된 시험이 없어요.\n동생이 시험을 마치면 여기에 나와요.',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: AppSpace.sm.w),
                                Expanded(
                                  child: ResultNavCard(
                                    emoji: '🗓️',
                                    label: '지난 시험 결과',
                                    count: pastR.length,
                                    dark: true,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => HistoryCalendarView(
                                          title: '지난 시험 결과',
                                          items: [
                                            for (final r in pastR)
                                              DatedItem(
                                                date:
                                                    r.createdAt ??
                                                    DateTime.now(),
                                                child: _ResultCard(
                                                  result: r,
                                                  onTap: () =>
                                                      _openResult(context, r),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 92.h),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 홈 맨 위 헤더. 오늘 할 일과 성적을 숫자로 먼저 보여 준다.
  Widget _header(
    BuildContext context,
    List<ExamPlan> todayPlans,
    List<ExamPlan> upcoming,
    List<ExamResult> results,
  ) {
    final average = results.isEmpty
        ? '-'
        : '${(results.map((r) => r.total == 0 ? 0.0 : r.score / r.total * 100).reduce((a, b) => a + b) / results.length).round()}점';
    return SafeArea(
      bottom: false,
      child: HeroHeader(
        subtitle: _dateLabel(),
        title: '${user.name}, 안녕! 🐰',
        badge: todayPlans.isEmpty
            ? '오늘은 예정된 시험이 없어요'
            : '오늘 시험 ${todayPlans.length}개가 있어요',
        stats: [
          HeroStat(
            icon: Icons.today_rounded,
            value: '${todayPlans.length}',
            label: '오늘 시험',
          ),
          HeroStat(
            icon: Icons.calendar_month_rounded,
            value: '${upcoming.length}',
            label: '예정된 시험',
          ),
          HeroStat(
            icon: Icons.emoji_events_rounded,
            value: average,
            label: '평균 점수',
          ),
        ],
      ),
    );
  }

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String _dateLabel() {
    final n = DateTime.now();
    return '${n.month}월 ${n.day}일 ${_weekdays[n.weekday - 1]}요일';
  }

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  void _openResult(BuildContext context, ExamResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExamResultDetailView(result: result)),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.today,
    required this.onTap,
  });

  final ExamPlan plan;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = plan.dDay(today);
    final label = d == 0 ? 'D-DAY' : (d > 0 ? 'D-$d' : 'D+${-d}');
    final urgent = d <= 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter.w,
        AppSpace.xxs.h,
        AppSpace.gutter.w,
        AppSpace.xs.h,
      ),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.md.w,
                AppSpace.md.h,
                AppSpace.sm.w,
                AppSpace.sm.h,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: urgent ? AppColors.pink : AppColors.pinkSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm.r),
                    ),
                    child: Text(
                      label,
                      style: AppTheme.font(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: urgent ? Colors.white : AppColors.mintDeep,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpace.sm.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.display(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: AppSpace.xxs.h),
                        Row(
                          children: [
                            StatusChip(
                              icon: Icons.style_rounded,
                              label: '${plan.wordCount}단어',
                            ),
                            SizedBox(width: AppSpace.xxs.w + 2),
                            Text(
                              formatYmd(plan.scheduledDate),
                              style: AppTheme.font(
                                fontSize: 12.sp,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    color: AppColors.hint,
                    size: AppIconSize.md.sp,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            // 카드 안에서 바로 시작할 수 있게 큰 동작 버튼을 붙인다.
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.lg.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.sm.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      size: AppIconSize.sm.sp,
                      color: AppColors.pink,
                    ),
                    SizedBox(width: AppSpace.xxs.w + 2),
                    Text(
                      '이 시험 시작하기',
                      style: AppTheme.font(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 다가오는 시험을 가로로 넘겨 보는 작은 카드.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.plan,
    required this.today,
    required this.onTap,
  });

  final ExamPlan plan;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = plan.dDay(today);
    return SizedBox(
      width: 168.w,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.all(AppSpace.sm.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatusChip(
              label: 'D-$d',
              color: AppColors.gold,
              background: AppColors.goldSoft,
            ),
            Text(
              plan.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.display(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            Text(
              '${formatYmd(plan.scheduledDate)} · ${plan.wordCount}단어',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.font(fontSize: 11.sp, color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onTap});

  final ExamResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: AppColors.softShadow(),
          ),
          child: Row(
            children: [
              ResultEmojiBadge(percent: result.percent, size: 52),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '${result.guestName.isEmpty ? "동생" : result.guestName} · ${result.percent}점 · ${result.score}/${result.total} 정답${result.createdAt != null ? " · ${formatYmd(result.createdAt!)}" : ""}',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.hint, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}

/// 시험 배정 결과(단어 세트 + 예정일).
class _Assignment {
  const _Assignment(this.set, this.date);
  final WordSet set;
  final DateTime date;
}

class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.sets});

  final List<WordSet> sets;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  late WordSet _set = widget.sets.first;
  DateTime _date = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('시험 배정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '단어 세트',
            style: TextStyle(fontSize: 13.sp, color: AppColors.gray),
          ),
          SizedBox(height: 6.h),
          DropdownButton<WordSet>(
            value: _set,
            isExpanded: true,
            items: [
              for (final s in widget.sets)
                DropdownMenuItem(
                  value: s,
                  // 이미 시험에 배정한 자료는 한눈에 보이게 표시한다.
                  child: Text(
                    '${s.title} (${s.wordCount}개)'
                    '${s.examAssigned ? " · 배정됨" : ""}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _set = v ?? _set),
          ),
          SizedBox(height: 12.h),
          Text(
            '예정일',
            style: TextStyle(fontSize: 13.sp, color: AppColors.gray),
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18.sp,
                    color: AppColors.pink,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    formatYmd(_date),
                    style: TextStyle(fontSize: 14.sp, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_Assignment(_set, _date)),
          child: const Text('배정'),
        ),
      ],
    );
  }
}
