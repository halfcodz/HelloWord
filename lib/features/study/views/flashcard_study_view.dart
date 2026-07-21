import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../services/memorized_store.dart';
import '../widgets/memorize_filter.dart';
import '../../word_sets/models/word_pair.dart';
import '../../word_sets/models/word_set.dart';

/// 플래시카드 혼자 공부 화면. 카드를 탭하면 뜻↔영어가 뒤집힌다.
class FlashcardStudyView extends StatefulWidget {
  const FlashcardStudyView({super.key, required this.set});

  final WordSet set;

  @override
  State<FlashcardStudyView> createState() => _FlashcardStudyViewState();
}

class _FlashcardStudyViewState extends State<FlashcardStudyView> {
  MemorizeFilter _filter = MemorizeFilter.all;
  late List<WordPair> _words = applyFilter(widget.set.words, _filter);
  int _index = 0;
  bool _showKorean = false;
  int _memorized = 0;

  void _applyFilter(MemorizeFilter f) {
    setState(() {
      _filter = f;
      _words = applyFilter(widget.set.words, _filter);
      _index = 0;
      _showKorean = false;
      _memorized = 0;
    });
  }

  void _flip() => setState(() => _showKorean = !_showKorean);

  void _advance({required bool memorized}) {
    // 외운 단어 기록에 저장(안 외운 단어 모아 공부에 활용).
    MemorizedStore.setMemorized(_words[_index].english, memorized);
    if (memorized) _memorized++;
    if (_index < _words.length - 1) {
      setState(() {
        _index++;
        _showKorean = false;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('플래시카드 완료! 🎉'),
        content: Text('총 ${_words.length}개 중 $_memorized개를 외웠어요.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _shuffle() {
    setState(() {
      _words = applyFilter(widget.set.words, _filter)..shuffle();
      _index = 0;
      _showKorean = false;
      _memorized = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _words.length;
    final word = total == 0 ? null : _words[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text(total == 0 ? '플래시카드' : '${_index + 1}/$total',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: total == 0 ? null : _shuffle,
            icon: Icon(Icons.shuffle_rounded, color: AppColors.grayText),
            tooltip: '섞기',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: MemorizeFilterBar(
                  value: _filter,
                  words: widget.set.words,
                  onChanged: _applyFilter,
                ),
              ),
              SizedBox(height: 10.h),
              if (total == 0)
                Expanded(
                  child: Center(
                    child: Text(
                      _filter == MemorizeFilter.notMemorized
                          ? '안 외운 단어가 없어요! 🎉'
                          : '외운 단어가 아직 없어요.',
                      style:
                          TextStyle(fontSize: 15.sp, color: AppColors.gray),
                    ),
                  ),
                )
              else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: (_index + 1) / total,
                  minHeight: 6.h,
                  backgroundColor: AppColors.fieldBg,
                  valueColor: AlwaysStoppedAnimation(AppColors.pink),
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: BouncyTap(
                  onTap: _flip,
                  scale: 0.98,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.softShadow(blur: 20, y: 6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showKorean ? '뜻' : '영어',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.hint,
                          ),
                        ),
                        SizedBox(height: 18.h),
                        Text(
                          _showKorean ? word!.korean : word!.english,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _showKorean ? 30.sp : 38.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        if (!_showKorean &&
                            word.pronunciation.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Text('[${word.pronunciation}]',
                              style: TextStyle(
                                  fontSize: 14.sp, color: AppColors.gray)),
                        ],
                        SizedBox(height: 14.h),
                        // 미국 발음 듣기 버튼.
                        // 누르는 즉시(onTapDown) 재생하고, 빈 onTap으로 탭을
                        // 이 버튼이 가져가 카드가 뒤집히지 않게 한다.
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => TtsService.speak(word.english),
                          onTap: () {},
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.blueSoft,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.volume_up_rounded,
                                    size: 18.sp, color: AppColors.pink),
                                SizedBox(width: 6.w),
                                Text('발음 듣기',
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.pink)),
                              ],
                            ),
                          ),
                        ),
                        if (_showKorean && word.example.isNotEmpty) ...[
                          SizedBox(height: 16.h),
                          Text(word.example,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  height: 1.4,
                                  color: AppColors.grayText)),
                        ],
                        SizedBox(height: 14.h),
                        Text(
                          _showKorean ? '카드를 탭하면 영어가 보여요' : '카드를 탭하면 뜻이 보여요',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.hint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundCardButton(
                    icon: Icons.close_rounded,
                    onTap: () => _advance(memorized: false),
                  ),
                  SizedBox(width: 20.w),
                  _RoundCardButton(
                    icon: Icons.check_rounded,
                    primary: true,
                    onTap: () => _advance(memorized: true),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 플래시카드 하단 원형 버튼: 헷갈려요(빨간 X) / 외웠어요(민트 체크).
class _RoundCardButton extends StatelessWidget {
  const _RoundCardButton({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 72.w,
        height: 72.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? null : AppColors.cream,
          gradient: primary ? AppColors.primaryButton : null,
          shape: BoxShape.circle,
          border: primary
              ? null
              : Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: (primary ? AppColors.mint : AppColors.navy)
                  .withValues(alpha: primary ? 0.4 : 0.12),
              blurRadius: primary ? 20 : 16,
              offset: Offset(0, primary ? 8 : 6),
            ),
          ],
        ),
        child: Icon(icon,
            size: 34.sp,
            color: primary ? Colors.white : AppColors.danger),
      ),
    );
  }
}
