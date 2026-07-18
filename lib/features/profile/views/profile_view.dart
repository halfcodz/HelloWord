import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../models/app_user.dart';
import '../services/avatar_service.dart';

/// 내 정보 화면. 이름 수정과 로그아웃을 제공한다.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.user});

  final AppUser user;

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: user.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이름 수정 ✏️'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '이름 (별명)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('저장'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 사진을 바꿨어요! 📸')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러오지 못했어요.')),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃 할까요? 👋'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              BouncyTap(
                onTap: () => _changePhoto(context),
                child: Stack(
                  children: [
                    Container(
                      width: 110.w,
                      height: 110.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: user.photoBase64 == null
                            ? AppColors.primaryButton
                            : null,
                        shape: BoxShape.circle,
                        image: photoBytes != null
                            ? DecorationImage(
                                image: MemoryImage(photoBytes),
                                fit: BoxFit.cover)
                            : null,
                        boxShadow: AppColors.softShadow(),
                      ),
                      child: photoBytes != null
                          ? null
                          : Text(isElder ? '👩‍🏫' : '🧒',
                              style: TextStyle(fontSize: 52.sp)),
                    ),
                    Positioned(
                      right: 2.w,
                      bottom: 2.h,
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softShadow(blur: 6, y: 2),
                        ),
                        child: Icon(Icons.camera_alt_rounded,
                            size: 16.sp, color: AppColors.pink),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Text(user.name,
                  style: TextStyle(fontSize: 24.sp, color: AppColors.ink)),
              SizedBox(height: 6.h),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.lavenderSoft,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(isElder ? '언니 (출제자)' : '동생 (응시자)',
                    style: TextStyle(fontSize: 13.sp, color: AppColors.ink)),
              ),
              SizedBox(height: 32.h),
              _InfoTile(
                icon: Icons.badge_outlined,
                label: '이름',
                value: user.name,
                trailing: Icons.edit_outlined,
                onTap: () => _editName(context),
              ),
              SizedBox(height: 12.h),
              _InfoTile(
                icon: Icons.email_outlined,
                label: '이메일',
                value: user.email,
              ),
              SizedBox(height: 20.h),
              const _ThemePickerCard(),
              SizedBox(height: 20.h),
              _InfoTile(
                icon: Icons.logout,
                label: '로그아웃',
                value: '계정에서 나가기',
                danger: true,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final IconData? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Theme.of(context).colorScheme.error : AppColors.pink;
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: AppColors.softShadow(blur: 14, y: 6),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.lavender)),
                  SizedBox(height: 2.h),
                  Text(value,
                      style: TextStyle(fontSize: 15.sp, color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 18.sp, color: AppColors.lavender),
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right, size: 20.sp, color: AppColors.lavender),
          ],
        ),
      ),
    );
  }
}

/// 테마 색상 선택 카드.
class _ThemePickerCard extends StatelessWidget {
  const _ThemePickerCard();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppColors.softShadow(blur: 14, y: 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20.sp, color: AppColors.pink),
              SizedBox(width: 10.w),
              Text('테마 색상',
                  style: TextStyle(fontSize: 15.sp, color: AppColors.ink)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final palette in AppPalette.values)
                _SwatchButton(
                  palette: palette,
                  selected: controller.palette == palette,
                  onTap: () => controller.setPalette(palette),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: palette.swatch,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.ink : Colors.white,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.swatch.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: selected
                ? Icon(Icons.check, color: Colors.white, size: 20.sp)
                : null,
          ),
          SizedBox(height: 4.h),
          Text(palette.label,
              style: TextStyle(fontSize: 10.sp, color: AppColors.ink)),
        ],
      ),
    );
  }
}
