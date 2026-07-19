import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../call/views/call_panel.dart';
import '../../chat/views/chat_view.dart';
import '../../word_sets/models/word_pair.dart';
import '../models/exam_answer.dart';
import '../models/exam_session.dart';
import '../repositories/exam_repository.dart';
import '../viewmodels/session_host_viewmodel.dart';

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
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SessionHostViewModel>();
    final session = viewModel.session;

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.title ?? '시험 감독'),
        actions: [
          if (session?.guestUid != null)
            IconButton(
              tooltip: '채팅',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatView(
                    myUid: session!.hostUid,
                    otherUid: session.guestUid!,
                    otherName: session.guestName ?? '동생',
                  ),
                ),
              ),
            ),
        ],
      ),
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
          joinCode: session.joinCode,
          onCancel: () => _confirmClose(
            context,
            viewModel,
            title: '시험을 취소할까요?',
            message: '아직 동생이 참여하지 않았어요.',
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
                ? '시험을 닫을까요?'
                : '시험을 종료할까요?',
            message: session.status == SessionStatus.finished
                ? '결과를 닫고 목록으로 돌아갑니다.'
                : '진행 중인 시험을 종료합니다.',
          ),
        );
    }
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({required this.joinCode, required this.onCancel});

  final String joinCode;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('동생에게 이 코드를 알려주세요',
              style: TextStyle(fontSize: 16.sp, color: AppColors.ink)),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 24.h),
            decoration: BoxDecoration(
              gradient: AppColors.primaryButton,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: AppColors.softShadow(),
            ),
            child: Text(
              joinCode,
              style: TextStyle(
                fontSize: 44.sp,
                letterSpacing: 8.w,
                color: Colors.white,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.04, 1.04),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 16.h,
                width: 16.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12.w),
              Text('동생이 참여하길 기다리는 중…',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
          SizedBox(height: 40.h),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('시험 취소'),
          ),
        ],
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
        // 시험 진행 중에는 동생과 영상통화.
        if (!finished)
          CallPanel(sessionId: session.id, isCaller: true),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          color: finished
              ? theme.colorScheme.tertiaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    finished
                        ? '시험 완료'
                        : '${session.guestName ?? "동생"} 응시 중',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${viewModel.submittedCount} / ${session.total}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '맞은 개수: ${viewModel.correctCount}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
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
                isCurrent: !finished && index == session.currentIndex,
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: finished
                ? FilledButton(
                    onPressed: onClose,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: const Text('닫기'),
                    ),
                  )
                : TextButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('시험 종료'),
                  ),
          ),
        ),
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
          Text(
            answer!.submitted!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: correct ? Colors.green.shade700 : theme.colorScheme.error,
            ),
          ),
          SizedBox(width: 6.w),
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            size: 18.sp,
            color: correct ? Colors.green.shade700 : theme.colorScheme.error,
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

    return Container(
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
          Text('${index + 1}',
              style: theme.textTheme.bodySmall),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              word.korean,
              style: theme.textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(child: Align(alignment: Alignment.centerRight, child: trailing)),
        ],
      ),
    );
  }
}
