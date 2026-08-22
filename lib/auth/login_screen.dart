import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/toast.dart';
import '../core/widgets/bouncy_tap.dart';
import 'account_avatar.dart';
import 'auth_service.dart';
import 'password_reset_sheet.dart';
import 'saved_accounts.dart';
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
  final _passwordFocus = FocusNode();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = true;
  bool _restored = false;

  /// 이 기기에서 로그인한 적 있는 계정들(얼굴 목록).
  List<SavedAccount> _accounts = const [];

  /// 비밀번호까지 저장돼 있어서 얼굴만 눌러도 들어가지는 계정들.
  Set<String> _quickUids = const {};

  /// 얼굴 목록 대신 입력 칸을 보여 줄지.
  bool _showForm = false;

  /// 얼굴을 눌러 로그인 중인 계정(그 카드에만 동그라미를 돌린다).
  String? _busyUid;

  /// 얼굴을 눌렀는데 비밀번호가 저장돼 있지 않아 한 줄만 받는 중인 계정.
  SavedAccount? _pending;

  static const _prefRemember = 'auto_login';
  static const _prefEmail = 'saved_email';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_prefRemember) ?? true;
    final email = prefs.getString(_prefEmail) ?? '';
    final accounts = await SavedAccounts.list();
    final quick = await SavedAccounts.quickLoginUids(accounts);
    if (!mounted) return;
    setState(() {
      _restored = true;
      _rememberMe = remember;
      _accounts = accounts;
      _quickUids = quick;
      _showForm = accounts.isEmpty;
      if (remember && email.isNotEmpty) _emailController.text = email;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _busy => _loading || _busyUid != null;

  /// 로그인에 성공한 뒤 이 기기에 남길 것들을 정리한다.
  /// 프로필(이름·사진)은 로그인이 끝나면 [AuthGate]가 채워 준다.
  Future<void> _afterSignIn(String uid, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRemember, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_prefEmail, email);
      await SavedAccounts.savePassword(uid, password);
    } else {
      await prefs.remove(_prefEmail);
      await SavedAccounts.forgetPassword(uid);
    }
  }

  // ── 얼굴 눌러 로그인 ────────────────────────────────────────────

  Future<void> _tapAccount(SavedAccount account) async {
    if (_busy) return;

    // 비밀번호를 저장해 두지 않은 계정은 한 줄만 받는다.
    if (!_quickUids.contains(account.uid)) {
      _askPasswordFor(account);
      return;
    }

    // 얼굴을 눌러 들어가는 건 '이 기기에 저장해 둔다'는 뜻이다.
    setState(() {
      _busyUid = account.uid;
      _rememberMe = true;
    });
    try {
      final password = await SavedAccounts.password(account.uid);
      if (password == null || password.isEmpty) {
        if (!mounted) return;
        setState(() => _quickUids = {..._quickUids}..remove(account.uid));
        _askPasswordFor(account);
        return;
      }
      final uid = await _auth.signIn(
        email: account.email,
        password: password,
      );
      await _afterSignIn(uid, account.email, password);
      // 이제 AuthGate가 알아서 홈 화면으로 넘어간다.
    } catch (error) {
      if (!mounted) return;
      if (_isCredentialError(error)) {
        // 다른 곳에서 비밀번호를 바꿨다. 저장해 둔 것을 버리고 다시 받는다.
        await SavedAccounts.forgetPassword(account.uid);
        if (!mounted) return;
        setState(() => _quickUids = {..._quickUids}..remove(account.uid));
        _askPasswordFor(account);
        showToast(context, '비밀번호가 바뀌었어요. 다시 넣어 주세요.', isError: true);
      } else {
        showToast(context, authErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyUid = null);
    }
  }

  static bool _isCredentialError(Object error) {
    if (error is! FirebaseAuthException) return false;
    return const {
      'wrong-password',
      'invalid-credential',
      'invalid-login-credentials',
      'user-not-found',
      'user-disabled',
    }.contains(error.code);
  }

  /// 얼굴은 그대로 두고 비밀번호 한 줄만 받는 화면으로 넘어간다.
  void _askPasswordFor(SavedAccount account) {
    setState(() {
      _pending = account;
      _showForm = true;
      _emailController.text = account.email;
      _passwordController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passwordFocus.requestFocus();
    });
  }

  /// 목록에 없는 계정으로 들어갈 때(이메일부터 입력).
  void _showFullForm() {
    setState(() {
      _pending = null;
      _showForm = true;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _backToAccounts() {
    setState(() {
      _pending = null;
      _showForm = false;
      _passwordController.clear();
    });
  }

  Future<void> _confirmForget(SavedAccount account) async {
    final name = account.name.isNotEmpty ? account.name : account.email;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 기기에서 지울까요?'),
        content: Text('$name 계정을 목록에서 지워요.\n계정이 없어지는 건 아니고, 다음엔 이메일부터 넣으면 돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('그냥 둘래'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await SavedAccounts.forget(account.uid);
    final accounts = await SavedAccounts.list();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _quickUids = {..._quickUids}..remove(account.uid);
      if (accounts.isEmpty) {
        _pending = null;
        _showForm = true;
      }
    });
  }

  // ── 입력해서 로그인 ─────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = (_pending?.email ?? _emailController.text).trim();
    final password = _passwordController.text;

    setState(() => _loading = true);
    try {
      final uid = await _auth.signIn(
        email: email,
        password: password,
        rememberMe: _rememberMe,
      );
      await _afterSignIn(uid, email, password);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── 화면 ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  SizedBox(height: 28.h),
                  // 저장된 계정을 읽어 오는 아주 짧은 동안에는 아무것도
                  // 그리지 않는다(얼굴 목록이 뒤늦게 끼어드는 것을 막는다).
                  if (!_restored)
                    SizedBox(height: 240.h)
                  else if (_showForm)
                    _form()
                  else
                    _accountPicker(),
                  SizedBox(height: 16.h),
                  _signupLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          width: 76.w,
          height: 76.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.pink,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
          ),
          // 로딩 화면과 같은 로고. 이모지 대신 앱에 포함된 아이콘을 쓴다.
          child:
              Icon(Icons.menu_book_rounded, size: 38.sp, color: Colors.white),
        ),
        SizedBox(height: 14.h),
        Text('HelloWord',
            style: AppTheme.display(
                fontSize: 30.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.5)),
        SizedBox(height: 6.h),
        Text('언니랑 함께하는 영어 단어 공부 ✏️',
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray)),
      ],
    );
  }

  /// 이 기기에서 로그인했던 얼굴들. 눌러서 바로 들어간다.
  Widget _accountPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('누구로 들어갈까요?',
            textAlign: TextAlign.center,
            style: AppTheme.font(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.grayText)),
        SizedBox(height: 14.h),
        for (final account in _accounts) ...[
          _AccountCard(
            account: account,
            quick: _quickUids.contains(account.uid),
            busy: _busyUid == account.uid,
            disabled: _busy && _busyUid != account.uid,
            onTap: () => _tapAccount(account),
            onRemove: () => _confirmForget(account),
          ),
          SizedBox(height: 10.h),
        ],
        SizedBox(height: 4.h),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _busy ? null : _showFullForm,
          child: Container(
            height: 52.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(AppRadius.md.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1_outlined,
                    size: 18.sp, color: AppColors.pink),
                SizedBox(width: 8.w),
                Text('다른 계정으로 로그인',
                    style: AppTheme.font(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pink)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 이메일·비밀번호 입력 칸. 얼굴을 눌러 들어온 경우엔 비밀번호만 받는다.
  Widget _form() {
    final pending = _pending;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_accounts.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _busy ? null : _backToAccounts,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12.h, right: 8.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left_rounded,
                          size: 20.sp, color: AppColors.gray),
                      Text('저장된 계정',
                          style: AppTheme.font(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray)),
                    ],
                  ),
                ),
              ),
            ),
          if (pending != null) ...[
            Column(
              children: [
                AccountAvatar(
                  size: 64.w,
                  photoBase64: pending.photoBase64,
                  role: pending.role,
                  name: pending.name,
                ),
                SizedBox(height: 10.h),
                Text(pending.name.isNotEmpty ? pending.name : pending.email,
                    style: AppTheme.display(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
                SizedBox(height: 2.h),
                Text('비밀번호만 넣으면 돼요',
                    style: AppTheme.font(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray)),
              ],
            ),
            SizedBox(height: 18.h),
          ] else ...[
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
          ],
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _busy ? null : _submit(),
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
          SizedBox(height: 14.h),
          _RememberToggle(
            value: _rememberMe,
            onChanged: _busy ? null : (v) => setState(() => _rememberMe = v),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: 30.w),
            child: Text('이 기기에 저장해 두고, 다음엔 얼굴만 눌러서 들어와요.',
                style: AppTheme.font(fontSize: 12.sp, color: AppColors.hint)),
          ),
          SizedBox(height: 16.h),
          BlueButton(
            label: '로그인',
            loading: _loading,
            onTap: _busy ? null : _submit,
          ),
          SizedBox(height: 14.h),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _busy
                ? null
                : () => showPasswordResetSheet(
                      context,
                      initialEmail:
                          (_pending?.email ?? _emailController.text).trim(),
                    ),
            child: Text('비밀번호가 기억 안 나요',
                textAlign: TextAlign.center,
                style: AppTheme.font(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray)),
          ),
        ],
      ),
    );
  }

  Widget _signupLink() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _busy
          ? null
          : () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SignupScreen())),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
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
                    color: AppColors.pink, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 저장된 계정 한 줄. 얼굴 · 이름 · 이메일과 지우기 버튼.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.quick,
    required this.busy,
    required this.disabled,
    required this.onTap,
    required this.onRemove,
  });

  final SavedAccount account;

  /// 비밀번호까지 저장돼 있어 누르면 바로 들어가는 계정인지.
  final bool quick;
  final bool busy;
  final bool disabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = account.name.isNotEmpty ? account.name : account.email;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: BouncyTap(
        onTap: disabled || busy ? null : onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 6.w, 12.h),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.softShadow(blur: 10, y: 3),
          ),
          child: Row(
            children: [
              AccountAvatar(
                size: 46.w,
                photoBase64: account.photoBase64,
                role: account.role,
                name: account.name,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    SizedBox(height: 2.h),
                    Text(
                      quick ? '눌러서 바로 들어가기' : '비밀번호를 한 번 넣어 주세요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: quick ? AppColors.pink : AppColors.gray),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              if (busy)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(AppColors.pink),
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: disabled ? null : onRemove,
                  icon: Icon(Icons.close_rounded,
                      size: 18.sp, color: AppColors.hint),
                  tooltip: '이 기기에서 지우기',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 자동 로그인 토글. 체크박스 + 라벨을 탭하면 켜고 끈다.
class _RememberToggle extends StatelessWidget {
  const _RememberToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22.w,
            height: 22.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: value ? AppColors.pink : AppColors.cream,
              borderRadius: BorderRadius.circular(7.r),
              border: Border.all(
                color: value ? AppColors.pink : AppColors.border,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check, size: 15.sp, color: Colors.white)
                : null,
          ),
          SizedBox(width: 8.w),
          Text('자동 로그인',
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grayText)),
        ],
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.border : AppColors.pink,
          borderRadius: BorderRadius.circular(AppRadius.md.r),
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
                style: AppTheme.font(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: onTap == null ? AppColors.hint : Colors.white)),
      ),
    );
  }
}
