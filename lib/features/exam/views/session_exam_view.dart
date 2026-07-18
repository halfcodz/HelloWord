import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../models/app_user.dart';
import '../../call/views/call_panel.dart';
import '../../chat/views/chat_view.dart';
import '../models/exam_session.dart';
import '../repositories/exam_repository.dart';
import '../viewmodels/session_exam_viewmodel.dart';

/// 동생(응시자)의 시험 응시 화면.
class SessionExamView extends StatelessWidget {
  const SessionExamView({
    super.key,
    required this.sessionId,
    required this.user,
  });

  final String sessionId;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SessionExamViewModel(
        repository: context.read<ExamRepository>(),
        sessionId: sessionId,
      ),
      child: _ExamBody(user: user),
    );
  }
}

class _ExamBody extends StatefulWidget {
  const _ExamBody({required this.user});

  final AppUser user;

  @override
  State<_ExamBody> createState() => _ExamBodyState();
}

class _ExamBodyState extends State<_ExamBody> {
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit(SessionExamViewModel viewModel) async {
    if (_answerController.text.trim().isEmpty) return;
    await viewModel.submit(_answerController.text);
    _answerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SessionExamViewModel>();
    final session = viewModel.session;

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.title ?? '시험'),
        automaticallyImplyLeading: false,
        actions: [
          if (session != null && !viewModel.isFinished)
            IconButton(
              tooltip: '채팅',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatView(
                    myUid: widget.user.uid,
                    otherUid: session.hostUid,
                    otherName: session.hostName,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, viewModel, session)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SessionExamViewModel viewModel,
    ExamSession? session,
  ) {
    if (!viewModel.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (session == null) {
      // 언니가 시험을 닫아 세션이 사라진 경우.
      return _ClosedView();
    }

    if (viewModel.isFinished) {
      return _ResultView(
        score: session.score ?? viewModel.correctCount,
        total: session.total,
      );
    }

    final word = viewModel.currentWord;
    if (word == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    return Column(
      children: [
        // 시험 보는 동안 언니와 영상통화.
        CallPanel(sessionId: session.id, isCaller: false),
        LinearProgressIndicator(
          value: session.total == 0
              ? 0
              : viewModel.currentIndex / session.total,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 8.h),
                Text(
                  '${viewModel.currentIndex + 1} / ${session.total}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 24.h),
                Container(
                  key: ValueKey(viewModel.currentIndex),
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: AppColors.softShadow(),
                  ),
                  child: Column(
                    children: [
                      Text('이 뜻의 영어 단어는? 🤔',
                          style: TextStyle(
                              fontSize: 13.sp, color: AppColors.lavender)),
                      SizedBox(height: 14.h),
                      Text(
                        word.korean,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30.sp, color: AppColors.ink),
                      ),
                    ],
                  ),
                )
                    .animate(key: ValueKey(viewModel.currentIndex))
                    .fadeIn(duration: 300.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                SizedBox(height: 24.h),
                TextField(
                  controller: _answerController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: '영어로 입력',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: viewModel.onTyped,
                  onSubmitted: (_) => _submit(viewModel),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: GradientButton(
              label: viewModel.currentIndex + 1 == session.total
                  ? '제출하고 완료 🎉'
                  : '제출',
              icon: Icons.send_rounded,
              onPressed: () => _submit(viewModel),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎉', style: TextStyle(fontSize: 72.sp))
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
          SizedBox(height: 16.h),
          Text('시험 완료!',
              style: TextStyle(fontSize: 24.sp, color: AppColors.ink)),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
            decoration: BoxDecoration(
              gradient: AppColors.primaryButton,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: AppColors.softShadow(),
            ),
            child: Text(
              '$score / $total 개 맞았어요',
              style: TextStyle(fontSize: 22.sp, color: Colors.white),
            ),
          ),
          SizedBox(height: 40.h),
          SizedBox(
            width: 200.w,
            child: GradientButton(
              label: '홈으로',
              icon: Icons.home_rounded,
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _ClosedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🌙', style: TextStyle(fontSize: 56.sp)),
          SizedBox(height: 16.h),
          Text('시험이 종료되었어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: AppColors.ink)),
          SizedBox(height: 28.h),
          SizedBox(
            width: 200.w,
            child: GradientButton(
              label: '홈으로',
              icon: Icons.home_rounded,
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
        ],
      ),
    );
  }
}
