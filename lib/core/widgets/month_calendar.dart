import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import 'bouncy_tap.dart';

/// 재사용 가능한 컴팩트 월 달력. 날짜별 이벤트 개수를 점으로 표시한다.
/// 언니(단어 세트)·동생(투두) 모두 사용한다.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.eventCount,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final DateTime selectedDay;
  final DateTime today;
  final int Function(DateTime day) eventCount;
  final void Function(DateTime day) onDayTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leading = firstOfMonth.weekday % 7; // 일요일 시작
    final gridStart = firstOfMonth.subtract(Duration(days: leading));
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final weeks = ((leading + lastOfMonth.day) / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          month: month,
          onPrev: onPrev,
          onNext: onNext,
          onToday: onToday,
        ),
        const _WeekdayRow(),
        Padding(
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
                        return Expanded(
                          child: _DayCell(
                            date: date,
                            inMonth: date.month == month.month,
                            isToday: _key(date) == _key(today),
                            isSelected: _key(date) == _key(selectedDay),
                            isSunday: d == 0,
                            eventCount: eventCount(date),
                            onTap: () => onDayTap(date),
                          ),
                        );
                      }),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
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
        height: 38.h,
        margin: EdgeInsets.all(1.5.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pinkSoft.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? Border.all(color: AppColors.pink, width: 1.5)
              : null,
        ),
        // 날짜 원은 칸 중앙에, 점 표시는 아래쪽에 겹쳐 배치한다.
        child: Stack(
          alignment: Alignment.center,
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
            if (eventCount > 0)
              Positioned(
                bottom: 3.h,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
