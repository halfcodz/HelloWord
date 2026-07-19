import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../word_sets/models/word_pair.dart';
import '../models/exam_answer.dart';

/// 맞은/틀린 개수와 점수를 크고 또렷하게 보여주는 배너. (언니·동생 공통)
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

  int get _wrong => (total - score).clamp(0, total);
  int get _points => total == 0 ? 0 : ((score / total) * 100).round();

  @override
  Widget build(BuildContext context) {
    final pass = _points >= 60;
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
                if (name != null) ...[
                  Text(name!,
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grayText)),
                  SizedBox(height: 8.h),
                ],
                _StatLine(
                    label: '맞은 개수', value: score, color: AppColors.green),
                SizedBox(height: 6.h),
                _StatLine(label: '틀린 개수', value: _wrong, color: AppColors.danger),
              ],
            ),
          ),
          Container(
            width: 84.w,
            height: 84.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_points',
                    style: TextStyle(
                        fontSize: 28.sp,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: accent)),
                Text('점',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Text(label,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.grayText)),
        SizedBox(width: 8.w),
        Text('$value개',
            style: TextStyle(
                fontSize: 20.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// 문항별 정오답 복기 리스트. 틀린 문항을 위로 모아 먼저 보여준다. (언니·동생 공통)
class ExamReviewList extends StatelessWidget {
  const ExamReviewList({
    super.key,
    required this.words,
    required this.resolve,
    this.sourceTitle,
    this.padding,
  });

  final List<WordPair> words;
  final ExamAnswer? Function(int index) resolve;

  /// 이 시험(단어 세트)의 이름. 틀린 문항에 '어디서 틀렸는지'로 표시.
  final String? sourceTitle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    // (문항, 정오답)으로 묶어 틀린 것 먼저 → 맞은 것 순으로 정렬.
    final entries = <_ReviewEntry>[];
    for (var i = 0; i < words.length; i++) {
      final a = resolve(i);
      entries.add(_ReviewEntry(
        number: i + 1,
        word: words[i],
        submitted: a?.submitted ?? '',
        correct: a?.correct == true,
      ));
    }
    entries.sort((x, y) {
      if (x.correct == y.correct) return x.number.compareTo(y.number);
      return x.correct ? 1 : -1; // 틀린 것(false)이 먼저
    });

    final wrongCount = entries.where((e) => !e.correct).length;
    final children = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      // 틀린 그룹과 맞은 그룹 사이에 구분 라벨.
      if (i == 0 && wrongCount > 0) {
        children.add(_GroupLabel(text: '틀린 문제 $wrongCount개', color: AppColors.danger));
      }
      if (i == wrongCount && wrongCount < entries.length) {
        children.add(_GroupLabel(
            text: '맞은 문제 ${entries.length - wrongCount}개',
            color: AppColors.green));
      }
      children.add(ExamReviewRow(
        number: e.number,
        word: e.word,
        submitted: e.submitted,
        correct: e.correct,
        source: e.correct ? null : sourceTitle,
      ));
      children.add(SizedBox(height: 8.h));
    }

    return ListView(
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
      children: children,
    );
  }
}

class _ReviewEntry {
  _ReviewEntry({
    required this.number,
    required this.word,
    required this.submitted,
    required this.correct,
  });
  final int number;
  final WordPair word;
  final String submitted;
  final bool correct;
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 2.h, left: 2.w),
      child: Text(text,
          style: TextStyle(
              fontSize: 13.sp, fontWeight: FontWeight.w800, color: color)),
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
    this.source,
  });

  final int number;
  final WordPair word;
  final String submitted;
  final bool correct;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.green : AppColors.danger;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
            color: correct ? AppColors.border : AppColors.danger.withValues(alpha: 0.35)),
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
                if (source != null && source!.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 12.sp, color: AppColors.hint),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text('출처: $source',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.sp, color: AppColors.hint)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
