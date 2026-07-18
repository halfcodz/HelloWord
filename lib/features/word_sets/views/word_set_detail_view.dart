import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/date_format.dart';
import '../models/word_set.dart';

/// 저장된 단어 세트의 상세(단어 목록) 화면.
class WordSetDetailView extends StatelessWidget {
  const WordSetDetailView({super.key, required this.set});

  final WordSet set;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(set.title)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(formatYmd(set.date), style: theme.textTheme.bodyMedium),
                    SizedBox(width: 12.w),
                    Icon(Icons.style_outlined, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text('${set.wordCount}개', style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (set.message.trim().isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    '💬 ${set.message}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: set.words.length,
              separatorBuilder: (_, _) => Divider(height: 1.h),
              itemBuilder: (context, index) {
                final word = set.words[index];
                return ListTile(
                  dense: true,
                  leading: Text(
                    '${index + 1}',
                    style: theme.textTheme.bodySmall,
                  ),
                  title: Text(
                    word.english,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    word.korean,
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
