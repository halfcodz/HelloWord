import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/word_tile.dart' show englishLead;
import '../../call/views/call_panel.dart';
import '../../word_sets/models/word_pair.dart';
import '../models/exam_answer.dart';
import '../models/exam_session.dart';
import '../repositories/exam_repository.dart';
import '../viewmodels/session_host_viewmodel.dart';
import 'exam_result_widgets.dart';

/// 언니(출제자)의 실시간 감독 화면.
class SessionMonitorView extends StatelessWidget {
  const SessionMonitorView({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SessionHostViewModel(
        repository: context.read<ExamRepository>(),
        sessionId: sessionId,
      ),
      child: const _MonitorBody(),
    );
  }
}

class _MonitorBody extends StatelessWidget {
  const _MonitorBody();

  Future<void> _confirmClose(
    BuildContext context,
    SessionHostViewModel viewModel, {
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await viewModel.closeSession();
      // popUntil은 idempotent라 세션 삭제 자동 이동과 겹쳐도 루트까지만 이동한다.
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SessionHostViewModel>();
    final session = viewModel.session;

    return Scaffold(
      appBar: AppBar(title: Text(session?.title ?? '시험 감독')),
      body: SafeArea(child: _buildContent(context, viewModel, session)),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SessionHostViewModel viewModel,
    ExamSession? session,
  ) {
    if (session == null) {
      // 동생이 시험을 종료해 세션이 사라진 경우 → 자동으로 홈 이동.
      if (viewModel.loaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        });
      }
      return const Center(child: CircularProgressIndicator());
    }

    switch (session.status) {
      case SessionStatus.waiting:
        return _WaitingView(
          invitedName: session.invitedName ?? '동생',
          onCancel: () => _confirmClose(
            context,
            viewModel,
            title: '시험을 취소할까요?',
            message: '아직 동생이 수락하지 않았어요.',
          ),
        );
      case SessionStatus.declined:
        return _DeclinedView(
          name: session.invitedName ?? '동생',
          onClose: () => _confirmClose(
            context,
            viewModel,
            title: '닫을까요?',
            message: '시험을 닫고 목록으로 돌아갑니다.',
          ),
        );
      case SessionStatus.active:
      case SessionStatus.finished:
        return _LiveMonitor(
          session: session,
          viewModel: viewModel,
          onClose: () => _confirmClose(
            context,
            viewModel,
            title: session.status == SessionStatus.finished
                ? '통화를 끊고 시험을 마칠까요?'
                : '시험을 종료할까요?',
            message: session.status == SessionStatus.finished
                ? '영상통화가 종료되고 언니·동생 모두 홈으로 이동해요.'
                : '진행 중인 시험을 종료합니다.',
          ),
        );
    }
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({required this.invitedName, required this.onCancel});

  final String invitedName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96.w,
            height: 96.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              shape: BoxShape.circle,
            ),
            child: Text('📨', style: TextStyle(fontSize: 44.sp)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 1000.ms,
                curve: Curves.easeInOut,
              ),
          SizedBox(height: 24.h),
          Text('$invitedName에게 시험 초대를 보냈어요',
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 16.h,
                width: 16.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12.w),
              Text('수락을 기다리는 중…', style: theme.textTheme.bodyMedium),
            ],
          ),
          SizedBox(height: 40.h),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('초대 취소'),
          ),
        ],
      ),
    );
  }
}

class _DeclinedView extends StatelessWidget {
  const _DeclinedView({required this.name, required this.onClose});

  final String name;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('😢', style: TextStyle(fontSize: 52.sp)),
            SizedBox(height: 16.h),
            Text('$name이(가) 초대를 거절했어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            SizedBox(height: 8.h),
            Text('나중에 다시 시험을 내볼 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
            SizedBox(height: 32.h),
            SizedBox(
              width: 200.w,
              child: FilledButton(
                onPressed: onClose,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: const Text('닫기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMonitor extends StatelessWidget {
  const _LiveMonitor({
    required this.session,
    required this.viewModel,
    required this.onClose,
  });

  final ExamSession session;
  final SessionHostViewModel viewModel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finished = session.status == SessionStatus.finished;

    return Column(
      children: [
        // 영상통화는 진행 중·완료 후 모두 같은 위치에 유지해 끊기지 않게 한다.
        CallPanel(
          key: const ValueKey('monitor-call'),
          sessionId: session.id,
          isCaller: true,
        ),
        if (finished) ...[
          ExamScoreBanner(
            score: viewModel.correctCount,
            total: session.total,
            name: session.guestName ?? '동생',
          ),
          Expanded(
            child: ExamReviewList(
              words: session.words,
              resolve: viewModel.answerAt,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.call_end_rounded),
                  label: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: const Text('통화 종료하고 시험 마치기'),
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${session.guestName ?? "동생"} 응시 중',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('${viewModel.submittedCount} / ${session.total}',
                    style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(12.w),
              itemCount: session.words.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                return _AnswerRow(
                  index: index,
                  word: session.words[index],
                  answer: viewModel.answerAt(index),
                  isCurrent: index == session.currentIndex,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: TextButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('시험 종료'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.index,
    required this.word,
    required this.answer,
    required this.isCurrent,
  });

  final int index;
  final WordPair word;
  final ExamAnswer? answer;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submitted = answer?.isSubmitted ?? false;
    final correct = answer?.correct == true;
    final typing = (answer?.typed ?? '').trim();

    Color? border;
    if (isCurrent) {
      border = theme.colorScheme.primary;
    }

    Widget trailing;
    if (submitted) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: correct
                ? Text(
                    answer!.submitted!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green),
                  )
                // 틀렸으면 어긋난 스펠링만 빨간색으로.
                : SpellDiffText(
                    correct: word.quizAnswer,
                    submitted: answer!.submitted!,
                    fontSize: 14.sp,
                    baseColor: AppColors.ink,
                  ),
          ),
          SizedBox(width: 6.w),
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            size: 18.sp,
            color: correct ? AppColors.green : theme.colorScheme.error,
          ),
        ],
      );
    } else if (typing.isNotEmpty) {
      trailing = Text(
        typing,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.primary,
        ),
      );
    } else {
      trailing = Text('대기', style: theme.textTheme.bodySmall);
    }

    final hasExtra = word.example.isNotEmpty || word.pronunciation.isNotEmpty;

    return InkWell(
      onTap: () => _showWordDetail(context, index + 1, word),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: border ?? theme.dividerColor,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text('${index + 1}', style: theme.textTheme.bodySmall),
            SizedBox(width: 10.w),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      word.askMeaning
                          ? '${word.english} (뜻)'
                          : word.korean,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasExtra) ...[
                    SizedBox(width: 6.w),
                    Icon(Icons.menu_book_rounded,
                        size: 15.sp, color: AppColors.pink),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Flexible(
                child:
                    Align(alignment: Alignment.centerRight, child: trailing)),
          ],
        ),
      ),
    );
  }

  /// 단어를 탭하면 영어·발음·예문을 크게 보여준다.
  /// 언니가 예문을 보고 동생에게 영상통화로 질문할 때 쓴다.
  void _showWordDetail(BuildContext context, int number, WordPair word) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('$number. ',
                style: TextStyle(fontSize: 16.sp, color: AppColors.gray)),
            Expanded(
              child: Text(word.english,
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ),
            IconButton(
              tooltip: '발음 듣기',
              icon: Icon(Icons.volume_up_rounded, color: AppColors.pink),
              onPressed: () => TtsService.speak(word.english),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('뜻  ${word.korean}',
                style: TextStyle(fontSize: 15.sp, color: AppColors.ink)),
            if (word.pronunciation.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text('발음  [${word.pronunciation}]',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.grayText)),
            ],
            if (word.example.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Text('예문',
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pink)),
              SizedBox(height: 4.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.rowBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(word.example,
                          style: TextStyle(
                              fontSize: 14.sp,
                              height: 1.4,
                              color: AppColors.grayText)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '예문 발음',
                      icon: Icon(Icons.volume_up_rounded,
                          size: 20.sp, color: AppColors.pink),
                      onPressed: () =>
                          TtsService.speak(englishLead(word.example)),
                    ),
                  ],
                ),
              ),
            ],
            if (word.example.isEmpty && word.pronunciation.isEmpty)
              Text('이 단어에는 등록된 예문·발음이 없어요.',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
