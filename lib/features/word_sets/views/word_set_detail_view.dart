import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/word_tile.dart';
import '../../../models/app_user.dart';
import '../../../core/theme/app_theme.dart';
import '../../exam/repositories/exam_repository.dart';
import '../../exam/views/session_monitor_view.dart';
import '../../social/repositories/friend_repository.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';

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
  /// '뜻 적기'로 낼 단어의 인덱스.
  final Set<int> _askMeaning = {};

  /// 시험에 낼 단어 목록(선택한 단어는 뜻 적기로).
  List<WordPair> get _examWords => [
        for (var i = 0; i < widget.set.words.length; i++)
          widget.set.words[i].copyWith(askMeaning: _askMeaning.contains(i)),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = widget.set;
    return Scaffold(
      appBar: AppBar(title: Text(set.title)),
      bottomNavigationBar:
          _StartExamButton(set: set, user: widget.user, words: _examWords),
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
                    Text(formatYmd(set.date), style: theme.textTheme.bodyMedium),
                    SizedBox(width: 12.w),
                    Icon(Icons.style_outlined, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text('${set.wordCount}개', style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (set.message.trim().isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Text(set.message, style: theme.textTheme.bodyMedium),
                ],
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14.sp, color: AppColors.pink),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        '단어의 "뜻 적기"를 켜면 그 문제는 영어를 보여주고 뜻을 적게 해요.',
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.grayText)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: set.words.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, index) => WordTile(
                word: set.words[index],
                index: index + 1,
                trailing: _AskMeaningToggle(
                  on: _askMeaning.contains(index),
                  onTap: () => setState(() {
                    if (!_askMeaning.remove(index)) _askMeaning.add(index);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 단어별 '뜻 적기' 토글 칩.
class _AskMeaningToggle extends StatelessWidget {
  const _AskMeaningToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: 6.w),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: on ? AppColors.pink : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text('뜻 적기',
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : AppColors.gray)),
      ),
    );
  }
}

/// "이 단어로 시험 내기" 버튼. 세션을 만들고 감독 화면으로 이동한다.
class _StartExamButton extends StatefulWidget {
  const _StartExamButton(
      {required this.set, required this.user, required this.words});

  final WordSet set;
  final AppUser user;
  final List<WordPair> words;

  @override
  State<_StartExamButton> createState() => _StartExamButtonState();
}

class _StartExamButtonState extends State<_StartExamButton> {
  bool _creating = false;

  Future<void> _start() async {
    // 시험 볼 동생을 고른다.
    final friends =
        await context.read<FriendRepository>().watchFriends(widget.user.uid).first;
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
    try {
      final session = await context.read<ExamRepository>().createSession(
            wordSet: widget.set,
            words: widget.words,
            hostUid: widget.user.uid,
            hostName: widget.user.name,
            invitedUid: target.uid,
            invitedName: target.name,
          );
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
