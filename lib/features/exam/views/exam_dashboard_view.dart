import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/history_calendar_view.dart';
import '../../../core/widgets/home_greeting.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
import '../../social/views/notification_bell.dart';
import '../../word_sets/models/word_set.dart';
import '../../word_sets/repositories/word_set_repository.dart';
import '../../word_sets/views/word_set_detail_view.dart';
import '../models/exam_plan.dart';
import '../models/exam_result.dart';
import '../repositories/exam_repository.dart';
import 'exam_result_detail_view.dart';
import 'exam_result_widgets.dart';

/// 언니 홈: 시험 관리 대시보드.
/// 예정된 시험(D-DAY)과 동생이 친 지난 시험 결과를 한눈에 정리한다.
class ExamDashboardView extends StatelessWidget {
  const ExamDashboardView({super.key, required this.user});

  final AppUser user;

  ExamRepository _exam(BuildContext c) => c.read<ExamRepository>();
  WordSetRepository _wordSets(BuildContext c) => c.read<WordSetRepository>();

  Future<void> _assignExam(BuildContext context) async {
    final sets = await _wordSets(context).watchByCreator(user.uid).first;
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
      await _exam(context).createPlan(ExamPlan(
        id: '',
        hostUid: user.uid,
        hostName: user.name,
        guestUids: assigned.set.sharedWith,
        wordSetId: assigned.set.id,
        title: assigned.set.title,
        wordCount: assigned.set.wordCount,
        scheduledDate: assigned.date,
      ));
      if (context.mounted) showToast(context, '시험을 배정했어요!');
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WordSetDetailView(set: set, user: user),
    ));
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
        onPressed: () => _assignExam(context),
        icon: const Icon(Icons.event_note_rounded),
        label: const Text('시험 배정'),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 8.h, 0, 120.h),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: HomeGreeting(
                name: user.name,
                mascot: '🐰',
                subtitle: '우리 동생 관리하기',
                trailing: NotificationBell(user: user),
              ),
            ),
            SizedBox(height: 6.h),
            FriendBar(me: user),
            SizedBox(height: 4.h),
            _SectionTitle(icon: Icons.event_available_rounded, label: '예정된 시험'),
            StreamBuilder<List<ExamPlan>>(
              stream: exam.watchPlansByHost(user.uid),
              builder: (context, snap) {
                final plans = (snap.data ?? const <ExamPlan>[])
                    .where((p) => !p.done)
                    .toList();
                if (plans.isEmpty) {
                  return const _EmptyHint(
                      text: '예정된 시험이 없어요.\n아래 "시험 배정"으로 추가해요.');
                }
                return Column(
                  children: [
                    for (final plan in plans)
                      _PlanCard(
                        plan: plan,
                        today: today,
                        onTap: () => _planMenu(context, plan),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 16.h),
            _SectionTitle(
                icon: Icons.fact_check_rounded, label: '오늘 시험 결과'),
            StreamBuilder<List<ExamResult>>(
              stream: exam.watchResultsByHost(user.uid),
              builder: (context, snap) {
                final results = snap.data ?? const <ExamResult>[];
                final today =
                    results.where((r) => _isToday(r.createdAt)).toList();
                final past =
                    results.where((r) => !_isToday(r.createdAt)).toList();
                return Column(
                  children: [
                    if (today.isEmpty)
                      const _EmptyHint(text: '오늘 채점된 시험이 없어요.')
                    else
                      for (final result in today)
                        _ResultCard(
                          result: result,
                          onTap: () => _openResult(context, result),
                        ),
                    if (past.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 0),
                        child: HistoryEntryButton(
                          title: '지난 시험 결과',
                          count: past.length,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HistoryCalendarView(
                                title: '지난 시험 결과',
                                items: [
                                  for (final r in past)
                                    DatedItem(
                                      date: r.createdAt ?? DateTime.now(),
                                      child: _ResultCard(
                                        result: r,
                                        onTap: () => _openResult(context, r),
                                      ),
                                    ),
                                ],
                              ),
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

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  void _openResult(BuildContext context, ExamResult result) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExamResultDetailView(result: result)));
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
  const _PlanCard({required this.plan, required this.today, required this.onTap});

  final ExamPlan plan;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = plan.dDay(today);
    final label = d == 0 ? 'D-DAY' : (d > 0 ? 'D-$d' : 'D+${-d}');
    final urgent = d <= 0;
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
                        style:
                            TextStyle(fontSize: 12.sp, color: AppColors.gray)),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: AppColors.hint, size: 20.sp),
            ],
          ),
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
                        '${result.guestName.isEmpty ? "동생" : result.guestName} · ${result.score}/${result.total} 정답${result.createdAt != null ? " · ${formatYmd(result.createdAt!)}" : ""}',
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
          Text('단어 세트', style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
          SizedBox(height: 6.h),
          DropdownButton<WordSet>(
            value: _set,
            isExpanded: true,
            items: [
              for (final s in widget.sets)
                DropdownMenuItem(
                  value: s,
                  child: Text('${s.title} (${s.wordCount}개)',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _set = v ?? _set),
          ),
          SizedBox(height: 12.h),
          Text('예정일', style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
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
                  Icon(Icons.calendar_today_outlined,
                      size: 18.sp, color: AppColors.pink),
                  SizedBox(width: 8.w),
                  Text(formatYmd(_date),
                      style: TextStyle(fontSize: 14.sp, color: AppColors.ink)),
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
          onPressed: () =>
              Navigator.of(context).pop(_Assignment(_set, _date)),
          child: const Text('배정'),
        ),
      ],
    );
  }
}
