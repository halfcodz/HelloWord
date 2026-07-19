import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../word_sets/models/word_pair.dart';
import '../models/exam_result.dart';
import 'exam_result_widgets.dart';

/// 지난 시험의 문항별 정오답 상세. 언니가 동생의 답을 확인한다.
class ExamResultDetailView extends StatelessWidget {
  const ExamResultDetailView({super.key, required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    // 틀린 문항을 먼저(위) → 맞은 문항을 아래로 정렬.
    final items = [...result.items]..sort((a, b) {
        if (a.correct == b.correct) return a.index.compareTo(b.index);
        return a.correct ? 1 : -1;
      });
    final wrongCount = items.where((e) => !e.correct).length;

    final children = <Widget>[
      ExamScoreBanner(
        score: result.score,
        total: result.total,
        name: result.guestName.isEmpty ? null : result.guestName,
      ),
      SizedBox(height: 16.h),
    ];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (i == 0 && wrongCount > 0) {
        children.add(_label('틀린 문제 $wrongCount개', AppColors.danger));
      }
      if (i == wrongCount && wrongCount < items.length) {
        children.add(_label('맞은 문제 ${items.length - wrongCount}개', AppColors.green));
      }
      children.add(Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ExamReviewRow(
          number: item.index + 1,
          word: WordPair(english: item.english, korean: item.korean),
          submitted: item.submitted,
          correct: item.correct,
          source: item.correct ? null : result.title,
        ),
      ));
      children.add(SizedBox(height: 8.h));
    }

    return Scaffold(
      appBar: AppBar(title: Text(result.title)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 24.h),
          children: children,
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Padding(
        padding: EdgeInsets.fromLTRB(18.w, 4.h, 16.w, 8.h),
        child: Text(text,
            style: TextStyle(
                fontSize: 13.sp, fontWeight: FontWeight.w800, color: color)),
      );
}
