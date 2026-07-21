import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../exam/models/exam_result.dart';
import '../../exam/views/exam_result_widgets.dart';
import '../../word_sets/models/word_pair.dart';
import '../../word_sets/models/word_set.dart';
import 'flashcard_study_view.dart';
import 'self_quiz_view.dart';
import 'word_list_view.dart';

/// 지난 시험 하나를 열어 '틀린 단어'만 확인하고 공부하는 화면. (동생)
class ExamReviewStudyView extends StatelessWidget {
  const ExamReviewStudyView({super.key, required this.result});

  final ExamResult result;

  List<WordPair> get _wrongWords => [
        for (final it in result.items)
          if (!it.correct) WordPair(english: it.english, korean: it.korean),
      ];

  WordSet _wrongSet() => WordSet(
        id: 'exam-review-${result.id}',
        title: '${result.title} · 틀린 단어',
        date: DateTime.now(),
        message: '',
        words: _wrongWords,
        createdBy: '',
      );

  void _study(BuildContext context, Widget view) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => view));
  }

  @override
  Widget build(BuildContext context) {
    final wrong = _wrongWords;
    final set = _wrongSet();

    return Scaffold(
      appBar: AppBar(title: Text(result.title)),
      body: SafeArea(
        child: Column(
          children: [
            ExamScoreBanner(score: result.score, total: result.total),
            if (wrong.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(28.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎉', style: TextStyle(fontSize: 48.sp)),
                        SizedBox(height: 12.h),
                        Text('이 시험은 틀린 단어가 없어요!',
                            style: TextStyle(
                                fontSize: 15.sp, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                child: Row(
                  children: [
                    _StudyChip(
                      icon: Icons.style_rounded,
                      label: '플래시카드',
                      onTap: () =>
                          _study(context, FlashcardStudyView(set: set)),
                    ),
                    SizedBox(width: 8.w),
                    _StudyChip(
                      icon: Icons.edit_rounded,
                      label: '직접 입력',
                      onTap: () => _study(context, SelfQuizView(set: set)),
                    ),
                    SizedBox(width: 8.w),
                    _StudyChip(
                      icon: Icons.list_alt_rounded,
                      label: '목록',
                      onTap: () => _study(context, WordListView(set: set)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 4.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('틀린 단어 ${wrong.length}개',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger)),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                  itemCount: result.items.where((e) => !e.correct).length,
                  separatorBuilder: (_, _) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final wrongItems =
                        result.items.where((e) => !e.correct).toList();
                    final it = wrongItems[index];
                    return ExamReviewRow(
                      number: it.index + 1,
                      word:
                          WordPair(english: it.english, korean: it.korean),
                      submitted: it.submitted,
                      correct: false,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudyChip extends StatelessWidget {
  const _StudyChip(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22.sp, color: AppColors.pink),
              SizedBox(height: 4.h),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pink)),
            ],
          ),
        ),
      ),
    );
  }
}
