import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/x_mark.dart';
import '../../../models/app_user.dart';
import '../models/word_set.dart';
import '../repositories/word_set_repository.dart';
import '../viewmodels/word_set_list_viewmodel.dart';
import 'exam_assigned_badge.dart';
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
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => WordSetUploadView(user: user)));
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
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('삭제'),
        ),
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
              heroTag: 'fab-wordset-add',
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
    return _MaterialsBrowser(
      user: user,
      sets: viewModel.sets,
      onDelete: (set) =>
          _confirmDeleteSet(context, set, () => viewModel.delete(set.id)),
      onAdd: enableAdd ? () => _openUpload(context, user) : null,
    );
  }
}

/// 자료를 '오늘 / 지난 / 전체'로 걸러 바로 볼 수 있는 목록.
/// 예전에는 큰 카드를 눌러 화면을 한 번 더 들어가야 자료가 보였는데,
/// 목록을 처음부터 펼쳐 두고 위 버튼으로 기간만 좁히도록 바꿨다.
class _MaterialsBrowser extends StatefulWidget {
  const _MaterialsBrowser({
    required this.user,
    required this.sets,
    required this.onDelete,
    required this.onAdd,
  });

  final AppUser user;
  final List<WordSet> sets;
  final void Function(WordSet set) onDelete;
  final VoidCallback? onAdd;

  @override
  State<_MaterialsBrowser> createState() => _MaterialsBrowserState();
}

enum _MaterialFilter { today, past, all }

class _MaterialsBrowserState extends State<_MaterialsBrowser> {
  _MaterialFilter _filter = _MaterialFilter.today;

  String _label(_MaterialFilter f) => switch (f) {
    _MaterialFilter.today => '오늘',
    _MaterialFilter.past => '지난 자료',
    _MaterialFilter.all => '전체',
  };

  List<WordSet> _filtered() {
    return switch (_filter) {
      _MaterialFilter.today =>
        widget.sets.where((s) => _isTodaySet(s.date)).toList(),
      _MaterialFilter.past =>
        widget.sets.where((s) => !_isTodaySet(s.date)).toList(),
      _MaterialFilter.all => widget.sets,
    };
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.sets.where((s) => _isTodaySet(s.date)).length;
    final past = widget.sets.length - today;
    final items = _filtered();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.gutter.w,
              AppSpace.xs.h,
              AppSpace.gutter.w,
              0,
            ),
            child: Row(
              children: [
                for (final f in _MaterialFilter.values) ...[
                  _FilterChip(
                    label: _label(f),
                    count: switch (f) {
                      _MaterialFilter.today => today,
                      _MaterialFilter.past => past,
                      _MaterialFilter.all => widget.sets.length,
                    },
                    selected: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                  SizedBox(width: AppSpace.xs.w),
                ],
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(top: AppSpace.xl.h),
              child: EmptyState(
                icon: Icons.folder_open_rounded,
                text: _filter == _MaterialFilter.today
                    ? '오늘 올린 자료가 없어요.\n새 단어 세트를 만들어 볼까요?'
                    : '아직 자료가 없어요.',
                actionLabel: widget.onAdd == null ? null : '단어 추가하기',
                onAction: widget.onAdd,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.md.w,
              AppSpace.sm.h,
              AppSpace.md.w,
              100.h,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MaterialCoverCard(
                  set: items[i],
                  onTap: () => _openDetail(context, items[i], widget.user),
                  onDelete: () => widget.onDelete(items[i]),
                ),
                childCount: items.length,
              ),
            ),
          ),
      ],
    );
  }
}

/// 목록 위 기간 필터 버튼.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpace.sm.w,
          vertical: AppSpace.xs.h,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink : AppColors.cream,
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
          border: Border.all(
            color: selected ? AppColors.pink : AppColors.border,
          ),
        ),
        child: Text(
          '$label $count',
          style: AppTheme.font(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.grayText,
          ),
        ),
      ),
    );
  }
}

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
      padding: EdgeInsets.only(bottom: AppSpace.sm.h),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.all(AppSpace.md.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 자료를 한눈에 알아보는 표지. 단어 수를 크게 보여 준다.
            Container(
              width: 54.w,
              height: 54.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.pinkSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${set.wordCount}',
                    style: AppTheme.tabularNumber(
                      fontSize: 18.sp,
                      color: AppColors.mintDeep,
                    ),
                  ),
                  Text(
                    '단어',
                    style: AppTheme.font(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mintDeep,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpace.sm.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: AppSpace.xxs.h),
                  Text(
                    formatYmd(set.date),
                    style: AppTheme.font(
                      fontSize: 12.sp,
                      color: AppColors.gray,
                    ),
                  ),
                  if (set.examAssigned) ...[
                    SizedBox(height: AppSpace.xs.h),
                    ExamAssignedBadge.of(set),
                  ],
                ],
              ),
            ),
            SizedBox(width: AppSpace.xs.w),
            // 삭제는 눌러야 보이지 않도록 오른쪽에 작게 두되 44pt 영역을 준다.
            Semantics(
              button: true,
              label: '자료 삭제',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Center(
                    child: XMark(color: AppColors.hint, size: 15.w),
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
