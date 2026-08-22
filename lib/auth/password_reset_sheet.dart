import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import 'auth_service.dart';

/// 비밀번호를 잊었을 때 재설정 메일을 보내는 시트.
///
/// 이메일만 넣으면 파이어베이스가 '새 비밀번호 정하기' 링크를 보내 준다.
/// 앱에서 비밀번호를 알려 줄 방법은 없으므로(암호화되어 저장된다) 메일로
/// 다시 정하는 것이 가장 간단한 길이다.
Future<void> showPasswordResetSheet(
  BuildContext context, {
  String initialEmail = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PasswordResetSheet(initialEmail: initialEmail),
  );
}

class _PasswordResetSheet extends StatefulWidget {
  const _PasswordResetSheet({required this.initialEmail});

  final String initialEmail;

  @override
  State<_PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<_PasswordResetSheet> {
  late final _email = TextEditingController(text: widget.initialEmail);

  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '올바른 이메일을 넣어 주세요.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AuthService().sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 키보드 위로 올려 준다.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.gutter.w,
            AppSpace.md.h,
            AppSpace.gutter.w,
            AppSpace.md.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                ),
              ),
              SizedBox(height: AppSpace.md.h),
              if (_sent) ..._sentBody() else ..._formBody(),
              SizedBox(height: AppSpace.xs.h),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _formBody() {
    return [
      Text(
        '비밀번호가 기억 안 나요',
        style: AppTheme.display(
          fontSize: 19.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      SizedBox(height: AppSpace.xxs.h),
      Text(
        '가입할 때 쓴 이메일을 넣으면\n비밀번호를 새로 정하는 링크를 보내 줄게요.',
        style: AppTheme.font(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.gray,
          height: 1.4,
        ),
      ),
      SizedBox(height: AppSpace.md.h),
      TextField(
        controller: _email,
        autofocus: widget.initialEmail.isEmpty,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(hintText: '이메일'),
        onSubmitted: (_) => _send(),
      ),
      if (_error != null) ...[
        SizedBox(height: AppSpace.xs.h),
        Text(
          _error!,
          style: AppTheme.font(fontSize: 12.sp, color: AppColors.danger),
        ),
      ],
      SizedBox(height: AppSpace.md.h),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _sending ? null : () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ),
          SizedBox(width: AppSpace.xs.w),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('메일 보내기'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _sentBody() {
    return [
      Center(
        child: Container(
          width: 60.w,
          height: 60.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.greenSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 30.sp,
            color: AppColors.green,
          ),
        ),
      ),
      SizedBox(height: AppSpace.sm.h),
      Text(
        '메일을 보냈어요!',
        textAlign: TextAlign.center,
        style: AppTheme.display(
          fontSize: 19.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      SizedBox(height: AppSpace.xxs.h),
      Text(
        '${_email.text.trim()} 으로 보냈어요.\n메일 속 링크에서 비밀번호를 새로 정하고\n다시 로그인해 주세요.',
        textAlign: TextAlign.center,
        style: AppTheme.font(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.gray,
          height: 1.5,
        ),
      ),
      SizedBox(height: AppSpace.xxs.h),
      Text(
        '메일이 안 보이면 스팸함도 한번 봐 주세요.',
        textAlign: TextAlign.center,
        style: AppTheme.font(fontSize: 12.sp, color: AppColors.hint),
      ),
      SizedBox(height: AppSpace.md.h),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('확인'),
      ),
    ];
  }
}
