import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/widgets/word_tile.dart';
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
          itemBuilder: (context, index) =>
              WordTile(word: set.words[index], index: index + 1),
        ),
      ),
    );
  }
}
