import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/history_calendar_view.dart';
import '../../../models/app_user.dart';
import '../models/word_set.dart';
import '../repositories/word_set_repository.dart';
import '../viewmodels/word_set_list_viewmodel.dart';
import 'word_set_detail_view.dart';
import 'word_set_upload_view.dart';

/// 언니의 단어 세트(공부자료) 화면.
/// 동생 공부탭과 같은 '오늘/지난' 큰 카드 2개 구성 + 언니 기능(추가·삭제).
class WordSetListView extends StatelessWidget {
  const WordSetListView({
    super.key,
    required this.user,
    this.title = '단어 세트',
    this.enableAdd = true,
  });

  final AppUser user;
  final String title;

  /// 단어 추가(업로드) 진입을 노출할지.
  final bool enableAdd;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WordSetListViewModel(
        repository: context.read<WordSetRepository>(),
        uid: user.uid,
      ),
      child: _WordSetListBody(user: user, title: title, enableAdd: enableAdd),
    );
  }
}

bool _isTodaySet(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

Future<void> _openUpload(BuildContext context, AppUser user) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => WordSetUploadView(user: user)),
  );
}

/// 세트 삭제 확인 후 삭제 실행.
Future<void> _confirmDeleteSet(
  BuildContext context,
  WordSet set,
  Future<void> Function() onConfirmed,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('삭제할까요? 🥲'),
      content: Text('"${set.title}" 세트를 삭제합니다.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제')),
      ],
    ),
  );
  if (ok == true) await onConfirmed();
}

void _openDetail(BuildContext context, WordSet set, AppUser user) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => WordSetDetailView(set: set, user: user),
    ),
  );
}

class _WordSetListBody extends StatelessWidget {
  const _WordSetListBody({
    required this.user,
    required this.title,
    required this.enableAdd,
  });

  final AppUser user;
  final String title;
  final bool enableAdd;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordSetListViewModel>();
    final showFab = enableAdd && !viewModel.loading;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _openUpload(context, user),
              icon: const Icon(Icons.add),
              label: const Text('단어 추가'),
            )
          : null,
      body: SafeArea(child: _home(context, viewModel)),
    );
  }

  Widget _home(BuildContext context, WordSetListViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(child: Text(viewModel.error!));
    }

    final today = viewModel.sets.where((s) => _isTodaySet(s.date)).toList();
    final past = viewModel.sets.where((s) => !_isTodaySet(s.date)).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
      children: [
        Text('자료를 관리해 볼까요?',
            style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        SizedBox(height: 4.h),
        Text('오늘 올린 자료를 확인하거나, 지난 자료를 달력에서 찾아봐요.',
            style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
        SizedBox(height: 18.h),
        _BigChoiceCard(
          emoji: '📦',
          badge: 'TODAY',
          title: '오늘 올린 자료',
          subtitle: today.isEmpty
              ? '오늘 올린 자료가 없어요'
              : '단어 세트 ${today.length}개',
          action: '자료 보기',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _MaterialsTodayView(user: user, enableAdd: enableAdd),
          )),
        ),
        SizedBox(height: 14.h),
        _BigChoiceCard(
          emoji: '🗓️',
          badge: 'HISTORY',
          title: '지난 자료',
          subtitle: past.isEmpty
              ? '아직 지난 자료가 없어요'
              : '달력에서 지난 자료 ${past.length}개 찾기',
          action: '달력으로 보기',
          dark: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => HistoryCalendarView(
              title: '지난 자료',
              emptyText: '이 날 올린 자료가 없어요.',
              items: [
                for (final set in past)
                  DatedItem(
                    date: set.date,
                    child: _MaterialCoverCard(
                      set: set,
                      onTap: () => _openDetail(context, set, user),
                      onDelete: () => _confirmDeleteSet(
                          context, set, () => viewModel.delete(set.id)),
                    ),
                  ),
              ],
            ),
          )),
        ),
      ],
    );
  }
}

/// 오늘 올린 자료 목록(실시간). 커버 카드 + 추가/삭제.
class _MaterialsTodayView extends StatelessWidget {
  const _MaterialsTodayView({required this.user, required this.enableAdd});

  final AppUser user;
  final bool enableAdd;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<WordSetRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('오늘 올린 자료')),
      floatingActionButton: enableAdd
          ? FloatingActionButton.extended(
              onPressed: () => _openUpload(context, user),
              icon: const Icon(Icons.add),
              label: const Text('단어 추가'),
            )
          : null,
      body: SafeArea(
        child: StreamBuilder<List<WordSet>>(
          stream: repo.watchByCreator(user.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final today =
                snap.data!.where((s) => _isTodaySet(s.date)).toList();
            if (today.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📦', style: TextStyle(fontSize: 44.sp)),
                    SizedBox(height: 12.h),
                    Text('오늘 올린 자료가 없어요',
                        style:
                            TextStyle(fontSize: 15.sp, color: AppColors.ink)),
                    SizedBox(height: 6.h),
                    Text('아래 "단어 추가"로 새 자료를 만들어요!',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 12.sp, color: AppColors.gray)),
                  ],
                ),
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 90.h),
              children: [
                for (final set in today)
                  _MaterialCoverCard(
                    set: set,
                    onTap: () => _openDetail(context, set, user),
                    onDelete: () => _confirmDeleteSet(
                        context, set, () => repo.delete(set.id)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// '오늘/지난'을 고르는 큰 선택 카드(동생 공부탭과 동일 디자인).
class _BigChoiceCard extends StatelessWidget {
  const _BigChoiceCard({
    required this.emoji,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.dark = false,
  });

  final String emoji;
  final String badge;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final sub = Colors.white.withValues(alpha: 0.85);
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(22.w),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? AppColors.navy : null,
          gradient: dark ? null : AppColors.primaryButton,
          borderRadius: BorderRadius.circular(26.r),
          boxShadow: [
            BoxShadow(
              color: (dark ? AppColors.navy : AppColors.mint)
                  .withValues(alpha: dark ? 0.28 : 0.3),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10.w,
              bottom: -22.h,
              child: Text(emoji,
                  style: TextStyle(
                      fontSize: 96.sp,
                      color: Colors.white.withValues(alpha: 0.16))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white)),
                ),
                SizedBox(height: 14.h),
                Text(title,
                    style: TextStyle(
                        fontSize: 23.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                SizedBox(height: 4.h),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: sub)),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Text(action,
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(width: 6.w),
                    Container(
                      width: 26.w,
                      height: 26.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 16.sp, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 단어 세트 커버 카드(공부탭과 동일한 민트 그라디언트 디자인).
/// 언니용: 진행률 대신 단어 수를 보여주고, 우측 상단 X로 세트를 삭제한다.
class _MaterialCoverCard extends StatelessWidget {
  const _MaterialCoverCard({
    required this.set,
    required this.onTap,
    required this.onDelete,
  });

  final WordSet set;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: BouncyTap(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20.w),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: AppColors.primaryButton,
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                  color: AppColors.mint.withValues(alpha: 0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12.w,
                bottom: -18.h,
                child: Text('📚',
                    style: TextStyle(
                        fontSize: 82.sp,
                        color: Colors.white.withValues(alpha: 0.22))),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDelete,
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 18.sp, color: Colors.white),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 36.w),
                    child: Text('WORDS',
                        style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ),
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.only(right: 36.w),
                    child: Text(set.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  SizedBox(height: 2.h),
                  Text('${set.wordCount}단어 · ${formatYmd(set.date)}',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85))),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Text('탭해서 단어 확인·시험 배정',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9))),
                      SizedBox(width: 6.w),
                      Icon(Icons.arrow_forward_rounded,
                          size: 15.sp, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
