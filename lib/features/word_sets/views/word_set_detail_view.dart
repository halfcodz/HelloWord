import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/word_tile.dart';
import '../../../core/widgets/x_mark.dart';
import '../../../models/app_user.dart';
import '../../../core/theme/app_theme.dart';
import '../../exam/repositories/exam_repository.dart';
import '../../exam/views/session_monitor_view.dart';
import '../../social/repositories/friend_repository.dart';
import '../models/word_pair.dart';
import 'word_edit_sheet.dart';
import '../models/word_set.dart';
import '../repositories/word_set_repository.dart';
import 'exam_assigned_badge.dart';

/// 저장된 단어 세트의 상세(단어 목록) 화면.
/// 각 단어를 '뜻 적기'로 낼지 선택할 수 있다.
class WordSetDetailView extends StatefulWidget {
  const WordSetDetailView({super.key, required this.set, required this.user});

  final WordSet set;
  final AppUser user;

  @override
  State<WordSetDetailView> createState() => _WordSetDetailViewState();
}

class _WordSetDetailViewState extends State<WordSetDetailView> {
  /// 화면에서 편집(삭제) 가능한 현재 단어 목록.
  late final List<WordPair> _words = [...widget.set.words];

  /// 시험 배정 표시(이 화면에서 시험을 내면 곧바로 반영한다).
  late bool _examAssigned = widget.set.examAssigned;
  late DateTime? _examScheduledDate = widget.set.examScheduledDate;
  late int _examAssignedCount = widget.set.examAssignedCount;

  /// 이 자료로 시험을 냈을 때 배정 표시를 갱신한다.
  void _onExamAssigned(DateTime scheduledDate) {
    setState(() {
      _examAssigned = true;
      _examScheduledDate = scheduledDate;
      _examAssignedCount = _examAssignedCount + 1;
    });
  }

  /// '뜻 적기'로 낼 단어(객체 참조로 추적해 삭제 후에도 유지).
  final Set<WordPair> _ask = {};

  /// 다중 선택 삭제 모드.
  bool _selectMode = false;
  final Set<WordPair> _selected = {};

  bool _saving = false;

  /// 시험에 낼 단어 목록(선택한 단어는 뜻 적기로).
  List<WordPair> get _examWords => [
    for (final w in _words) w.copyWith(askMeaning: _ask.contains(w)),
  ];

  Future<void> _persist() async {
    setState(() => _saving = true);
    try {
      await context.read<WordSetRepository>().updateWords(
        widget.set.id,
        _words,
      );
    } catch (_) {
      if (mounted) {
        showToast(context, '저장하지 못했어요. 다시 시도해 주세요.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 단어 하나를 고친다(저장한 뒤에도 언제든).
  Future<void> _editOne(WordPair word) async {
    final edited = await showWordEditSheet(context, word: word);
    if (edited == null || !mounted) return;
    final index = _words.indexOf(word);
    if (index < 0) return;
    setState(() {
      final wasAsked = _ask.remove(word);
      _words[index] = edited;
      if (wasAsked) _ask.add(edited);
    });
    await _persist();
    if (mounted) showToast(context, '단어를 고쳤어요.');
  }

  /// 이미 있는 단어(영어+뜻이 같은 것)는 빼고 새 단어만 더한다.
  Future<void> _appendWords(List<WordPair> incoming) async {
    if (incoming.isEmpty) return;
    String key(WordPair w) =>
        '${w.english.toLowerCase().trim()}|${w.korean.trim()}';
    final existing = {for (final w in _words) key(w)};
    final fresh = [
      for (final w in incoming)
        if (existing.add(key(w))) w,
    ];
    if (fresh.isEmpty) {
      if (mounted) showToast(context, '이미 있는 단어뿐이에요.');
      return;
    }
    setState(() => _words.addAll(fresh));
    await _persist();
    if (!mounted) return;
    final skipped = incoming.length - fresh.length;
    showToast(
      context,
      skipped == 0
          ? '${fresh.length}개를 더했어요.'
          : '${fresh.length}개를 더했어요. (중복 $skipped개는 건너뜀)',
    );
  }

  /// 단어를 더하는 방법을 고른다: 직접 입력 / 표 붙여넣기 / 파일.
  Future<void> _addWords() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: AppSpace.xs.h),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: AppColors.pink),
              title: const Text('직접 입력'),
              subtitle: const Text('단어를 하나씩 써서 넣어요'),
              onTap: () => Navigator.of(sheet).pop('one'),
            ),
            ListTile(
              leading: Icon(Icons.table_chart_rounded, color: AppColors.pink),
              title: const Text('표 붙여넣기'),
              subtitle: const Text('엑셀·표를 그대로 붙여넣어요'),
              onTap: () => Navigator.of(sheet).pop('paste'),
            ),
            ListTile(
              leading: Icon(Icons.upload_file_rounded, color: AppColors.pink),
              title: const Text('파일에서 가져오기'),
              subtitle: const Text('엑셀·CSV·txt 파일을 골라요'),
              onTap: () => Navigator.of(sheet).pop('file'),
            ),
            SizedBox(height: AppSpace.xs.h),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    try {
      switch (choice) {
        case 'one':
          final word = await showWordEditSheet(context);
          if (word != null) await _appendWords([word]);
        case 'paste':
          final words = await showPasteWordsSheet(context);
          if (words != null) await _appendWords(words);
        case 'file':
          final words = await pickWordsFromFile();
          if (words != null) await _appendWords(words);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, '파일을 읽지 못했어요. 형식을 확인해 주세요.', isError: true);
      }
    }
  }

  Future<void> _deleteOne(WordPair word) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어를 삭제할까요?'),
        content: Text('"${word.english}" 단어를 이 세트에서 지웁니다.'),
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
    if (ok != true) return;
    setState(() {
      _words.remove(word);
      _ask.remove(word);
      _selected.remove(word);
    });
    await _persist();
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final n = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$n개 단어를 삭제할까요?'),
        content: const Text('선택한 단어들을 이 세트에서 지웁니다.'),
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
    if (ok != true) return;
    setState(() {
      _words.removeWhere(_selected.contains);
      _ask.removeWhere(_selected.contains);
      _selected.clear();
      _selectMode = false;
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = widget.set;
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? '${_selected.length}개 선택' : set.title),
        actions: [
          if (!_selectMode)
            IconButton(
              tooltip: '단어 추가',
              icon: const Icon(Icons.add_rounded),
              onPressed: _saving ? null : _addWords,
            ),
          if (!_selectMode)
            TextButton(
              onPressed: _words.isEmpty
                  ? null
                  : () => setState(() => _selectMode = true),
              child: const Text('선택'),
            )
          else
            TextButton(
              onPressed: () => setState(() {
                _selectMode = false;
                _selected.clear();
              }),
              child: const Text('취소'),
            ),
        ],
      ),
      bottomNavigationBar: _selectMode
          ? _DeleteBar(
              count: _selected.length,
              allSelected:
                  _words.isNotEmpty && _selected.length == _words.length,
              onToggleAll: () => setState(() {
                if (_selected.length == _words.length) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(_words);
                }
              }),
              onDelete: _saving ? null : _deleteSelected,
            )
          : _StartExamButton(
              set: set,
              user: widget.user,
              words: _examWords,
              onAssigned: _onExamAssigned,
            ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      formatYmd(set.date),
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(width: 12.w),
                    Icon(Icons.style_outlined, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      '${_words.length}개',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (_examAssigned) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      ExamAssignedBadge(
                        assigned: true,
                        scheduledDate: _examScheduledDate,
                        count: _examAssignedCount,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '시험에 배정한 자료예요.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.mintDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (set.message.trim().isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Text(set.message, style: theme.textTheme.bodyMedium),
                ],
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14.sp,
                      color: AppColors.pink,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        _selectMode
                            ? '삭제할 단어를 눌러 선택한 뒤, 아래에서 한 번에 지워요.'
                            : '"뜻 적기"를 켜면 그 문제는 영어를 보여주고 뜻을 적게 해요. · X로 단어를 지울 수 있어요.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.grayText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _words.isEmpty
                ? Center(
                    child: Text(
                      '단어가 없어요.',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.gray),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: _words.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final word = _words[index];
                      final selected = _selected.contains(word);
                      final tile = WordTile(
                        word: word,
                        index: index + 1,
                        trailing: _selectMode
                            ? Padding(
                                padding: EdgeInsets.only(left: 6.w),
                                child: Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: selected
                                      ? AppColors.pink
                                      : AppColors.hint,
                                  size: 24.sp,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _AskMeaningToggle(
                                    on: _ask.contains(word),
                                    onTap: () => setState(() {
                                      if (!_ask.remove(word)) _ask.add(word);
                                    }),
                                  ),
                                  _DeleteWordButton(
                                    onTap: () => _deleteOne(word),
                                  ),
                                ],
                              ),
                      );
                      if (!_selectMode) {
                        // 저장한 뒤에도 눌러서 고칠 수 있다.
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _editOne(word),
                          child: tile,
                        );
                      }
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() {
                          if (!_selected.remove(word)) _selected.add(word);
                        }),
                        child: tile,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 단어 한 개 삭제 X 버튼. 테두리·배경 없이 빨간 X만 직접 그린다.
/// (웹에서 아이콘 폰트 X 글리프가 안 보이는 문제 회피)
class _DeleteWordButton extends StatelessWidget {
  const _DeleteWordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 8.w),
        child: XMark(color: AppColors.danger, size: 22.w),
      ),
    );
  }
}

/// 다중 선택 삭제 모드의 하단 바(전체선택 + 삭제).
class _DeleteBar extends StatelessWidget {
  const _DeleteBar({
    required this.count,
    required this.allSelected,
    required this.onToggleAll,
    required this.onDelete,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: onToggleAll,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                side: BorderSide(color: AppColors.border),
                foregroundColor: AppColors.grayText,
              ),
              icon: Icon(
                allSelected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18.sp,
              ),
              label: Text(allSelected ? '선택 해제' : '전체 선택'),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: FilledButton.icon(
                onPressed: count == 0 ? null : onDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text('$count개 삭제'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 단어별 '뜻 적기' 토글 스위치(버튼이 아닌 온/오프 토글).
class _AskMeaningToggle extends StatelessWidget {
  const _AskMeaningToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '뜻 적기',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: on ? AppColors.mintDeep : AppColors.gray,
              ),
            ),
            SizedBox(height: 3.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 42.w,
              height: 24.h,
              padding: EdgeInsets.all(2.w),
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: on ? AppColors.pink : AppColors.border,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Container(
                width: 20.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "이 단어로 시험 내기" 버튼. 세션을 만들고 감독 화면으로 이동한다.
class _StartExamButton extends StatefulWidget {
  const _StartExamButton({
    required this.set,
    required this.user,
    required this.words,
    required this.onAssigned,
  });

  final WordSet set;
  final AppUser user;
  final List<WordPair> words;

  /// 시험을 냈을 때(자료에 배정 표시를 남긴 뒤) 호출된다.
  final void Function(DateTime scheduledDate) onAssigned;

  @override
  State<_StartExamButton> createState() => _StartExamButtonState();
}

class _StartExamButtonState extends State<_StartExamButton> {
  bool _creating = false;

  Future<void> _start() async {
    // 시험 볼 동생을 고른다.
    final friends = await context
        .read<FriendRepository>()
        .watchFriends(widget.user.uid)
        .first;
    if (!mounted) return;
    if (friends.isEmpty) {
      showToast(context, '먼저 내 정보에서 동생을 초대해 친구를 맺어주세요.', isError: true);
      return;
    }
    AppUser? target = friends.first;
    if (friends.length > 1) {
      target = await showDialog<AppUser>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('누구에게 시험을 낼까요?'),
          children: [
            for (final f in friends)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(f),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(f.name, style: TextStyle(fontSize: 16.sp)),
                ),
              ),
          ],
        ),
      );
      if (target == null || !mounted) return;
    }

    setState(() => _creating = true);
    final wordSetRepo = context.read<WordSetRepository>();
    try {
      final session = await context.read<ExamRepository>().createSession(
        wordSet: widget.set,
        words: widget.words,
        hostUid: widget.user.uid,
        hostName: widget.user.name,
        invitedUid: target.uid,
        invitedName: target.name,
      );
      // 이 자료로 시험을 냈다는 표시를 자료에 남긴다.
      final now = DateTime.now();
      try {
        await wordSetRepo.markExamAssigned(
          id: widget.set.id,
          scheduledDate: now,
        );
        if (mounted) widget.onAssigned(now);
      } catch (_) {
        // 표시 저장에 실패해도 시험 진행은 막지 않는다.
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionMonitorView(sessionId: session.id),
        ),
      );
    } catch (_) {
      if (mounted) {
        showToast(context, '시험을 시작하지 못했어요. 다시 시도해 주세요.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: GradientButton(
          label: '이 단어로 시험 내기',
          icon: Icons.play_arrow_rounded,
          loading: _creating,
          onPressed: _creating ? null : _start,
        ),
      ),
    );
  }
}
