import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../models/app_user.dart';
import '../models/word_set.dart';
import '../repositories/word_set_repository.dart';
import '../viewmodels/word_set_list_viewmodel.dart';
import 'word_set_detail_view.dart';
import 'word_set_upload_view.dart';

/// 언니 홈: 노션풍 달력으로 단어 세트를 날짜별로 보여준다.
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
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<WordSet>> _groupByDay(List<WordSet> sets) {
    final map = <DateTime, List<WordSet>>{};
    for (final set in sets) {
      map.putIfAbsent(_dayKey(set.date), () => []).add(set);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordSetListViewModel>();
    final events = _groupByDay(viewModel.sets);
    final selectedSets = events[_dayKey(_selectedDay)] ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('단어 달력 📅')),
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
        child: viewModel.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 90.h),
                children: [
                  _CalendarCard(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    eventsForDay: (day) => events[_dayKey(day)] ?? const [],
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  _SelectedDayHeader(day: _selectedDay, count: selectedSets.length),
                  SizedBox(height: 8.h),
                  if (selectedSets.isEmpty)
                    _EmptyDay()
                  else
                    ...selectedSets.map(
                      (set) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: _DaySetCard(
                          set: set,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WordSetDetailView(
                                set: set,
                                user: widget.user,
                              ),
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

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.eventsForDay,
    required this.onDaySelected,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<WordSet> Function(DateTime) eventsForDay;
  final void Function(DateTime, DateTime) onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: AppColors.softShadow(blur: 20, y: 8),
      ),
      child: TableCalendar<WordSet>(
        firstDay: DateTime(2020),
        lastDay: DateTime(2100),
        focusedDay: focusedDay,
        currentDay: DateTime.now(),
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        eventLoader: eventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16.sp, color: AppColors.ink),
          leftChevronIcon:
              const Icon(Icons.chevron_left, color: AppColors.lavender),
          rightChevronIcon:
              const Icon(Icons.chevron_right, color: AppColors.lavender),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 12.sp, color: AppColors.ink),
          weekendStyle: TextStyle(fontSize: 12.sp, color: AppColors.pink),
        ),
        calendarStyle: CalendarStyle(
          isTodayHighlighted: true,
          todayDecoration: BoxDecoration(
            color: AppColors.pinkSoft.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: AppColors.ink),
          selectedDecoration: const BoxDecoration(
            gradient: AppColors.primaryButton,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.white),
          markerDecoration: const BoxDecoration(
            color: AppColors.lavender,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          defaultTextStyle: const TextStyle(color: AppColors.ink),
          weekendTextStyle: const TextStyle(color: AppColors.pink),
          outsideTextStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.3)),
        ),
        onDaySelected: onDaySelected,
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
    return Row(
      children: [
        Text(
          '${day.month}월 ${day.day}일',
          style: TextStyle(fontSize: 16.sp, color: AppColors.ink),
        ),
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
    );
  }
}

class _DaySetCard extends StatelessWidget {
  const _DaySetCard({required this.set, required this.onTap});

  final WordSet set;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: AppColors.softShadow(blur: 14, y: 6),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(set.title,
                      style: TextStyle(fontSize: 16.sp, color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2.h),
                  Text('${set.wordCount}개 단어',
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.lavender)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.lavender, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text('🌷', style: TextStyle(fontSize: 36.sp)),
          SizedBox(height: 8.h),
          Text('이 날은 등록된 단어가 없어요',
              style: TextStyle(fontSize: 13.sp, color: AppColors.lavender)),
        ],
      ),
    );
  }
}
