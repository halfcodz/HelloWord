import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../word_sets/models/word_pair.dart';
import '../models/exam_answer.dart';

/// 맞은 개수를 크고 또렷하게 보여주는 점수 배너. (언니·동생 공통)
class ExamScoreBanner extends StatelessWidget {
  const ExamScoreBanner({
    super.key,
    required this.score,
    required this.total,
    this.name,
  });

  final int score;
  final int total;
  final String? name;

  int get _percent => total == 0 ? 0 : ((score / total) * 100).round();

  @override
  Widget build(BuildContext context) {
    final pass = _percent >= 60;
    final accent = pass ? AppColors.green : AppColors.danger;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name == null ? '맞은 개수' : '$name · 맞은 개수',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grayText)),
                SizedBox(height: 6.h),
                // 큰 숫자로 또렷하게: 18 / 20
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$score',
                        style: TextStyle(
                            fontSize: 46.sp,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pink)),
                    SizedBox(width: 4.w),
                    Text('/ $total',
                        style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray)),
                    SizedBox(width: 6.w),
                    Text('개',
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 76.w,
            height: 76.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 3),
            ),
            child: Text('$_percent%',
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: accent)),
          ),
        ],
      ),
    );
  }
}

/// 문항별 정오답 복기 리스트. (언니·동생 공통)
class ExamReviewList extends StatelessWidget {
  const ExamReviewList({
    super.key,
    required this.words,
    required this.resolve,
    this.padding,
  });

  final List<WordPair> words;
  final ExamAnswer? Function(int index) resolve;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
      itemCount: words.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final word = words[index];
        final answer = resolve(index);
        final submitted = answer?.submitted ?? '';
        final correct = answer?.correct == true;
        return ExamReviewRow(
          number: index + 1,
          word: word,
          submitted: submitted,
          correct: correct,
        );
      },
    );
  }
}

class ExamReviewRow extends StatelessWidget {
  const ExamReviewRow({
    super.key,
    required this.number,
    required this.word,
    required this.submitted,
    required this.correct,
  });

  final int number;
  final WordPair word;
  final String submitted;
  final bool correct;

  @override
  Widget build(BuildContext context) {
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
                Text('${word.korean}  ·  ${word.english}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                SizedBox(height: 3.h),
                Text(
                  submitted.isEmpty ? '입력한 답: (빈칸)' : '입력한 답: $submitted',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
