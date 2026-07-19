import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../../features/word_sets/models/word_pair.dart';
import 'bouncy_tap.dart';

/// 단어 한 줄: 영어 + 뜻 + 미국 발음 듣기 버튼(정확한 TTS 발음).
class WordTile extends StatelessWidget {
  const WordTile({super.key, required this.word, this.index, this.trailing});

  final WordPair word;
  final int? index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.softShadow(blur: 8, y: 3),
      ),
      child: Row(
        children: [
          if (index != null) ...[
            SizedBox(
              width: 22.w,
              child: Text('$index',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.lavender)),
            ),
          ],
          // 미국 발음 듣기.
          BouncyTap(
            onTap: () => TtsService.speak(word.english),
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: AppColors.pinkSoft.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.volume_up_rounded,
                  size: 18.sp, color: AppColors.pink),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(word.english,
                style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600)),
          ),
          SizedBox(width: 8.w),
          Text(word.korean,
              style: TextStyle(fontSize: 15.sp, color: AppColors.ink)),
          ?trailing,
        ],
      ),
    );
  }
}
