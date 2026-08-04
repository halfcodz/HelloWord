import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../auth/auth_service.dart';
import '../../../core/services/bgm_service.dart';
import '../../../core/services/sfx_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/toast.dart';
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
    if (context.mounted) showToast(context, '이름을 변경했어요!');
  }

  Future<void> _changePhoto(BuildContext context) async {
    try {
      final base64 = await AvatarService.pickAndEncode();
      if (base64 == null) return;
      await AuthService().updatePhoto(uid: user.uid, base64: base64);
      if (context.mounted) showToast(context, '프로필 사진을 바꿨어요!');
    } catch (_) {
      if (context.mounted) {
        showToast(context, '사진을 불러오지 못했어요.', isError: true);
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
            SizedBox(height: AppSpace.lg.h),
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    AppSpace.gutter.w, 0, AppSpace.gutter.w, AppSpace.lg.h),
                children: [
                  const _SectionLabel('계정'),
                  _SettingCard(children: [
                    _SettingRow(
                      icon: Icons.badge_outlined,
                      label: '이름',
                      value: user.name,
                      onTap: () => _editName(context),
                    ),
                    _SettingRow(
                      icon: Icons.mail_outline_rounded,
                      label: '이메일',
                      value: user.email,
                      isLast: true,
                    ),
                  ]),
                  SizedBox(height: AppSpace.lg.h),
                  const _SectionLabel('앱 설정'),
                  const _SettingCard(children: [
                    _ThemeToggleRow(),
                    _BgmToggleRow(),
                    _SfxToggleRow(),
                  ]),
                  SizedBox(height: AppSpace.lg.h),
                  _SettingCard(children: [
                    _SettingRow(
                      icon: Icons.logout_rounded,
                      label: '로그아웃',
                      danger: true,
                      isLast: true,
                      onTap: () => _confirmLogout(context),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 묶음 위에 붙는 작은 제목.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AppSpace.xxs.w, bottom: AppSpace.xs.h),
      child: Text(
        text,
        style: AppTheme.font(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.gray,
        ),
      ),
    );
  }
}

/// 설정 행들을 담는 카드. 행 사이는 카드 안쪽 구분선으로 나눈다.
class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// 스위치가 달린 설정 행(다크 모드·배경음악 공용).
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: AppSpace.sm.h, horizontal: AppSpace.md.w),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Icon(icon, size: AppIconSize.md.sp, color: AppColors.grayText),
              SizedBox(width: AppSpace.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTheme.font(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    if (description != null) ...[
                      SizedBox(height: 2.h),
                      Text(description!,
                          style: AppTheme.font(
                              fontSize: 12.sp, color: AppColors.gray)),
                    ],
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.pink,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 다크 모드 토글 행.
class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final dark = controller.isDark;
    return _SwitchRow(
      icon: dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
      label: '다크 모드',
      description: dark ? '어두운 화면으로 보고 있어요' : '밝은 화면으로 보고 있어요',
      value: dark,
      onChanged: controller.setDark,
    );
  }
}

/// 배경음악 토글 행.
class _BgmToggleRow extends StatelessWidget {
  const _BgmToggleRow();

  @override
  Widget build(BuildContext context) {
    final bgm = context.watch<BgmService>();
    return _SwitchRow(
      icon: bgm.enabled
          ? Icons.music_note_rounded
          : Icons.music_off_rounded,
      label: '배경음악',
      description: bgm.isUnavailable
          ? '이 기기에서는 소리를 낼 수 없어요'
          : '공부할 때 잔잔하게 흘러나와요 (영상통화 중엔 자동으로 꺼져요)',
      value: bgm.enabled,
      onChanged: bgm.setEnabled,
    );
  }
}

/// 버튼 효과음 토글 행.
class _SfxToggleRow extends StatelessWidget {
  const _SfxToggleRow();

  @override
  Widget build(BuildContext context) {
    final sfx = context.watch<SfxService>();
    return _SwitchRow(
      icon: sfx.enabled
          ? Icons.touch_app_rounded
          : Icons.do_not_touch_rounded,
      label: '버튼 효과음',
      description: '버튼을 누를 때 짧은 소리가 나요',
      value: sfx.enabled,
      onChanged: sfx.setEnabled,
      isLast: true,
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
        padding: EdgeInsets.symmetric(
            vertical: AppSpace.md.h, horizontal: AppSpace.md.w),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.md.sp, color: color),
            SizedBox(width: AppSpace.sm.w),
            Text(label,
                style: AppTheme.font(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
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
