import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/history_calendar_view.dart';
import '../../../core/widgets/app_components.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
import '../../social/views/material_bell.dart';
import '../models/exam_plan.dart';
import '../models/exam_result.dart';
import '../repositories/exam_repository.dart';
import 'exam_result_detail_view.dart';
import 'exam_result_widgets.dart';
import 'result_section.dart';

/// 동생 홈: 언니가 만든 시험 일정과 내 시험 결과를 '조회만' 하는 화면.
/// 편집(배정·삭제)은 언니만 가능하다.
class ExamScheduleView extends StatelessWidget {
  const ExamScheduleView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final exam = context.read<ExamRepository>();
    final today = DateTime.now();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: StreamBuilder<List<ExamPlan>>(
              stream: exam.watchPlansForGuest(user.uid),
              builder: (context, planSnap) {
                final plans =
                    (planSnap.data ?? const <ExamPlan>[])
                        .where((p) => !p.done && p.dDay(today) >= 0)
                        .toList()
                      ..sort((a, b) => a.dDay(today).compareTo(b.dDay(today)));
                final next = plans.isEmpty ? null : plans.first;

                return StreamBuilder<List<ExamResult>>(
                  stream: exam.watchResultsForGuest(user.uid),
                  builder: (context, resultSnap) {
                    final results = resultSnap.data ?? const <ExamResult>[];
                    bool isToday(DateTime? d) {
                      if (d == null) return false;
                      return d.year == today.year &&
                          d.month == today.month &&
                          d.day == today.day;
                    }

                    final todayR = results
                        .where((r) => isToday(r.createdAt))
                        .toList();
                    final pastR = results
                        .where((r) => !isToday(r.createdAt))
                        .toList();
                    _ResultCard resultTile(ExamResult r) => _ResultCard(
                      result: r,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExamResultDetailView(result: r),
                        ),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(context, next, plans, results, today),
                        SizedBox(height: AppSpace.md.h),
                        FriendBar(me: user),
                        SectionHeader(
                          icon: Icons.event_available_rounded,
                          label: '다가오는 시험',
                        ),
                        if (plans.isEmpty)
                          const EmptyState(
                            icon: Icons.event_note_rounded,
                            text: '예정된 시험이 없어요.\n언니가 시험을 내면 여기에 표시돼요.',
                          )
                        else
                          for (final plan in plans)
                            _PlanCard(plan: plan, today: today),
                        SectionHeader(
                          icon: Icons.fact_check_rounded,
                          label: '내 시험 결과',
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
                                              '오늘 본 시험이 없어요.\n시험을 마치면 여기에 나와요.',
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
                                                date: r.createdAt ?? today,
                                                child: resultTile(r),
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
                        SizedBox(height: AppSpace.xl.h),
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

  /// 홈 헤더. 가장 가까운 시험까지 며칠 남았는지를 가장 크게 보여 준다.
  Widget _header(
    BuildContext context,
    ExamPlan? next,
    List<ExamPlan> plans,
    List<ExamResult> results,
    DateTime today,
  ) {
    final best = results.isEmpty
        ? '-'
        : '${results.map((r) => r.total == 0 ? 0 : (r.score / r.total * 100).round()).reduce((a, b) => a > b ? a : b)}점';
    final d = next?.dDay(today);
    return SafeArea(
      bottom: false,
      child: HeroHeader(
        subtitle: _dateLabel(),
        title: '${user.name}, 안녕! 🐥',
        badge: next == null
            ? '예정된 시험이 없어요. 오늘도 단어 공부해요!'
            : (d == 0
                  ? '오늘이 시험날이에요! "${next.title}"'
                  : '"${next.title}" 시험이 $d일 남았어요'),
        trailing: MaterialBell(user: user),
        stats: [
          HeroStat(
            icon: Icons.hourglass_bottom_rounded,
            value: next == null ? '-' : (d == 0 ? 'D-DAY' : 'D-$d'),
            label: '다음 시험',
          ),
          HeroStat(
            icon: Icons.checklist_rounded,
            value: '${results.length}',
            label: '본 시험',
          ),
          HeroStat(icon: Icons.star_rounded, value: best, label: '최고 점수'),
        ],
      ),
    );
  }

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String _dateLabel() {
    final n = DateTime.now();
    return '${n.month}월 ${n.day}일 ${_weekdays[n.weekday - 1]}요일';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.today});

  final ExamPlan plan;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final d = plan.dDay(today);
    final label = d == 0 ? 'D-DAY' : 'D-$d';
    final urgent = d <= 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter.w,
        AppSpace.xxs.h,
        AppSpace.gutter.w,
        AppSpace.xs.h,
      ),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: urgent ? AppColors.gold : AppColors.goldSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm.r),
              ),
              child: Icon(
                Icons.alarm_rounded,
                size: AppIconSize.md.sp,
                color: urgent ? Colors.white : AppColors.gold,
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
                  Text(
                    '${formatYmd(plan.scheduledDate)} · ${plan.wordCount}단어',
                    style: AppTheme.font(
                      fontSize: 12.sp,
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpace.xs.w),
            StatusChip(
              label: label,
              color: urgent ? Colors.white : AppColors.gold,
              background: urgent ? AppColors.gold : AppColors.goldSoft,
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
                      '${result.percent}점 · ${result.score}/${result.total} 정답${result.createdAt != null ? " · ${formatYmd(result.createdAt!)}" : ""}',
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
