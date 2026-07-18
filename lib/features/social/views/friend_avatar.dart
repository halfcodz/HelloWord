import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../../profile/services/avatar_service.dart';

/// Todomate풍 원형 프로필 아바타.
/// - 공부 중: 불꽃(🔥) 배지 + 은은한 주황 글로우
/// - 접속 중: 초록 불빛
class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    required this.user,
    this.isMe = false,
    this.onTap,
  });

  final AppUser user;
  final bool isMe;
  final VoidCallback? onTap;

  static const _palette = [
    Color(0xFFFF9EC4),
    Color(0xFFB79CED),
    Color(0xFF8FE3C8),
    Color(0xFFFFC48F),
    Color(0xFF9FC4FF),
    Color(0xFFFFB3C6),
  ];

  Color get _color {
    final seed = user.uid.isEmpty ? user.name : user.uid;
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = c + ((hash << 5) - hash);
    }
    return _palette[hash.abs() % _palette.length];
  }

  String get _initial =>
      user.name.isNotEmpty ? user.name.characters.first : '?';

  @override
  Widget build(BuildContext context) {
    final studying = user.studying && user.online;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64.w,
        child: Column(
          children: [
            SizedBox(
              width: 56.w,
              height: 56.w,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _AvatarCircle(
                    color: _color,
                    initial: _initial,
                    studying: studying,
                    photo: AvatarService.decode(user.photoBase64),
                  ),
                  // 접속 중 초록 불빛 (공부 중이 아닐 때).
                  if (user.online && !studying)
                    Positioned(
                      right: 0,
                      bottom: 2.h,
                      child: _StatusDot(color: const Color(0xFF4CD964)),
                    ),
                  // 공부 중 불꽃 배지.
                  if (studying)
                    Positioned(
                      right: -2.w,
                      top: -2.h,
                      child: Text('🔥', style: TextStyle(fontSize: 20.sp))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.15, 1.15),
                            duration: 600.ms,
                            curve: Curves.easeInOut,
                          ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isMe ? '나' : user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.sp, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.color,
    required this.initial,
    required this.studying,
    this.photo,
  });

  final Color color;
  final String initial;
  final bool studying;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 52.w,
      height: 52.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        image: photo != null
            ? DecorationImage(image: MemoryImage(photo!), fit: BoxFit.cover)
            : null,
        border: Border.all(
          color: studying ? const Color(0xFFFF7A45) : Colors.white,
          width: studying ? 2.5 : 2,
        ),
        boxShadow: studying
            ? [
                BoxShadow(
                  color: const Color(0xFFFF7A45).withValues(alpha: 0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : AppColors.softShadow(blur: 8, y: 3),
      ),
      child: photo != null
          ? null
          : Text(
              initial,
              style: TextStyle(
                fontSize: 20.sp,
                color: Colors.white,
              ),
            ),
    );

    if (!studying) return circle;
    return circle
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .boxShadow(
          begin: BoxShadow(
            color: const Color(0xFFFF7A45).withValues(alpha: 0.3),
            blurRadius: 8,
          ),
          end: BoxShadow(
            color: const Color(0xFFFF7A45).withValues(alpha: 0.7),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          duration: 700.ms,
        );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14.w,
      height: 14.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
