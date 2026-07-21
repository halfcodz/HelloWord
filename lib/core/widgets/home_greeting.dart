import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// 홈 상단 인사 헤더(말해보카풍). 날짜 + "○○, 안녕! 🐥" + 우측 알림.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({
    super.key,
    required this.name,
    required this.mascot,
    this.subtitle,
    this.trailing,
  });

  final String name;
  final String mascot;
  final String? subtitle;
  final Widget? trailing;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String _dateLabel() {
    final n = DateTime.now();
    return '${n.month}월 ${n.day}일 ${_weekdays[n.weekday - 1]}요일';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle ?? _dateLabel(),
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray)),
                SizedBox(height: 3.h),
                Text('$name, 안녕! $mascot',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
