import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_reload.dart';
import '../../../core/widgets/month_calendar.dart';
import '../../../models/app_user.dart';
import '../../social/views/friend_bar.dart';
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

  Future<void> _refresh() async {
    reloadApp();
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _add() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    _addController.clear();
    await _repo.add(uid: widget.user.uid, text: text, date: _selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('할 일 ✅')),
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
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.pink,
                    child: dayTodos.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 60.h),
                              Center(
                                child: Column(
                                  children: [
                                    Text('🍀',
                                        style: TextStyle(fontSize: 40.sp)),
                                    SizedBox(height: 8.h),
                                    Text('할 일을 추가해 보세요!',
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.lavender)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
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
                ),
                _AddBar(controller: _addController, onAdd: _add),
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
          color: Colors.red.shade300,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
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
        color: done ? null : Colors.white,
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

class _AddBar extends StatelessWidget {
  const _AddBar({required this.controller, required this.onAdd});

  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAdd(),
              decoration: const InputDecoration(
                hintText: '할 일 추가…',
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow(blur: 8, y: 3),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 24.sp),
            ),
          ),
        ],
      ),
    );
  }
}
