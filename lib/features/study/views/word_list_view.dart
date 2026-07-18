import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../word_sets/models/word_set.dart';

/// 단어 세트의 전체 단어를 목록으로 확인(읽기 전용).
class WordListView extends StatelessWidget {
  const WordListView({super.key, required this.set});

  final WordSet set;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(set.title)),
      body: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: set.words.length,
          separatorBuilder: (_, _) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final word = set.words[index];
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: AppColors.softShadow(blur: 8, y: 3),
              ),
              child: Row(
                children: [
                  Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.lavender)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(word.english,
                        style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text(word.korean,
                      style:
                          TextStyle(fontSize: 15.sp, color: AppColors.ink)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
