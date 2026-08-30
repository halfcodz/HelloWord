import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// 순서를 무작위로 섞을지 정하는 작은 알약 토글.
/// 공부 화면의 필터 칩 줄 옆에 붙여 쓴다.
class ShuffleChip extends StatelessWidget {
  const ShuffleChip({
    super.key,
    required this.on,
    required this.onChanged,
    this.label = '무작위',
  });

  final bool on;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: on ? AppColors.purple : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shuffle_rounded,
              size: 15.sp,
              color: on ? Colors.white : AppColors.grayText,
            ),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : AppColors.grayText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 설명이 붙은 한 줄짜리 무작위 토글(스위치 모양).
/// 출제 화면처럼 자리가 넉넉한 곳에서 쓴다.
class ShuffleToggleRow extends StatelessWidget {
  const ShuffleToggleRow({
    super.key,
    required this.on,
    required this.onChanged,
    required this.title,
    required this.hint,
  });

  final bool on;
  final ValueChanged<bool> onChanged;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: on ? AppColors.purpleSoft : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(AppRadius.md.r),
          border: Border.all(
            color: on ? AppColors.purple : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.shuffle_rounded,
              size: 18.sp,
              color: on ? AppColors.purple : AppColors.gray,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: on ? AppColors.purple : AppColors.grayText,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hint,
                    style: TextStyle(fontSize: 11.sp, color: AppColors.gray),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _MiniSwitch(on: on),
          ],
        ),
      ),
    );
  }
}

/// 켜짐/꺼짐만 보여주는 작은 스위치 모양(탭은 부모가 받는다).
class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      width: 42.w,
      height: 24.h,
      padding: EdgeInsets.all(2.w),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? AppColors.purple : AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
      ),
      child: Container(
        width: 20.w,
        height: 20.h,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.18),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
