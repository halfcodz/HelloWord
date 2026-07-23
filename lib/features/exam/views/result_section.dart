import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../models/exam_result.dart';
import 'exam_result_detail_view.dart';

/// 홈 · 시험 결과로 들어가는 작은 카드(가로 2개). 언니·동생 공용.
class ResultNavCard extends StatelessWidget {
  const ResultNavCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.count,
    required this.onTap,
    this.dark = false,
  });

  final String emoji;
  final String label;
  final int count;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softShadow(blur: 12, y: 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dark ? AppColors.navy : null,
                    gradient: dark ? null : AppColors.primaryButton,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text('$count건',
                      style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mintDeep)),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            SizedBox(height: 3.h),
            Row(
              children: [
                Text('결과 보기',
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray)),
                Icon(Icons.chevron_right, size: 15.sp, color: AppColors.hint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 오늘 시험 결과를 바로(내용으로) 보여주는 화면.
/// 결과가 1건이면 그 내용을, 여러 건이면 제목으로 구분해 이어서 보여준다.
class TodayResultsView extends StatelessWidget {
  const TodayResultsView({
    super.key,
    required this.results,
    required this.emptyText,
  });

  final List<ExamResult> results;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('오늘 시험 결과')),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📊', style: TextStyle(fontSize: 40.sp)),
                SizedBox(height: 10.h),
                Text(emptyText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: AppColors.gray)),
              ],
            ),
          ),
        ),
      );
    }

    final title = results.length == 1 ? results.first.title : '오늘 시험 결과';
    final children = <Widget>[];
    for (var i = 0; i < results.length; i++) {
      if (results.length > 1) {
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(18.w, i == 0 ? 6.h : 20.h, 16.w, 4.h),
          child: Row(
            children: [
              Text('📄', style: TextStyle(fontSize: 15.sp)),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(results[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ),
            ],
          ),
        ));
      }
      children.addAll(ExamResultDetailView.buildResultContent(results[i]));
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 24.h),
          children: children,
        ),
      ),
    );
  }
}
