import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/history_calendar_view.dart';
import '../../../core/widgets/home_greeting.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
import '../../social/views/notification_bell.dart';
import '../models/exam_plan.dart';
import '../models/exam_result.dart';
import '../repositories/exam_repository.dart';
import 'exam_result_detail_view.dart';
import 'exam_result_widgets.dart';

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
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 8.h, 0, 110.h),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: HomeGreeting(
                name: user.name,
                mascot: '🐥',
                trailing: NotificationBell(user: user),
              ),
            ),
            SizedBox(height: 6.h),
            FriendBar(me: user),
            SizedBox(height: 4.h),
            _SectionTitle(
                icon: Icons.event_available_rounded, label: '다가오는 시험'),
            StreamBuilder<List<ExamPlan>>(
              stream: exam.watchPlansForGuest(user.uid),
              builder: (context, snap) {
                final plans = (snap.data ?? const <ExamPlan>[])
                    .where((p) => !p.done && p.dDay(today) >= 0)
                    .toList();
                if (plans.isEmpty) {
                  return const _EmptyHint(
                      text: '예정된 시험이 없어요.\n언니가 시험을 배정하면 여기에 표시돼요.');
                }
                return Column(
                  children: [
                    for (final plan in plans)
                      _PlanCard(plan: plan, today: today),
                  ],
                );
              },
            ),
            SizedBox(height: 16.h),
            _SectionTitle(icon: Icons.fact_check_rounded, label: '오늘 시험 결과'),
            StreamBuilder<List<ExamResult>>(
              stream: exam.watchResultsForGuest(user.uid),
              builder: (context, snap) {
                final results = snap.data ?? const <ExamResult>[];
                if (results.isEmpty) {
                  return const _EmptyHint(
                      text: '아직 본 시험이 없어요.\n시험을 마치면 점수가 여기에 쌓여요.');
                }
                bool isToday(DateTime? d) {
                  if (d == null) return false;
                  return d.year == today.year &&
                      d.month == today.month &&
                      d.day == today.day;
                }

                Widget tile(ExamResult r) => _ResultCard(
                      result: r,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ExamResultDetailView(result: r))),
                    );
                final todayR =
                    results.where((r) => isToday(r.createdAt)).toList();
                final pastR =
                    results.where((r) => !isToday(r.createdAt)).toList();
                return Column(
                  children: [
                    if (todayR.isEmpty)
                      const _EmptyHint(text: '오늘 본 시험이 없어요.')
                    else
                      for (final r in todayR) tile(r),
                    if (pastR.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 0),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HistoryCalendarView(
                                title: '지난 시험 결과',
                                items: [
                                  for (final r in pastR)
                                    DatedItem(
                                      date: r.createdAt ?? today,
                                      child: _ResultCard(
                                        result: r,
                                        onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    ExamResultDetailView(
                                                        result: r))),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: AppColors.rowBg,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.history_rounded,
                                    size: 18.sp, color: AppColors.grayText),
                                SizedBox(width: 8.w),
                                Text('지난 시험 기록 (${pastR.length})',
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink)),
                                const Spacer(),
                                Icon(Icons.chevron_right,
                                    color: AppColors.hint, size: 20.sp),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.pink),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.rowBg,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
      ),
    );
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: AppColors.softShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text('⏰', style: TextStyle(fontSize: 25.sp)),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  SizedBox(height: 3.h),
                  Text('${formatYmd(plan.scheduledDate)} · ${plan.wordCount}개',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.gray)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: urgent ? AppColors.orange : AppColors.blueSoft,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: urgent ? Colors.white : AppColors.mintDeep)),
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
    final pass = result.percent >= 60;
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
              ScoreRing(
                percent: result.percent,
                accent: pass ? AppColors.mint : AppColors.danger,
                size: 52,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    SizedBox(height: 3.h),
                    Text(
                        '${result.score}/${result.total} 정답${result.createdAt != null ? " · ${formatYmd(result.createdAt!)} 시험" : ""}',
                        style:
                            TextStyle(fontSize: 12.sp, color: AppColors.gray)),
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
