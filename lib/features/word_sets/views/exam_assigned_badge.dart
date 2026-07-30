import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../models/word_set.dart';

/// "이 자료는 시험에 배정했어요" 배지.
/// 자료 카드(민트 그라디언트) 위에는 [onColor]를 true로 써서 흰 톤으로 보여 준다.
class ExamAssignedBadge extends StatelessWidget {
  const ExamAssignedBadge({
    super.key,
    required this.assigned,
    this.scheduledDate,
    this.count = 1,
    this.onColor = false,
  });

  /// 자료 하나의 배정 상태로 배지를 만든다.
  factory ExamAssignedBadge.of(WordSet set, {bool onColor = false}) =>
      ExamAssignedBadge(
        assigned: set.examAssigned,
        scheduledDate: set.examScheduledDate,
        count: set.examAssignedCount,
        onColor: onColor,
      );

  /// 시험에 배정한 자료인지.
  final bool assigned;

  /// 배정한 시험의 예정일.
  final DateTime? scheduledDate;

  /// 배정 횟수.
  final int count;

  /// 색이 진한 카드 위에 올릴지(흰 반투명) 아닌지(민트 소프트).
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    if (!assigned) return const SizedBox.shrink();

    final date = scheduledDate;
    final label = date == null
        ? '시험 배정'
        : '시험 배정 · ${date.month}/${date.day}';
    final fg = onColor ? Colors.white : AppColors.mintDeep;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: onColor
            ? Colors.white.withValues(alpha: 0.24)
            : AppColors.greenSoft,
        borderRadius: BorderRadius.circular(999.r),
        border: onColor
            ? null
            : Border.all(color: AppColors.mint.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 12.sp, color: fg),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(
                  fontSize: 10.sp, fontWeight: FontWeight.w800, color: fg)),
          if (count > 1) ...[
            SizedBox(width: 3.w),
            Text('×$count',
                style: TextStyle(
                    fontSize: 10.sp, fontWeight: FontWeight.w700, color: fg)),
          ],
        ],
      ),
    );
  }
}
