import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/word_tile.dart';
import '../../../core/widgets/x_mark.dart';
import '../../../models/app_user.dart';
import '../../social/repositories/friend_repository.dart';
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
        friendRepository: context.read<FriendRepository>(),
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

  /// 파일에서 단어를 불러온다. [append]면 지금 목록 뒤에 이어서 추가한다.
  Future<void> _pickFile(WordSetUploadViewModel viewModel,
      {bool append = false}) async {
    final added = await viewModel.pickAndParse(append: append);
    // 파싱 후 파일명 기반 기본 제목을 컨트롤러에 반영한다.
    if (_titleController.text.trim().isEmpty && viewModel.title.isNotEmpty) {
      _titleController.text = viewModel.title;
    }
    if (append && mounted) _showAddResult(viewModel, added);
  }

  /// 이어 붙이기 결과를 알려준다. (-1은 사용자가 취소한 경우로 아무것도 알리지 않는다)
  void _showAddResult(WordSetUploadViewModel viewModel, int added) {
    if (added < 0) return;
    if (added > 0) {
      final dup = viewModel.duplicateCount;
      showToast(
        context,
        dup > 0
            ? '단어 $added개를 추가했어요! (이미 있는 $dup개는 건너뜀)'
            : '단어 $added개를 추가했어요!',
      );
      return;
    }
    showToast(
      context,
      viewModel.errorMessage ??
          (viewModel.duplicateCount > 0
              ? '모두 이미 있는 단어예요.'
              : '추가할 단어를 찾지 못했어요.'),
      isError: true,
    );
  }

  /// 표 붙여넣기 다이얼로그. [append]면 지금 목록에 이어서 추가한다.
  Future<void> _openPasteDialog(WordSetUploadViewModel viewModel,
      {bool append = false}) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(append ? '표 더 붙여넣기' : '표 붙여넣기'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                append
                    ? '다른 표를 복사한 뒤 아래 버튼을 누르면,\n지금 목록 뒤에 이어서 추가돼요.'
                    : 'GPT나 엑셀에서 만든 단어 표를 복사한 뒤,\n아래 버튼을 누르면 한 번에 붙여넣어져요.',
                style: TextStyle(fontSize: 13.sp, color: AppColors.gray),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final data =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    final text = data?.text ?? '';
                    if (text.trim().isEmpty) {
                      if (dialogContext.mounted) {
                        showToast(dialogContext,
                            '복사된 내용이 없어요. 표를 먼저 복사해 주세요.');
                      }
                      return;
                    }
                    controller.text = text;
                    controller.selection = TextSelection.collapsed(
                        offset: controller.text.length);
                  },
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('클립보드에서 붙여넣기'),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: controller,
                maxLines: 7,
                minLines: 4,
                decoration: const InputDecoration(
                  hintText: '여기에 붙여넣어도 돼요\n예) apple, 사과',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(append ? '추가하기' : '불러오기'),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final added = viewModel.parseFromText(text, append: append);
    if (_titleController.text.trim().isEmpty && viewModel.title.isNotEmpty) {
      _titleController.text = viewModel.title;
    }
    if (append && mounted) _showAddResult(viewModel, added);
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
      Navigator.of(context).pop();
      showToast(context, '단어 세트를 저장했어요!');
    } else if (viewModel.errorMessage != null) {
      showToast(context, viewModel.errorMessage!, isError: true);
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
        onPaste: () => _openPasteDialog(viewModel),
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
                SizedBox(height: 10.h),
                // 표를 여러 번 이어서 붙일 수 있게 '추가' 버튼을 함께 둔다.
                _AddMoreBar(
                  onPasteMore: () => _openPasteDialog(viewModel, append: true),
                  onPickMore: () => _pickFile(viewModel, append: true),
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
                _RecipientPicker(viewModel: viewModel),
                SizedBox(height: 20.h),
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
              trailing: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => viewModel.removeWordAt(index),
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: XMark(color: AppColors.danger, size: 24.w),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
      ],
    );
  }
}

/// 이 자료를 볼 사람(동생)을 직접 선택한다. (여러 명 선택 가능)
class _RecipientPicker extends StatelessWidget {
  const _RecipientPicker({required this.viewModel});

  final WordSetUploadViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final friends = viewModel.friends;
    final selected = viewModel.selectedFriendUids;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_rounded, size: 18.sp, color: AppColors.pink),
            SizedBox(width: 6.w),
            Text('이 자료를 볼 사람',
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
          ],
        ),
        SizedBox(height: 4.h),
        Text('선택한 동생에게만 이 자료가 보여요.',
            style: TextStyle(fontSize: 12.sp, color: AppColors.gray)),
        SizedBox(height: 10.h),
        if (friends.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
            decoration: BoxDecoration(
              color: AppColors.rowBg,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text('아직 친구가 없어요.\n내 정보에서 동생을 초대하면 여기서 선택할 수 있어요.',
                style: TextStyle(fontSize: 12.sp, color: AppColors.gray)),
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final friend in friends)
                _RecipientChip(
                  name: friend.name,
                  selected: selected.contains(friend.uid),
                  onTap: () => viewModel.toggleFriend(friend.uid),
                ),
            ],
          ),
        if (friends.isNotEmpty && selected.isEmpty) ...[
          SizedBox(height: 8.h),
          Text('⚠️ 받는 사람을 한 명 이상 선택해야 동생이 볼 수 있어요.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.danger)),
        ],
      ],
    );
  }
}

/// 받는 사람 선택 칩(v2 톤).
class _RecipientChip extends StatelessWidget {
  const _RecipientChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryButton : null,
          color: selected ? null : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
              color: selected ? Colors.transparent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16.sp,
              color: selected ? Colors.white : AppColors.hint,
            ),
            SizedBox(width: 6.w),
            Text(name,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.grayText)),
          ],
        ),
      ),
    );
  }
}

/// 이미 불러온 목록에 표·파일을 이어서 더 붙이는 버튼 두 개.
class _AddMoreBar extends StatelessWidget {
  const _AddMoreBar({required this.onPasteMore, required this.onPickMore});

  final VoidCallback onPasteMore;
  final VoidCallback onPickMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onPasteMore,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('표 더 붙여넣기'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickMore,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            icon: const Icon(Icons.note_add_outlined, size: 18),
            label: const Text('파일 더 추가'),
          ),
        ),
      ],
    );
  }
}

class _PickPrompt extends StatelessWidget {
  const _PickPrompt({
    required this.onPick,
    required this.onPaste,
    this.errorMessage,
  });

  final VoidCallback onPick;
  final VoidCallback onPaste;
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
            Text('단어를 불러와 주세요 📄',
                style: TextStyle(fontSize: 18.sp, color: AppColors.ink)),
            SizedBox(height: 10.h),
            Text(
              'GPT·엑셀에서 만든 표를 복사해 붙여넣거나,\ncsv·txt·엑셀(xlsx) 파일을 올릴 수 있어요.\n("영어 - 뜻" 순서면 표·목록 모두 인식돼요)',
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
              width: 220.w,
              child: GradientButton(
                label: '표 붙여넣기',
                icon: Icons.content_paste_rounded,
                onPressed: onPaste,
              ),
            ),
            SizedBox(height: 10.h),
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('파일에서 불러오기'),
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
            TextButton(onPressed: onReplace, child: const Text('전체 교체')),
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
