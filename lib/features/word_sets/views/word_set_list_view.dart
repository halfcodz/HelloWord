import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../models/app_user.dart';
import '../models/word_set.dart';
import '../repositories/word_set_repository.dart';
import '../viewmodels/word_set_list_viewmodel.dart';
import 'word_set_detail_view.dart';
import 'word_set_upload_view.dart';

/// 언니의 단어 세트 목록 화면.
class WordSetListView extends StatelessWidget {
  const WordSetListView({
    super.key,
    required this.user,
    this.title = '단어 세트',
    this.enableAdd = true,
  });

  final AppUser user;
  final String title;

  /// 단어 추가(업로드) 진입을 노출할지. 하단바의 "시험" 탭에서는 false.
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

class _WordSetListBody extends StatefulWidget {
  const _WordSetListBody({
    required this.user,
    required this.title,
    required this.enableAdd,
  });

  final AppUser user;
  final String title;
  final bool enableAdd;

  @override
  State<_WordSetListBody> createState() => _WordSetListBodyState();
}

class _WordSetListBodyState extends State<_WordSetListBody> {
  bool _showPast = false;

  Future<void> _openUpload(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordSetUploadView(user: widget.user)),
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordSetListViewModel>();
    final showFab =
        widget.enableAdd && !viewModel.loading && viewModel.sets.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _openUpload(context),
              icon: const Icon(Icons.add),
              label: const Text('단어 추가'),
            )
          : null,
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, WordSetListViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(child: Text(viewModel.error!));
    }
    if (viewModel.isEmpty) {
      return _EmptyState(
        onAdd: widget.enableAdd ? () => _openUpload(context) : null,
      );
    }

    final today = viewModel.sets.where((s) => _isToday(s.date)).toList();
    final past = viewModel.sets.where((s) => !_isToday(s.date)).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 90.h),
      children: [
        _sectionHeader('오늘 자료'),
        if (today.isEmpty)
          _hint('오늘 올린 자료가 없어요.')
        else
          for (final set in today) _row(context, viewModel, set),
        if (past.isNotEmpty) ...[
          SizedBox(height: 10.h),
          _PastHeader(
            count: past.length,
            expanded: _showPast,
            onTap: () => setState(() => _showPast = !_showPast),
          ),
          if (_showPast)
            for (final set in past) _row(context, viewModel, set),
        ],
      ],
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 8.h),
        child: Text(text,
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
      );

  Widget _hint(String text) => Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.rowBg,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
      );

  Widget _row(
      BuildContext context, WordSetListViewModel viewModel, WordSet set) {
    return _MaterialCoverCard(
      set: set,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WordSetDetailView(set: set, user: widget.user),
        ),
      ),
      onDelete: () => _confirmDelete(context, viewModel, set),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WordSetListViewModel viewModel,
    WordSet set,
  ) async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true) {
      await viewModel.delete(set.id);
    }
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
              // 우측 상단 X: 세트 삭제.
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

/// '지난 자료' 펼침/접힘 헤더.
class _PastHeader extends StatelessWidget {
  const _PastHeader(
      {required this.count, required this.expanded, required this.onTap});

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 18.sp, color: AppColors.grayText),
            SizedBox(width: 6.w),
            Text('지난 자료 ($count)',
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const Spacer(),
            Icon(expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌸', style: TextStyle(fontSize: 64.sp))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.12, 1.12),
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                ),
            SizedBox(height: 20.h),
            Text('아직 단어 세트가 없어요',
                style: TextStyle(fontSize: 18.sp, color: AppColors.ink)),
            SizedBox(height: 8.h),
            Text(
              onAdd != null
                  ? '단어 파일(csv·txt·엑셀)을 올려\n공부자료를 만들어 보세요!'
                  : '자료 탭에서 공부자료를 먼저 추가해 주세요!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.lavender),
            ),
            if (onAdd != null) ...[
              SizedBox(height: 28.h),
              SizedBox(
                width: 220.w,
                child: GradientButton(
                  label: '단어 추가하기',
                  icon: Icons.add,
                  onPressed: onAdd,
                ),
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}
