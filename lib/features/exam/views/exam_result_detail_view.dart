import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../models/exam_result.dart';
import 'exam_result_widgets.dart';

/// 지난 시험의 문항별 정오답 상세. 언니가 동생의 답을 확인한다.
class ExamResultDetailView extends StatelessWidget {
  const ExamResultDetailView({super.key, required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(result.title)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 24.h),
          children: [
            ExamScoreBanner(
              score: result.score,
              total: result.total,
              name: result.guestName.isEmpty ? null : result.guestName,
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text('문항별 채점',
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grayText)),
            ),
            SizedBox(height: 10.h),
            for (final item in result.items) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _ItemRow(item: item),
              ),
              SizedBox(height: 8.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final ExamResultItem item;

  @override
  Widget build(BuildContext context) {
    final correct = item.correct;
    final color = correct ? AppColors.green : AppColors.danger;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel,
              color: color, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.english}  ·  ${item.korean}',
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                SizedBox(height: 3.h),
                Text(
                  item.submitted.isEmpty
                      ? '입력한 답: (빈칸)'
                      : '입력한 답: ${item.submitted}',
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: correct ? AppColors.gray : AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
