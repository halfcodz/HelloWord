import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/word_tile.dart';
import '../../../models/app_user.dart';
import '../repositories/word_set_repository.dart';
import '../viewmodels/word_set_upload_viewmodel.dart';

/// 단어 파일을 올리고 제목·날짜·한마디를 입력해 저장하는 화면.
class WordSetUploadView extends StatelessWidget {
  const WordSetUploadView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WordSetUploadViewModel(
        repository: context.read<WordSetRepository>(),
        uid: user.uid,
      ),
      child: const _UploadScreen(),
    );
  }
}

class _UploadScreen extends StatefulWidget {
  const _UploadScreen();

  @override
  State<_UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<_UploadScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(WordSetUploadViewModel viewModel) async {
    await viewModel.pickAndParse();
    // 파싱 후 파일명 기반 기본 제목을 컨트롤러에 반영한다.
    if (_titleController.text.trim().isEmpty && viewModel.title.isNotEmpty) {
      _titleController.text = viewModel.title;
    }
  }

  Future<void> _pickDate(WordSetUploadViewModel viewModel) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) viewModel.setDate(picked);
  }

  Future<void> _save(WordSetUploadViewModel viewModel) async {
    final success = await viewModel.save();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('단어 세트를 저장했어요!')),
      );
      Navigator.of(context).pop();
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordSetUploadViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('단어 세트 만들기')),
      body: SafeArea(
        child: _buildBody(context, viewModel),
      ),
      bottomNavigationBar: viewModel.hasWords
          ? _SaveBar(
              enabled: viewModel.canSave,
              saving: viewModel.status == UploadStatus.saving,
              onSave: () => _save(viewModel),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, WordSetUploadViewModel viewModel) {
    if (viewModel.status == UploadStatus.parsing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!viewModel.hasWords) {
      return _PickPrompt(
        errorMessage: viewModel.status == UploadStatus.error
            ? viewModel.errorMessage
            : null,
        onPick: () => _pickFile(viewModel),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FileInfoCard(
                  fileName: viewModel.fileName ?? '',
                  wordCount: viewModel.words.length,
                  skipped: viewModel.skippedLines,
                  onReplace: () => _pickFile(viewModel),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: _titleController,
                  onChanged: viewModel.setTitle,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '예) 중1 필수단어 1과',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.h),
                InkWell(
                  onTap: () => _pickDate(viewModel),
                  borderRadius: BorderRadius.circular(4.r),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '날짜',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(formatYmd(viewModel.date)),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _messageController,
                  onChanged: viewModel.setMessage,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '언니의 한마디',
                    hintText: '예) 이번엔 스펠링 조심해!',
                    prefixIcon: Icon(Icons.chat_bubble_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  '단어 미리보기',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList.separated(
            itemCount: viewModel.words.length,
            separatorBuilder: (_, _) => SizedBox(height: 8.h),
            itemBuilder: (context, index) => WordTile(
              word: viewModel.words[index],
              index: index + 1,
              trailing: IconButton(
                icon: Icon(Icons.close, size: 18.sp),
                tooltip: '이 단어 제외',
                onPressed: () => viewModel.removeWordAt(index),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
      ],
    );
  }
}

class _PickPrompt extends StatelessWidget {
  const _PickPrompt({required this.onPick, this.errorMessage});

  final VoidCallback onPick;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow(),
              ),
              child: Icon(Icons.cloud_upload_rounded,
                  size: 54.sp, color: Colors.white),
            ),
            SizedBox(height: 20.h),
            Text('단어 파일을 올려주세요 📄',
                style: TextStyle(fontSize: 18.sp, color: AppColors.ink)),
            SizedBox(height: 10.h),
            Text(
              'csv · txt · 엑셀(xlsx) 파일을 지원해요.\n각 줄이 "영단어-해석" 형식이면 됩니다.\n(구분자는 하이픈 -, 쉼표 , 탭 모두 가능)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.lavender),
            ),
            if (errorMessage != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            SizedBox(height: 28.h),
            SizedBox(
              width: 200.w,
              child: GradientButton(
                label: '파일 선택',
                icon: Icons.folder_open_rounded,
                onPressed: onPick,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard({
    required this.fileName,
    required this.wordCount,
    required this.skipped,
    required this.onReplace,
  });

  final String fileName;
  final int wordCount;
  final int skipped;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    skipped > 0
                        ? '단어 $wordCount개 · 형식 안 맞는 $skipped줄 제외됨'
                        : '단어 $wordCount개',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onReplace, child: const Text('변경')),
          ],
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.enabled,
    required this.saving,
    required this.onSave,
  });

  final bool enabled;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        child: GradientButton(
          label: '저장하기 💾',
          loading: saving,
          onPressed: enabled ? onSave : null,
        ),
      ),
    );
  }
}
