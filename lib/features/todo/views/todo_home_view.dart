import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_reload.dart';
import '../../../core/widgets/month_calendar.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
import '../../social/views/notification_bell.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

/// 동생 홈: 투두메이트식 달력 + 그날의 투두리스트.
class TodoHomeView extends StatefulWidget {
  const TodoHomeView({super.key, required this.user});

  final AppUser user;

  @override
  State<TodoHomeView> createState() => _TodoHomeViewState();
}

class _TodoHomeViewState extends State<TodoHomeView> {
  final _now = DateTime.now();
  final _addController = TextEditingController();
  late DateTime _month = DateTime(_now.year, _now.month);
  late DateTime _selectedDay = DateTime(_now.year, _now.month, _now.day);

  TodoRepository get _repo => context.read<TodoRepository>();

  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    _addController.clear();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${_selectedDay.month}월 ${_selectedDay.day}일 할 일',
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          content: TextField(
            controller: _addController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(dialogContext),
            decoration: const InputDecoration(hintText: '무엇을 할까요?'),
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => _add(dialogContext),
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _add(BuildContext dialogContext) async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    Navigator.of(dialogContext).pop();
    try {
      await _repo.add(uid: widget.user.uid, text: text, date: _selectedDay);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('할 일 저장에 실패했어요. (Firestore 규칙 확인 필요)'),
            duration: Duration(seconds: 3),
          ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일'),
        actions: [
          NotificationBell(user: widget.user),
          IconButton(
            tooltip: '새로고침',
            onPressed: reloadApp,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Todo>>(
          stream: _repo.watchMonth(widget.user.uid, _month),
          builder: (context, snapshot) {
            final todos = snapshot.data ?? const <Todo>[];
            final countByDay = <DateTime, int>{};
            for (final t in todos) {
              countByDay.update(_key(t.date), (v) => v + 1,
                  ifAbsent: () => 1);
            }
            final dayTodos = todos
                .where((t) => _key(t.date) == _key(_selectedDay))
                .toList()
              ..sort((a, b) => a.done == b.done ? 0 : (a.done ? 1 : -1));

            return Column(
              children: [
                FriendBar(me: widget.user),
                MonthCalendar(
                  month: _month,
                  selectedDay: _selectedDay,
                  today: DateTime(_now.year, _now.month, _now.day),
                  eventCount: (day) => countByDay[_key(day)] ?? 0,
                  onDayTap: (day) => setState(() => _selectedDay = day),
                  onPrev: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1)),
                  onNext: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1)),
                  onToday: () => setState(() {
                    _month = DateTime(_now.year, _now.month);
                    _selectedDay = DateTime(_now.year, _now.month, _now.day);
                  }),
                ),
                Divider(
                    height: 16.h,
                    thickness: 1,
                    indent: 20.w,
                    endIndent: 20.w),
                _DayHeader(day: _selectedDay, count: dayTodos.length),
                SizedBox(height: 4.h),
                Expanded(
                  child: dayTodos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🍀', style: TextStyle(fontSize: 40.sp)),
                              SizedBox(height: 8.h),
                              Text('할 일을 추가해 보세요!',
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.lavender)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 90.h),
                          itemCount: dayTodos.length,
                          separatorBuilder: (_, _) => SizedBox(height: 8.h),
                          itemBuilder: (context, index) {
                            final todo = dayTodos[index];
                            return _TodoTile(
                              todo: todo,
                              onToggle: () => _repo.setDone(
                                uid: widget.user.uid,
                                id: todo.id,
                                done: !todo.done,
                              ),
                              onDelete: () => _repo.delete(
                                  uid: widget.user.uid, id: todo.id),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.count});

  final DateTime day;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Text('${day.month}월 ${day.day}일 할 일',
              style: TextStyle(fontSize: 15.sp, color: AppColors.ink)),
          SizedBox(width: 8.w),
          if (count > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColors.pinkSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text('$count',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.pink)),
            ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: AppColors.softShadow(blur: 8, y: 3),
          ),
          child: Row(
            children: [
              _CheckCircle(done: todo.done),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  todo.text,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: todo.done
                        ? AppColors.ink.withValues(alpha: 0.4)
                        : AppColors.ink,
                    decoration:
                        todo.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24.w,
      height: 24.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: done ? AppColors.primaryButton : null,
        color: done ? null : AppColors.cream,
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? Colors.transparent : AppColors.pinkSoft,
          width: 2,
        ),
      ),
      child: done
          ? Icon(Icons.check, size: 15.sp, color: Colors.white)
          : null,
    );
  }
}
