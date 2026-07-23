import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_theme.dart';

/// 달력에 얹을 기록 한 건(날짜 + 화면에 보여줄 카드).
class DatedItem {
  const DatedItem({required this.date, required this.child});

  final DateTime date;
  final Widget child;
}

/// 지난 기록(단어·시험)을 달력으로 보여주는 공용 화면.
/// 날짜를 누르면 그 날의 자료/시험이 아래에 펼쳐진다.
class HistoryCalendarView extends StatefulWidget {
  const HistoryCalendarView({
    super.key,
    required this.title,
    required this.items,
    this.emptyText = '이 날은 기록이 없어요.',
  });

  final String title;
  final List<DatedItem> items;
  final String emptyText;

  @override
  State<HistoryCalendarView> createState() => _HistoryCalendarViewState();
}

class _HistoryCalendarViewState extends State<HistoryCalendarView> {
  static const _dow = ['월', '화', '수', '목', '금', '토', '일'];

  late final Map<DateTime, List<DatedItem>> _byDay = {};
  late DateTime _focused;
  late DateTime _selected;

  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _byDay.putIfAbsent(_key(item.date), () => []).add(item);
    }
    final days = _byDay.keys.toList()..sort();
    // 기록이 있으면 가장 최근 날을, 없으면 오늘을 기본 선택.
    _selected = days.isNotEmpty ? days.last : _key(DateTime.now());
    _focused = _selected;
  }

  List<DatedItem> _eventsFor(DateTime d) => _byDay[_key(d)] ?? const [];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayItems = _eventsFor(_selected);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        // 아래로 스크롤하면 달력이 위로 올라가 사라지고, 리스트가 전체화면으로.
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 6.h),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: AppColors.softShadow(),
                ),
                child: TableCalendar<DatedItem>(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(now.year + 1, 12, 31),
                focusedDay: _focused,
                currentDay: now,
                selectedDayPredicate: (d) => isSameDay(_selected, d),
                startingDayOfWeek: StartingDayOfWeek.monday,
                rowHeight: 46.h,
                daysOfWeekHeight: 30.h,
                availableGestures: AvailableGestures.horizontalSwipe,
                onDaySelected: (sel, foc) => setState(() {
                  _selected = _key(sel);
                  _focused = foc;
                }),
                onPageChanged: (foc) => _focused = foc,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarBuilders: CalendarBuilders<DatedItem>(
                  headerTitleBuilder: (context, day) => Center(
                    child: Text('${day.year}년 ${day.month}월',
                        style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                  ),
                  dowBuilder: (context, day) {
                    final i = day.weekday - 1;
                    final color = i == 6
                        ? AppColors.danger
                        : (i == 5 ? AppColors.mintDeep : AppColors.gray);
                    return Center(
                      child: Text(_dow[i],
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    );
                  },
                  defaultBuilder: (context, day, _) => _cell(day),
                  outsideBuilder: (context, day, _) =>
                      _cell(day, outside: true),
                  todayBuilder: (context, day, _) => _cell(day, today: true),
                  selectedBuilder: (context, day, _) =>
                      _cell(day, selected: true),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 8.h),
                child: Row(
                  children: [
                    Text(_selectedLabel(),
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    SizedBox(width: 8.w),
                    if (dayItems.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 9.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text('${dayItems.length}건',
                            style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.mintDeep)),
                      ),
                  ],
                ),
              ),
            ),
            if (dayItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(top: 48.h),
                  child: _emptyState(),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => dayItems[i].child,
                    childCount: dayItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _selectedLabel() {
    final w = _dow[_selected.weekday - 1];
    return '${_selected.month}월 ${_selected.day}일 ($w)';
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🗓️', style: TextStyle(fontSize: 40.sp)),
          SizedBox(height: 10.h),
          Text(widget.emptyText,
              style: TextStyle(fontSize: 14.sp, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _cell(DateTime day,
      {bool selected = false, bool today = false, bool outside = false}) {
    final hasEvents = !outside && _eventsFor(day).isNotEmpty;

    // 우선순위: 선택일(민트) > 오늘(네이비 링) > 기록 있는 날(연민트) > 일반.
    Gradient? grad;
    Color? bg;
    Border? border;
    Color fg = outside ? AppColors.hint : AppColors.ink;
    FontWeight weight = FontWeight.w600;

    if (selected) {
      grad = AppColors.primaryButton;
      fg = Colors.white;
      weight = FontWeight.w800;
    } else if (today) {
      bg = AppColors.cream;
      border = Border.all(color: AppColors.navy, width: 1.6);
      fg = AppColors.navy;
      weight = FontWeight.w800;
    } else if (hasEvents) {
      bg = AppColors.blueSoft;
      fg = AppColors.mintDeep;
      weight = FontWeight.w800;
    }

    return Center(
      child: Container(
        width: 40.w,
        height: 40.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: grad,
          color: bg,
          border: border,
          shape: BoxShape.circle,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.mint.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text('${day.day}',
            style: TextStyle(
                fontSize: 14.sp, fontWeight: weight, color: fg)),
      ),
    );
  }
}

/// 지난 기록(달력) 화면으로 들어가는 진입 카드. v2 통일 디자인.
class HistoryEntryButton extends StatelessWidget {
  const HistoryEntryButton({
    super.key,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: AppColors.softShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                borderRadius: BorderRadius.circular(13.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.calendar_month_rounded,
                  color: Colors.white, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  SizedBox(height: 2.h),
                  Text('달력에서 지난 기록 $count건 보기',
                      style:
                          TextStyle(fontSize: 12.sp, color: AppColors.gray)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.hint, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
