import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_reload.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/month_calendar.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
import '../../social/views/notification_bell.dart';
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


  void _openDay(DateTime day, Map<DateTime, List<WordSet>> events) {
    setState(() => _selectedDay = day);
    final sets = events[_dayKey(day)] ?? const <WordSet>[];
    showDialog<void>(
      context: context,
      builder: (_) => _DayDialog(
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
        onAdd: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WordSetUploadView(user: widget.user),
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
      appBar: AppBar(
        title: const Text('단어 달력'),
        actions: [
          NotificationBell(user: widget.user),
          IconButton(
            tooltip: '새로고침',
            onPressed: reloadApp,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FriendBar(me: widget.user),
              MonthCalendar(
                month: _month,
                selectedDay: _selectedDay,
                today: DateTime(_now.year, _now.month, _now.day),
                eventCount: (day) =>
                    (events[_dayKey(day)] ?? const []).length,
                onDayTap: (day) => _openDay(day, events),
                onPrev: _prevMonth,
                onNext: _nextMonth,
                onToday: _today,
              ),
              SizedBox(height: 10.h),
              Text('날짜를 누르면 그날의 단어가 나와요 🌸',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12.sp, color: AppColors.lavender)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 날짜를 누르면 뜨는 팝업. 그 날의 단어 세트를 보여준다.
class _DayDialog extends StatelessWidget {
  const _DayDialog({
    required this.day,
    required this.sets,
    required this.onOpenSet,
    required this.onAdd,
  });

  final DateTime day;
  final List<WordSet> sets;
  final void Function(WordSet) onOpenSet;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('${day.month}월 ${day.day}일',
                    style: TextStyle(fontSize: 18.sp, color: AppColors.ink)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 20.sp, color: AppColors.lavender),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (sets.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Column(
                  children: [
                    Text('🌷', style: TextStyle(fontSize: 34.sp)),
                    SizedBox(height: 8.h),
                    Text('이 날은 등록된 단어가 없어요',
                        style: TextStyle(
                            fontSize: 13.sp, color: AppColors.lavender)),
                    SizedBox(height: 16.h),
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('단어 추가'),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 320.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sets.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final set = sets[index];
                    return BouncyTap(
                      onTap: () => onOpenSet(set),
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: AppColors.softShadow(blur: 10, y: 4),
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
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
