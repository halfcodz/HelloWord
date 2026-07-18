import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../models/app_user.dart';
import '../repositories/exam_repository.dart';
import '../viewmodels/session_join_viewmodel.dart';
import 'session_exam_view.dart';

/// 동생(응시자)이 코드로 시험에 참여하는 화면.
class SessionJoinView extends StatelessWidget {
  const SessionJoinView({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SessionJoinViewModel(
        repository: context.read<ExamRepository>(),
        user: user,
      ),
      child: _JoinBody(user: user),
    );
  }
}

class _JoinBody extends StatefulWidget {
  const _JoinBody({required this.user});

  final AppUser user;

  @override
  State<_JoinBody> createState() => _JoinBodyState();
}

class _JoinBodyState extends State<_JoinBody> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join(SessionJoinViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    final sessionId = await viewModel.join(_codeController.text);
    if (!mounted || sessionId == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionExamView(sessionId: sessionId, user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SessionJoinViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('시험 참여')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24.h),
              Icon(Icons.vpn_key_outlined,
                  size: 56.sp, color: theme.colorScheme.primary),
              SizedBox(height: 16.h),
              Text(
                '언니가 알려준 6자리 코드를 입력하세요',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 32.h),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12.w,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '● ● ● ● ● ●',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _join(viewModel),
              ),
              if (viewModel.error != null) ...[
                SizedBox(height: 12.h),
                Text(
                  viewModel.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              SizedBox(height: 24.h),
              FilledButton(
                onPressed: viewModel.loading ? null : () => _join(viewModel),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: viewModel.loading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('참여하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
