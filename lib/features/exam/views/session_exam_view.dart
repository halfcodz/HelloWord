import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../models/app_user.dart';
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
      child: const _ExamBody(),
    );
  }
}

class _ExamBody extends StatefulWidget {
  const _ExamBody();

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
                Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 36.h),
                    child: Column(
                      children: [
                        Text('이 뜻의 영어 단어는?',
                            style: theme.textTheme.bodySmall),
                        SizedBox(height: 12.h),
                        Text(
                          word.korean,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
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
            child: FilledButton(
              onPressed: () => _submit(viewModel),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  viewModel.currentIndex + 1 == session.total ? '제출하고 완료' : '제출',
                ),
              ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎉', style: TextStyle(fontSize: 56.sp)),
          SizedBox(height: 16.h),
          Text('시험 완료!', style: theme.textTheme.headlineSmall),
          SizedBox(height: 12.h),
          Text(
            '$score / $total 개 맞았어요',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          SizedBox(height: 40.h),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              child: const Text('홈으로'),
            ),
          ),
        ],
      ),
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
          Icon(Icons.info_outline, size: 48.sp),
          SizedBox(height: 16.h),
          const Text('시험이 종료되었어요.', textAlign: TextAlign.center),
          SizedBox(height: 24.h),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('홈으로'),
          ),
        ],
      ),
    );
  }
}
