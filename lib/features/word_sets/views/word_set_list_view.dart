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
    this.title = '단어 세트 📚',
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

class _WordSetListBody extends StatelessWidget {
  const _WordSetListBody({
    required this.user,
    required this.title,
    required this.enableAdd,
  });

  final AppUser user;
  final String title;
  final bool enableAdd;

  Future<void> _openUpload(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordSetUploadView(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordSetListViewModel>();
    final showFab =
        enableAdd && !viewModel.loading && viewModel.sets.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _openUpload(context),
              icon: const Icon(Icons.add),
              label: const Text('단어 추가'),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack)
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
        onAdd: enableAdd ? () => _openUpload(context) : null,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 90.h),
      itemCount: viewModel.sets.length,
      separatorBuilder: (_, _) => SizedBox(height: 14.h),
      itemBuilder: (context, index) {
        final set = viewModel.sets[index];
        return _WordSetCard(
          set: set,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WordSetDetailView(set: set, user: user),
            ),
          ),
          onDelete: () => _confirmDelete(context, viewModel, set),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 50).ms)
            .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
      },
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

class _WordSetCard extends StatelessWidget {
  const _WordSetCard({
    required this.set,
    required this.onTap,
    required this.onDelete,
  });

  final WordSet set;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BouncyTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: AppColors.softShadow(blur: 20, y: 8),
        ),
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    set.title,
                    style: TextStyle(fontSize: 17.sp, color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                BouncyTap(
                  onTap: onDelete,
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(Icons.delete_outline,
                        size: 20.sp, color: theme.hintColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _Pill(
                  icon: Icons.calendar_today_rounded,
                  label: formatYmd(set.date),
                ),
                SizedBox(width: 8.w),
                _Pill(
                  icon: Icons.style_rounded,
                  label: '${set.wordCount}개',
                ),
              ],
            ),
            if (set.message.trim().isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.lavenderSoft.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  '💬 ${set.message}',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.ink),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.pinkSoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.pink),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(fontSize: 12.sp, color: AppColors.ink)),
        ],
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
                  ? '단어 파일(csv·txt·엑셀)을 올려\n첫 시험을 만들어 보세요!'
                  : '홈 달력에서 단어를 먼저 추가해 주세요!',
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
