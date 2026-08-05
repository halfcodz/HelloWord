import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../../call/views/call_panel.dart';
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
      // 정리(답안·세션 삭제)를 기다리지 않고 곧바로 화면을 닫는다.
      final closing = vm.endSession();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      unawaited(closing.catchError((Object _) {}));
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
          if (session != null && !vm.isFinished) ...[
            IconButton(
              tooltip: '나가기',
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmQuit(vm),
            ),
            Padding(
              padding: EdgeInsets.only(right: 10.w, top: 8.h, bottom: 8.h),
              child: FilledButton(
                onPressed: () => _finish(vm),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                ),
                child: const Text('완료',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
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

    // 답을 쓰는 동안에는(키보드가 열리면) 영상을 접어 문제·입력칸에 화면을 다 준다.
    // 통화는 그대로 유지되고, 키보드를 내리면 다시 펼쳐진다.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final callHeight = (!vm.isFinished && keyboardOpen) ? 0.0 : 260.h;

    // 바깥(입력칸 밖)을 터치하면 키보드를 내린다.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // 영상통화는 응시 중·완료 후 모두 같은 위치에 유지해 끊기지 않게 한다.
          CallPanel(
            key: const ValueKey('exam-call'),
            sessionId: session.id,
            isCaller: false,
            height: callHeight,
          ),
          Expanded(
            child: vm.isFinished
                ? _buildFinished(vm, session)
                : _buildActive(vm, keyboardOpen),
          ),
        ],
      ),
    );
  }

  Widget _buildActive(SessionExamViewModel vm, bool keyboardOpen) {
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
        // 문제(뜻)는 위쪽에서 스크롤로 보여준다.
        // 키보드가 열리면 문제 카드가 입력칸 바로 위에 붙도록 아래쪽으로 정렬해,
        // 스크롤하지 않아도 '문제 + 내가 쓴 답'이 한눈에 보이게 한다.
        Expanded(
          child: SingleChildScrollView(
            reverse: keyboardOpen,
            padding: EdgeInsets.fromLTRB(
              20.w,
              keyboardOpen ? 6.h : 14.h,
              20.w,
              8.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${vm.currentIndex + 1} / ${vm.total}',
                    textAlign: TextAlign.center,
                    style: AppTheme.tabularNumber(
                        fontSize: 14.sp, color: AppColors.gray)),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: 20.w, vertical: keyboardOpen ? 16.h : 24.h),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow(),
                  ),
                  child: Column(
                    children: [
                      Text(word.quizHint,
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.hint)),
                      SizedBox(height: 12.h),
                      // 문제로 나온 단어는 제목용 폰트로 크게.
                      Text(word.quizPrompt,
                          textAlign: TextAlign.center,
                          style: AppTheme.display(
                              fontSize: keyboardOpen ? 24.sp : 30.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 입력칸을 키보드 '바로 위'에 고정해 무엇을 쓰는지 항상 보이게 한다.
        _InputBar(
          controller: _answerController,
          hintText: word.quizInputHint,
          compact: keyboardOpen,
          canPrev: vm.currentIndex > 0,
          isLast: isLast,
          onPrev: () => _goPrev(vm),
          onNext: () => _goNext(vm),
          onTyped: vm.onTyped,
          onSubmitted: () => isLast ? _finish(vm) : _goNext(vm),
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

/// 시험 입력 바. 입력칸을 키보드 바로 위에 고정하고, 위에 이전/다음/완료 버튼을 둔다.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.hintText,
    required this.canPrev,
    required this.isLast,
    required this.compact,
    required this.onPrev,
    required this.onNext,
    required this.onTyped,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool canPrev;
  final bool isLast;

  /// 키보드가 열려 있을 때는 여백을 줄여 문제를 더 많이 보여준다.
  final bool compact;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<String> onTyped;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              14.w, compact ? 8.h : 12.h, 14.w, compact ? 10.h : 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 입력칸을 먼저(위) 두어 무엇을 쓰는지 잘 보이게 한다.
              // 키보드가 올라와도 이 줄은 항상 키보드 바로 위에 남는다.
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction:
                    isLast ? TextInputAction.done : TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                decoration: InputDecoration(hintText: hintText),
                onChanged: onTyped,
                onSubmitted: (_) => onSubmitted(),
              ),
              SizedBox(height: compact ? 8.h : 10.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canPrev ? onPrev : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: compact ? 9.h : 11.h),
                        side: BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.grayText,
                      ),
                      child: const Text('← 이전'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLast ? null : onNext,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: compact ? 9.h : 11.h),
                      ),
                      child: const Text('다음 →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
