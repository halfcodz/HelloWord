import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../../features/word_sets/models/word_pair.dart';

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
      padding: EdgeInsets.symmetric(
          horizontal: AppSpace.sm.w, vertical: AppSpace.sm.h),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        border: Border.all(color: AppColors.border),
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
                      style: AppTheme.tabularNumber(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.hint)),
                ),
              ],
              // 단어 미국 발음 듣기.
              _SpeakButton(text: word.english),
              SizedBox(width: AppSpace.xs.w),
              // 영어는 항상 한 줄로(가로로) 보이게 하고, 너무 길면 살짝 축소한다.
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        // 영어 단어는 이 앱의 주인공이라 제목용 폰트로 그린다.
                        child: Text(word.english,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTheme.display(
                                fontSize: 17.sp,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (word.pronunciation.isNotEmpty)
                      Text('[${word.pronunciation}]',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                              fontSize: 12.sp, color: AppColors.gray)),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 4,
                child: Text(word.korean,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTheme.font(
                        fontSize: 15.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grayText)),
              ),
              ?trailing,
            ],
          ),
          if (word.example.isNotEmpty) ...[
            SizedBox(height: AppSpace.xs.h),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpace.xs.w, vertical: AppSpace.xs.h),
              decoration: BoxDecoration(
                color: AppColors.rowBg,
                // 바깥 카드(16) 안쪽이라 반경을 더 작게 잡아야 동심원처럼 보인다.
                borderRadius: BorderRadius.circular(AppRadius.xs.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SpeakButton(text: englishLead(word.example), small: true),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(word.example,
                        style: AppTheme.font(
                            fontSize: 13.sp,
                            height: 1.45,
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
/// iOS/웹의 SpeechSynthesis는 사용자 제스처 '안에서' 호출해야 소리가 나므로
/// onTap(탭 업)이 아니라 onTapDown(누르는 즉시)에서 재생한다.
class _SpeakButton extends StatefulWidget {
  const _SpeakButton({required this.text, this.small = false});

  final String text;
  final bool small;

  @override
  State<_SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<_SpeakButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.small ? 28.w : 34.w;
    return Semantics(
      button: true,
      label: '발음 듣기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          TtsService.speak(widget.text);
          setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        // 동그라미는 작아도 누를 수 있는 범위는 44pt로 넓힌다.
        child: SizedBox(
          width: 44.w,
          height: 44.w,
          child: Center(
            child: AnimatedScale(
              scale: _pressed ? 0.9 : 1.0,
              duration: AppMotion.fast,
              curve: AppMotion.enter,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.volume_up_rounded,
                    size: widget.small ? 15.sp : 18.sp, color: AppColors.pink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
