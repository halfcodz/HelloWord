import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../../features/word_sets/models/word_pair.dart';
import 'bouncy_tap.dart';

/// 문자열에서 앞쪽 영어 부분만 추출(예문의 한글 해석 제외)해 TTS로 읽히기 위함.
String englishLead(String text) {
  final idx = text.indexOf(RegExp('[가-힣]'));
  final head = idx > 0 ? text.substring(0, idx) : (idx == 0 ? '' : text);
  return head.trim().isEmpty ? text.trim() : head.trim();
}

/// 단어 한 줄: 영어 + 뜻 + 발음 표기 + 예문 + 미국 발음 듣기 버튼(TTS).
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
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppColors.softShadow(blur: 8, y: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (index != null) ...[
                SizedBox(
                  width: 22.w,
                  child: Text('$index',
                      style:
                          TextStyle(fontSize: 12.sp, color: AppColors.gray)),
                ),
              ],
              // 단어 미국 발음 듣기.
              _SpeakButton(text: word.english),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(word.english,
                        style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700)),
                    if (word.pronunciation.isNotEmpty)
                      Text('[${word.pronunciation}]',
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.gray)),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(word.korean,
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
              ?trailing,
            ],
          ),
          if (word.example.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.rowBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SpeakButton(text: englishLead(word.example), small: true),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(word.example,
                        style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.35,
                            color: AppColors.grayText)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 미국 발음 재생 버튼.
class _SpeakButton extends StatelessWidget {
  const _SpeakButton({required this.text, this.small = false});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 28.w : 34.w;
    return BouncyTap(
      onTap: () => TtsService.speak(text),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.volume_up_rounded,
            size: small ? 15.sp : 18.sp, color: AppColors.pink),
      ),
    );
  }
}
