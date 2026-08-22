import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/profile/services/avatar_service.dart';
import '../models/app_user.dart';

/// 저장된 계정의 동그란 얼굴.
///
/// 프로필 사진이 있으면 사진을, 없으면 역할 마스코트(🐰/🐥)를 보여 준다.
/// 역할도 모르면 이름 첫 글자를 쓴다.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    super.key,
    required this.size,
    this.photoBase64,
    this.role,
    this.name = '',
  });

  final double size;
  final String? photoBase64;
  final UserRole? role;
  final String name;

  @override
  Widget build(BuildContext context) {
    final photo = AvatarService.decode(photoBase64);
    final background =
        role == UserRole.younger ? AppColors.orangeSoft : AppColors.blueSoft;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        image: photo != null
            ? DecorationImage(image: MemoryImage(photo), fit: BoxFit.cover)
            : null,
      ),
      child: photo != null ? null : _fallback(),
    );
  }

  Widget _fallback() {
    if (role != null) {
      return Text(role!.mascot, style: TextStyle(fontSize: size * 0.52));
    }
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Text(
      initial,
      style: AppTheme.display(
        fontSize: size * 0.42,
        fontWeight: FontWeight.w700,
        color: AppColors.pink,
      ),
    );
  }
}
