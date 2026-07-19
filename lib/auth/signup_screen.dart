import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import '../models/app_user.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  UserRole _role = UserRole.younger;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        role: _role,
      );
      if (mounted) Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 40.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('반가워요! 🌱',
                        style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    SizedBox(height: 6.h),
                    Text('정보를 입력하고 역할을 골라 주세요',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray)),
                    SizedBox(height: 24.h),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: '이름 (별명)'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이름을 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: '이메일'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이메일을 입력해 주세요.';
                        }
                        if (!value.contains('@')) {
                          return '올바른 이메일 형식이 아니에요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '비밀번호 (6자 이상)',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.hint,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해 주세요.';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 해요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),
                    Text('나의 역할',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grayText)),
                    SizedBox(height: 10.h),
                    _RolePicker(
                      role: _role,
                      onChanged: (r) => setState(() => _role = r),
                    ),
                    SizedBox(height: 28.h),
                    BlueButton(
                      label: '회원가입',
                      loading: _loading,
                      onTap: _loading ? null : _submit,
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

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            mascot: '🐰',
            label: '웅니',
            hint: '단어를 내요',
            bg: AppColors.blueSoft,
            selected: role == UserRole.elder,
            onTap: () => onChanged(UserRole.elder),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _RoleCard(
            mascot: '🐥',
            label: '동생',
            hint: '시험을 봐요',
            bg: AppColors.orangeSoft,
            selected: role == UserRole.younger,
            onTap: () => onChanged(UserRole.younger),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.mascot,
    required this.label,
    required this.hint,
    required this.bg,
    required this.selected,
    required this.onTap,
  });

  final String mascot;
  final String label;
  final String hint;
  final Color bg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : AppColors.cream,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected ? AppColors.pink : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Text(mascot, style: TextStyle(fontSize: 30.sp)),
            ),
            SizedBox(height: 10.h),
            Text(label,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.pink : AppColors.ink)),
            SizedBox(height: 2.h),
            Text(hint,
                style: TextStyle(fontSize: 12.sp, color: AppColors.gray)),
          ],
        ),
      ),
    );
  }
}
