import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../models/exam_result.dart';

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
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          children: [
            _ScoreCard(result: result),
            SizedBox(height: 20.h),
            Text('문항별 채점',
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grayText)),
            SizedBox(height: 10.h),
            for (final item in result.items) ...[
              _ItemRow(item: item),
              SizedBox(height: 8.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.guestName.isEmpty ? "동생" : result.guestName}의 점수',
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grayText)),
              SizedBox(height: 6.h),
              Text('${result.score} / ${result.total}',
                  style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pink)),
            ],
          ),
          const Spacer(),
          Container(
            width: 62.w,
            height: 62.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Text('${result.percent}%',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pink)),
          ),
        ],
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
