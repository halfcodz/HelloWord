import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../../profile/services/avatar_service.dart';

/// 자매 마스코트 프로필 아바타(🐰 언니 · 🐥 동생).
/// - 접속 중: 초록 점 · 공부 중: 파란 테두리 + "공부중" 라벨
class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    required this.user,
    this.isMe = false,
    this.size = 52,
    this.onTap,
  });

  final AppUser user;
  final bool isMe;
  final double size;
  final VoidCallback? onTap;

  bool get _isElder => user.role == UserRole.elder;
  String get _mascot => (user.role ?? UserRole.younger).mascot;
  Color get _bg => _isElder ? AppColors.blueSoft : AppColors.orangeSoft;

  @override
  Widget build(BuildContext context) {
    final studying = user.studying && user.online;
    final photo = AvatarService.decode(user.photoBase64);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size.w,
            height: size.w,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size.w,
                  height: size.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _bg,
                    shape: BoxShape.circle,
                    image: photo != null
                        ? DecorationImage(
                            image: MemoryImage(photo), fit: BoxFit.cover)
                        : null,
                    border: studying
                        ? Border.all(color: AppColors.pink, width: 2)
                        : null,
                  ),
                  child: photo != null
                      ? null
                      : Text(_mascot,
                          style: TextStyle(fontSize: (size / 2).sp)),
                ),
                if (user.online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13.w,
                      height: 13.w,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isMe ? '나' : (studying ? '${user.name} · 공부중' : user.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: studying ? FontWeight.w700 : FontWeight.w600,
              color: studying ? AppColors.pink : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}
