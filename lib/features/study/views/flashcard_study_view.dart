import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../services/memorized_store.dart';
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
  late List<WordPair> _words = List.of(widget.set.words);
  int _index = 0;
  bool _showKorean = false;
  int _memorized = 0;

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
      _words = List.of(widget.set.words)..shuffle();
      _index = 0;
      _showKorean = false;
      _memorized = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = _words[_index];
    final total = _words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1}/$total',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _shuffle,
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
                          _showKorean ? word.korean : word.english,
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
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => TtsService.speak(word.english),
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
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: _CardButton(
                      label: '아직 헷갈려요',
                      bg: AppColors.fieldBg,
                      fg: AppColors.grayText,
                      onTap: () => _advance(memorized: false),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _CardButton(
                      label: '외웠어요!',
                      bg: AppColors.pink,
                      fg: Colors.white,
                      onTap: () => _advance(memorized: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 15.sp, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}
