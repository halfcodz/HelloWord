import 'package:flutter/material.dart';
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
import 'exam_result_widgets.dart';

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
  int _shownIndex = -1;
  bool _leaving = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  /// 현재 문제로 이동할 때 입력칸을 그 문제의 저장된 답으로 채운다.
  void _syncField(SessionExamViewModel vm) {
    if (_shownIndex != vm.currentIndex) {
      _shownIndex = vm.currentIndex;
      _answerController.text = vm.submittedTextAt(vm.currentIndex);
    }
  }

  Future<void> _goPrev(SessionExamViewModel vm) async {
    await vm.saveAnswer(_answerController.text);
    vm.goTo(vm.currentIndex - 1);
  }

  Future<void> _goNext(SessionExamViewModel vm) async {
    await vm.saveAnswer(_answerController.text);
    vm.goTo(vm.currentIndex + 1);
  }

  Future<void> _finish(SessionExamViewModel vm) async {
    await vm.saveAnswer(_answerController.text);
    if (!mounted) return;
    if (!vm.allAnswered) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('아직 안 푼 문제가 있어요'),
          content: Text(
              '${vm.total - vm.submittedCount}문제가 비어 있어요. 그래도 완료할까요?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('더 풀기')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('완료')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await vm.finishExam();
  }

  Future<void> _confirmQuit(SessionExamViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시험에서 나갈까요?'),
        content: const Text('나가면 카메라·마이크가 꺼지고 홈으로 이동해요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('나가기')),
        ],
      ),
    );
    if (ok == true) {
      await vm.endSession();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  /// 언니가 종료해 세션이 사라지면 자동으로 홈으로 나간다.
  void _leaveHome() {
    if (_leaving) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SessionExamViewModel>();
    final session = vm.session;

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.title ?? '시험'),
        automaticallyImplyLeading: false,
        actions: [
          if (session != null) ...[
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
            if (!vm.isFinished)
              IconButton(
                tooltip: '나가기',
                icon: const Icon(Icons.logout),
                onPressed: () => _confirmQuit(vm),
              ),
          ],
        ],
      ),
      body: SafeArea(child: _buildBody(context, vm, session)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SessionExamViewModel vm,
    ExamSession? session,
  ) {
    if (!vm.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (session == null) {
      _leaveHome();
      return const Center(child: CircularProgressIndicator());
    }

    // 영상통화는 응시 중·완료 후 모두 같은 위치에 유지해 끊기지 않게 한다.
    return Column(
      children: [
        CallPanel(
          key: const ValueKey('exam-call'),
          sessionId: session.id,
          isCaller: false,
        ),
        Expanded(
          child: vm.isFinished
              ? _buildFinished(vm, session)
              : _buildActive(vm, session),
        ),
      ],
    );
  }

  Widget _buildActive(SessionExamViewModel vm, ExamSession session) {
    _syncField(vm);
    final word = vm.currentWord;
    if (word == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final isLast = vm.currentIndex + 1 == vm.total;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: vm.total == 0 ? 0 : (vm.currentIndex + 1) / vm.total,
            minHeight: 5.h,
            backgroundColor: AppColors.fieldBg,
            valueColor: AlwaysStoppedAnimation(AppColors.pink),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 4.h),
                Text('${vm.currentIndex + 1} / ${vm.total}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray)),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 34.h),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow(),
                  ),
                  child: Column(
                    children: [
                      Text('이 뜻의 영어 단어는?',
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.hint)),
                      SizedBox(height: 14.h),
                      Text(word.korean,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: _answerController,
                  autofocus: true,
                  textInputAction:
                      isLast ? TextInputAction.done : TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(hintText: '영어로 입력'),
                  onChanged: vm.onTyped,
                  onSubmitted: (_) => isLast ? _finish(vm) : _goNext(vm),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: vm.currentIndex > 0
                            ? () => _goPrev(vm)
                            : null,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('이전'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.grayText,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isLast ? null : () => _goNext(vm),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('다음'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                GradientButton(
                  label: '시험 완료 🎉',
                  icon: Icons.check_rounded,
                  onPressed: () => _finish(vm),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinished(SessionExamViewModel vm, ExamSession session) {
    return Column(
      children: [
        ExamScoreBanner(score: vm.correctCount, total: session.total),
        Expanded(
          child: ExamReviewList(
            words: session.words,
            resolve: vm.answerAt,
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text('언니가 시험을 마치면 홈으로 이동해요',
                    style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
