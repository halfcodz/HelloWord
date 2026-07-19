import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import 'auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
        rememberMe: true,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 76.w,
                          height: 76.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.pink,
                            borderRadius: BorderRadius.circular(22.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pink.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text('📖', style: TextStyle(fontSize: 38.sp)),
                        ),
                        SizedBox(height: 14.h),
                        Text('HelloWord',
                            style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                letterSpacing: -0.5)),
                        SizedBox(height: 6.h),
                        Text('언니랑 함께하는 영어 단어 공부 ✏️',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray)),
                      ],
                    ),
                    SizedBox(height: 34.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(hintText: '이메일'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '이메일을 입력해 주세요.';
                        }
                        if (!v.contains('@')) return '올바른 이메일 형식이 아니에요.';
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: '비밀번호',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.hint,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                    ),
                    SizedBox(height: 16.h),
                    BlueButton(
                      label: '로그인',
                      loading: _loading,
                      onTap: _loading ? null : _submit,
                    ),
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SignupScreen())),
                      child: Text.rich(
                        TextSpan(
                          text: '처음이에요 · ',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray),
                          children: [
                            TextSpan(
                              text: '회원가입',
                              style: TextStyle(
                                  color: AppColors.pink,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 디자인의 블루 풀버튼(라운드 16 + 그림자).
class BlueButton extends StatelessWidget {
  const BlueButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.hint : AppColors.pink,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: loading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : Text(label,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
      ),
    );
  }
}
