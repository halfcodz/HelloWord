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
import '../models/exam_session.dart';
import '../models/exam_result.dart';
import '../repositories/exam_repository.dart';
import 'exam_result_detail_view.dart';
import 'exam_invite.dart';
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
            child: StreamBuilder<List<ExamSession>>(
              // 언니가 시험을 내면 초대가 여기로 들어와 카드로 쌓인다.
              stream: exam.watchInvitesForGuest(user.uid),
              builder: (context, inviteSnap) {
                final invites = inviteSnap.data ?? const <ExamSession>[];
                return StreamBuilder<List<ExamPlan>>(
                  stream: exam.watchPlansForGuest(user.uid),
                  builder: (context, planSnap) {
                    final plans =
                        (planSnap.data ?? const <ExamPlan>[])
                            .where((p) => !p.done && p.dDay(today) >= 0)
                            .toList()
                          ..sort(
                            (a, b) => a.dDay(today).compareTo(b.dDay(today)),
                          );
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
                            _header(context, next, today),
                            // 인사 바로 아래에 프로필(나·언니) 줄.
                            FriendBar(me: user),
                            SizedBox(height: AppSpace.sm.h),
                            // 숫자 통계 대신 오늘의 한 문장.
                            QuoteCard(),
                            SectionHeader(
                              icon: Icons.event_available_rounded,
                              label: '오늘 시험',
                            ),
                            // 도착한 초대를 맨 위에 눈에 띄게 둔다.
                            for (final invite in invites)
                              _InviteCard(
                                session: invite,
                                onTap: () =>
                                    showExamInvite(context, invite, user),
                              ),
                            if (plans.isEmpty && invites.isEmpty)
                              EmptyState(
                                icon: Icons.event_note_rounded,
                                text: '아직 시험이 없어요.\n언니가 시험을 내면 여기에 바로 표시돼요.',
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ResultNavCard(
                                        icon: Icons.insights_rounded,
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
                                        icon: Icons.history_rounded,
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
                            SizedBox(height: kBottomInset.h),
                          ],
                        );
                      },
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

  /// 홈 헤더. 인사와 오늘 시험 여부만 담백하게 보여 준다.
  Widget _header(BuildContext context, ExamPlan? next, DateTime today) {
    final d = next?.dDay(today);
    return SafeArea(
      bottom: false,
      child: HeroHeader(
        subtitle: _dateLabel(),
        title: '${user.name}, 안녕! 🐥',
        badge: next == null
            ? null
            : (d == 0
                  ? '오늘 시험이 있어요 · ${next.title}'
                  : '${next.title} 시험이 $d일 남았어요'),
        trailing: MaterialBell(user: user),
      ),
    );
  }

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String _dateLabel() {
    final n = DateTime.now();
    return '${n.month}월 ${n.day}일 ${_weekdays[n.weekday - 1]}요일';
  }
}

/// 도착한 시험 초대 카드. 누르면 초대 화면이 열린다.
class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.session, required this.onTap});

  final ExamSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter.w,
        AppSpace.xxs.h,
        AppSpace.gutter.w,
        AppSpace.xs.h,
      ),
      child: AppCard(
        onTap: onTap,
        // 새로 온 초대라는 걸 알 수 있게 포인트 색 테두리를 준다.
        borderColor: AppColors.pink,
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(AppRadius.sm.r),
              ),
              child: Icon(
                Icons.mark_email_unread_rounded,
                size: AppIconSize.md.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: AppSpace.sm.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusChip(label: '새 초대'),
                      SizedBox(width: AppSpace.xxs.w + 2),
                      Expanded(
                        child: Text(
                          '${session.hostName}가 보냈어요',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                            fontSize: 12.sp,
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpace.xxs.h),
                  Text(
                    '${session.title} · ${session.total}문제',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.hint,
              size: AppIconSize.md.sp,
            ),
          ],
        ),
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
