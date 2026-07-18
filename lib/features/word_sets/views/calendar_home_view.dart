import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
import '../models/word_set.dart';
import '../repositories/word_set_repository.dart';
import '../viewmodels/word_set_list_viewmodel.dart';
import 'word_set_detail_view.dart';
import 'word_set_upload_view.dart';

/// 언니 홈: 상단 친구 바 + 노션풍 월 달력(단어 세트를 날짜별 바로 표시).
class CalendarHomeView extends StatelessWidget {
  const CalendarHomeView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WordSetListViewModel(
        repository: context.read<WordSetRepository>(),
        uid: user.uid,
      ),
      child: _CalendarBody(user: user),
    );
  }
}

class _CalendarBody extends StatefulWidget {
  const _CalendarBody({required this.user});

  final AppUser user;

  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<WordSet>> _groupByDay(List<WordSet> sets) {
    final map = <DateTime, List<WordSet>>{};
    for (final set in sets) {
      map.putIfAbsent(_dayKey(set.date), () => []).add(set);
    }
    return map;
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));
  void _today() {
    final now = DateTime.now();
    setState(() => _month = DateTime(now.year, now.month));
  }

  void _openDay(DateTime day, List<WordSet> sets) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => _DaySheet(
        day: day,
        sets: sets,
        onOpenSet: (set) {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WordSetDetailView(set: set, user: widget.user),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordSetListViewModel>();
    final events = _groupByDay(viewModel.sets);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WordSetUploadView(user: widget.user),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('단어 추가'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FriendBar(me: widget.user),
            _MonthHeader(
              month: _month,
              onPrev: _prevMonth,
              onNext: _nextMonth,
              onToday: _today,
            ),
            const _WeekdayRow(),
            Expanded(
              child: viewModel.loading
                  ? const Center(child: CircularProgressIndicator())
                  : _MonthGrid(
                      month: _month,
                      eventsByDay: events,
                      onDayTap: (day) =>
                          _openDay(day, events[_dayKey(day)] ?? const []),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 12.w, 4.h),
      child: Row(
        children: [
          Text('${month.year}년 ${month.month}월',
              style: TextStyle(fontSize: 20.sp, color: AppColors.ink)),
          const Spacer(),
          BouncyTap(
            onTap: onToday,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.pinkSoft.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text('오늘',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.pink)),
            ),
          ),
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, color: AppColors.lavender),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: AppColors.lavender),
          ),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  static const _days = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  _days[i],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: i == 0 ? AppColors.pink : AppColors.lavender,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.eventsByDay,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<DateTime, List<WordSet>> eventsByDay;
  final void Function(DateTime) onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leading = firstOfMonth.weekday % 7; // 일요일 시작
    final gridStart = firstOfMonth.subtract(Duration(days: leading));
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final weeks = ((leading + lastOfMonth.day) / 7).ceil();
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        children: [
          for (var w = 0; w < weeks; w++)
            Expanded(
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Builder(builder: (context) {
                      final date = gridStart.add(Duration(days: w * 7 + d));
                      final key = DateTime(date.year, date.month, date.day);
                      return Expanded(
                        child: _DayCell(
                          date: date,
                          inMonth: date.month == month.month,
                          isToday: key == today,
                          isSunday: d == 0,
                          events: eventsByDay[key] ?? const [],
                          onTap: () => onDayTap(date),
                        ),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.isToday,
    required this.isSunday,
    required this.events,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool isToday;
  final bool isSunday;
  final List<WordSet> events;
  final VoidCallback onTap;

  static const _pillColors = [
    Color(0xFFFFB3C6),
    Color(0xFFC4B0F0),
    Color(0xFF9FE0C9),
    Color(0xFFFFCE9E),
  ];

  @override
  Widget build(BuildContext context) {
    final dayColor = !inMonth
        ? AppColors.ink.withValues(alpha: 0.25)
        : isSunday
            ? AppColors.pink
            : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.all(2.w),
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: inMonth ? 0.55 : 0.2),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 22.w,
                height: 22.w,
                alignment: Alignment.center,
                decoration: isToday
                    ? const BoxDecoration(
                        gradient: AppColors.primaryButton,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isToday ? Colors.white : dayColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            for (var i = 0; i < events.length && i < 2; i++)
              _EventPill(
                title: events[i].title,
                color: _pillColors[i % _pillColors.length],
              ),
            if (events.length > 2)
              Padding(
                padding: EdgeInsets.only(top: 1.h, left: 2.w),
                child: Text('+${events.length - 2}',
                    style: TextStyle(
                        fontSize: 9.sp, color: AppColors.lavender)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventPill extends StatelessWidget {
  const _EventPill({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: TextStyle(fontSize: 9.sp, color: Colors.white),
      ),
    );
  }
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({
    required this.day,
    required this.sets,
    required this.onOpenSet,
  });

  final DateTime day;
  final List<WordSet> sets;
  final void Function(WordSet) onOpenSet;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.lavenderSoft,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('${day.month}월 ${day.day}일',
                style: TextStyle(fontSize: 18.sp, color: AppColors.ink)),
            SizedBox(height: 12.h),
            if (sets.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: Text('이 날은 등록된 단어가 없어요 🌷',
                      style: TextStyle(
                          fontSize: 13.sp, color: AppColors.lavender)),
                ),
              )
            else
              ...sets.map(
                (set) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: BouncyTap(
                    onTap: () => onOpenSet(set),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: AppColors.softShadow(blur: 12, y: 5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryButton,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                color: Colors.white, size: 20.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(set.title,
                                    style: TextStyle(
                                        fontSize: 15.sp,
                                        color: AppColors.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text('${set.wordCount}개 단어',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.lavender)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.lavender, size: 20.sp),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
