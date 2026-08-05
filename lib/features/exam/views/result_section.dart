import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../models/exam_result.dart';
import 'exam_result_detail_view.dart';

/// 홈 · 시험 결과로 들어가는 작은 카드(가로 2개). 언니·동생 공용.
class ResultNavCard extends StatelessWidget {
  const ResultNavCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  /// 두 장을 나란히 놓을 때 뒤쪽 카드를 살짝 다르게 보이게 한다.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    // 색 네모 대신 '건수'를 주인공으로 둔다.
    // 알고 싶은 건 결과가 몇 건인지이지 아이콘이 아니다.
    final accent = dark ? AppColors.purple : AppColors.pink;
    final tint = dark ? AppColors.purpleSoft : AppColors.pinkSoft;
    return Semantics(
      button: true,
      label: '$label $count건 보기',
      child: BouncyTap(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpace.md.w),
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    fontSize: 13.sp,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray,
                  ),
                ),
              ),
              SizedBox(height: AppSpace.xxs.h),
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$count',
                      style: AppTheme.tabularNumber(
                        fontSize: 30.sp,
                        color: count == 0 ? AppColors.hint : AppColors.ink,
                      ).copyWith(height: 1.0),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '건',
                      style: AppTheme.font(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpace.xs.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpace.xs.w,
                  vertical: AppSpace.xxs.h + 1,
                ),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(AppRadius.xs.r),
                ),
                child: Text(
                  '결과 보기',
                  style: AppTheme.font(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
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
                Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.gray),
                ),
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
        children.add(
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, i == 0 ? 6.h : 20.h, 16.w, 4.h),
            child: Row(
              children: [
                Text('📄', style: TextStyle(fontSize: 15.sp)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    results[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
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
