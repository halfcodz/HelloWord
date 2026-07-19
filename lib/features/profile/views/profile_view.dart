import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../models/app_user.dart';
import '../services/avatar_service.dart';

/// 내 정보 화면(토스풍). 마스코트 · 역할칩 · 설정 행.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.user});

  final AppUser user;

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: user.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이름 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '이름 (별명)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소')),
          FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('저장')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == user.name) return;
    await AuthService().updateName(uid: user.uid, name: newName);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 변경했어요!')),
      );
    }
  }

  Future<void> _changePhoto(BuildContext context) async {
    try {
      final base64 = await AvatarService.pickAndEncode();
      if (base64 == null) return;
      await AuthService().updatePhoto(uid: user.uid, base64: base64);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
              content: Text('프로필 사진을 바꿨어요!'),
              duration: Duration(seconds: 2)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
              content: Text('사진을 불러오지 못했어요.'),
              duration: Duration(seconds: 2)));
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃 할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('로그아웃')),
        ],
      ),
    );
    if (confirmed == true) await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isElder = user.role == UserRole.elder;
    final photoBytes = AvatarService.decode(user.photoBase64);

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _changePhoto(context),
              child: Stack(
                children: [
                  Container(
                    width: 84.w,
                    height: 84.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isElder
                          ? AppColors.blueSoft
                          : AppColors.orangeSoft,
                      shape: BoxShape.circle,
                      image: photoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(photoBytes),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: photoBytes != null
                        ? null
                        : Text(isElder ? '🐰' : '🐥',
                            style: TextStyle(fontSize: 44.sp)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.softShadow(blur: 6, y: 2),
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 15.sp, color: AppColors.pink),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(user.name,
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(isElder ? '언니' : '동생',
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pink)),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  _SettingRow(
                    icon: Icons.badge_outlined,
                    label: '이름 수정',
                    value: user.name,
                    onTap: () => _editName(context),
                  ),
                  _SettingRow(
                    icon: Icons.mail_outline_rounded,
                    label: '이메일',
                    value: user.email,
                  ),
                  const _ThemeToggleRow(),
                  _SettingRow(
                    icon: Icons.logout,
                    label: '로그아웃',
                    danger: true,
                    isLast: true,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 다크 모드 토글 행. 스위치로 라이트/다크를 전환한다.
class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final dark = controller.isDark;
    return InkWell(
      onTap: () => controller.setDark(!dark),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 4.w),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Icon(dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 22.sp, color: AppColors.grayText),
            SizedBox(width: 12.w),
            Text('다크 모드',
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
            const Spacer(),
            Switch.adaptive(
              value: dark,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.pink,
              onChanged: (v) => controller.setDark(v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.danger = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.grayText;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 4.w),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22.sp, color: color),
            SizedBox(width: 12.w),
            Text(label,
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: danger ? AppColors.danger : AppColors.ink)),
            const Spacer(),
            if (value != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 160.w),
                child: Text(value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.sp, color: AppColors.gray)),
              ),
            if (onTap != null && !danger) ...[
              SizedBox(width: 6.w),
              Icon(Icons.chevron_right, size: 20.sp, color: AppColors.hint),
            ],
          ],
        ),
      ),
    );
  }
}
