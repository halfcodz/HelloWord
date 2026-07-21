import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_refresh.dart';
import '../../../core/utils/date_format.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
import '../../social/views/notification_bell.dart';
import '../models/exam_plan.dart';
import '../models/exam_result.dart';
import '../repositories/exam_repository.dart';
import 'exam_result_detail_view.dart';

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
      appBar: AppBar(
        title: const Text('시험 일정'),
        actions: [
          NotificationBell(user: user),
          IconButton(
            tooltip: '새로고침',
            onPressed: AppRefresh.refreshKeepingTab,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: 24.h),
          children: [
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
            _SectionTitle(icon: Icons.fact_check_rounded, label: '내 시험 결과'),
            StreamBuilder<List<ExamResult>>(
              stream: exam.watchResultsForGuest(user.uid),
              builder: (context, snap) {
                final results = snap.data ?? const <ExamResult>[];
                if (results.isEmpty) {
                  return const _EmptyHint(
                      text: '아직 본 시험이 없어요.\n시험을 마치면 점수가 여기에 쌓여요.');
                }
                return Column(
                  children: [
                    for (final result in results)
                      _ResultCard(
                        result: result,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ExamResultDetailView(result: result),
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
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: urgent ? AppColors.pink : AppColors.blueSoft,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: urgent ? Colors.white : AppColors.pink)),
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  SizedBox(height: 3.h),
                  Text('${formatYmd(plan.scheduledDate)} · ${plan.wordCount}개',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.gray)),
                ],
              ),
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
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pass ? AppColors.greenSoft : AppColors.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Text('${result.percent}점',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: pass ? AppColors.green : AppColors.danger)),
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
                    Text('${result.score}/${result.total} 정답',
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
