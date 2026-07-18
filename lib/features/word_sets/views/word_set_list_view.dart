import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../auth/auth_service.dart';
import '../../../core/utils/date_format.dart';
import '../../../models/app_user.dart';
import '../models/word_set.dart';
import '../repositories/word_set_repository.dart';
import '../viewmodels/word_set_list_viewmodel.dart';
import 'word_set_detail_view.dart';
import 'word_set_upload_view.dart';

/// 언니의 단어 세트 목록 화면.
class WordSetListView extends StatelessWidget {
  const WordSetListView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WordSetListViewModel(
        repository: context.read<WordSetRepository>(),
        uid: user.uid,
      ),
      child: _WordSetListBody(user: user),
    );
  }
}

class _WordSetListBody extends StatelessWidget {
  const _WordSetListBody({required this.user});

  final AppUser user;

  Future<void> _openUpload(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WordSetUploadView(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordSetListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 세트'),
        actions: [
          IconButton(
            onPressed: AuthService().signOut,
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUpload(context),
        icon: const Icon(Icons.add),
        label: const Text('단어 추가'),
      ),
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
      return _EmptyState(onAdd: () => _openUpload(context));
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: viewModel.sets.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final set = viewModel.sets[index];
        return _WordSetCard(
          set: set,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WordSetDetailView(set: set),
            ),
          ),
          onDelete: () => _confirmDelete(context, viewModel, set),
        );
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
        title: const Text('삭제할까요?'),
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
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      set.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, size: 20.sp),
                    tooltip: '삭제',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(formatYmd(set.date), style: theme.textTheme.bodySmall),
                  SizedBox(width: 12.w),
                  Icon(Icons.style_outlined, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text('${set.wordCount}개', style: theme.textTheme.bodySmall),
                ],
              ),
              if (set.message.trim().isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '💬 ${set.message}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64.sp),
          SizedBox(height: 16.h),
          Text(
            '아직 등록한 단어 세트가 없어요',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            '단어 파일(csv·txt·엑셀)을 올려\n첫 번째 시험을 만들어 보세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('단어 추가'),
          ),
        ],
      ),
    );
  }
}
