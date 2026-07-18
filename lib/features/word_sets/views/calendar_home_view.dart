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

/// 언니 홈: 상단 친구 바 + 컴팩트한 노션풍 월 달력.
/// 날짜를 누르면 아래에 그 날의 단어 세트가 표시된다.
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
  final _now = DateTime.now();
  late DateTime _month = DateTime(_now.year, _now.month);
  late DateTime _selectedDay = DateTime(_now.year, _now.month, _now.day);

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
  void _today() => setState(() {
        _month = DateTime(_now.year, _now.month);
        _selectedDay = DateTime(_now.year, _now.month, _now.day);
      });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordSetListViewModel>();
    final events = _groupByDay(viewModel.sets);
    final selectedSets = events[_dayKey(_selectedDay)] ?? const <WordSet>[];

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
            _MonthGrid(
              month: _month,
              selectedDay: _selectedDay,
              today: DateTime(_now.year, _now.month, _now.day),
              eventsByDay: events,
              onDayTap: (day) => setState(() => _selectedDay = day),
            ),
            Divider(height: 20.h, thickness: 1, indent: 20.w, endIndent: 20.w),
            _SelectedDayHeader(day: _selectedDay, count: selectedSets.length),
            SizedBox(height: 8.h),
            Expanded(
              child: viewModel.loading
                  ? const Center(child: CircularProgressIndicator())
                  : _DaySetList(
                      sets: selectedSets,
                      onOpenSet: (set) => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordSetDetailView(
                            set: set,
                            user: widget.user,
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
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 8.w, 0),
      child: Row(
        children: [
          Text('${month.year}년 ${month.month}월',
              style: TextStyle(fontSize: 19.sp, color: AppColors.ink)),
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
            visualDensity: VisualDensity.compact,
            onPressed: onPrev,
            icon: Icon(Icons.chevron_left, color: AppColors.lavender),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onNext,
            icon: Icon(Icons.chevron_right, color: AppColors.lavender),
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
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
    required this.selectedDay,
    required this.today,
    required this.eventsByDay,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTime selectedDay;
  final DateTime today;
  final Map<DateTime, List<WordSet>> eventsByDay;
  final void Function(DateTime) onDayTap;

  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leading = firstOfMonth.weekday % 7; // 일요일 시작
    final gridStart = firstOfMonth.subtract(Duration(days: leading));
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final weeks = ((leading + lastOfMonth.day) / 7).ceil();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var w = 0; w < weeks; w++)
            Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Builder(builder: (_) {
                    final date = gridStart.add(Duration(days: w * 7 + d));
                    final key = _key(date);
                    return Expanded(
                      child: _DayCell(
                        date: date,
                        inMonth: date.month == month.month,
                        isToday: key == today,
                        isSelected: key == _key(selectedDay),
                        isSunday: d == 0,
                        eventCount: (eventsByDay[key] ?? const []).length,
                        onTap: () => onDayTap(date),
                      ),
                    );
                  }),
              ],
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
    required this.isSelected,
    required this.isSunday,
    required this.eventCount,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool isSunday;
  final int eventCount;
  final VoidCallback onTap;

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
        height: 46.h,
        margin: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pinkSoft.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? Border.all(color: AppColors.pink, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(
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
            SizedBox(height: 3.h),
            SizedBox(
              height: 6.h,
              child: eventCount == 0
                  ? null
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < eventCount && i < 3; i++)
                          Container(
                            width: 5.w,
                            height: 5.w,
                            margin: EdgeInsets.symmetric(horizontal: 1.w),
                            decoration: BoxDecoration(
                              color: AppColors.pink,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({required this.day, required this.count});

  final DateTime day;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Text('${day.month}월 ${day.day}일',
              style: TextStyle(fontSize: 16.sp, color: AppColors.ink)),
          SizedBox(width: 8.w),
          if (count > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColors.pinkSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text('$count개',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.pink)),
            ),
        ],
      ),
    );
  }
}

class _DaySetList extends StatelessWidget {
  const _DaySetList({required this.sets, required this.onOpenSet});

  final List<WordSet> sets;
  final void Function(WordSet) onOpenSet;

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌷', style: TextStyle(fontSize: 34.sp)),
            SizedBox(height: 8.h),
            Text('이 날은 등록된 단어가 없어요',
                style: TextStyle(fontSize: 13.sp, color: AppColors.lavender)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 90.h),
      itemCount: sets.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final set = sets[index];
        return BouncyTap(
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
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButton,
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 21.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(set.title,
                          style: TextStyle(
                              fontSize: 15.sp, color: AppColors.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2.h),
                      Text('${set.wordCount}개 단어',
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.lavender)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: AppColors.lavender, size: 20.sp),
              ],
            ),
          ),
        );
      },
    );
  }
}
