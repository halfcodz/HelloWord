import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_tap.dart';
import '../../../core/widgets/gradient_button.dart';
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
  bool _showEnglish = false;

  void _flip() => setState(() => _showEnglish = !_showEnglish);

  void _next() {
    if (_index < _words.length - 1) {
      setState(() {
        _index++;
        _showEnglish = false;
      });
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() {
        _index--;
        _showEnglish = false;
      });
    }
  }

  void _shuffle() {
    setState(() {
      _words = List.of(widget.set.words)..shuffle();
      _index = 0;
      _showEnglish = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = _words[_index];
    final total = _words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.set.title),
        actions: [
          IconButton(
            onPressed: _shuffle,
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: '섞기',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / total),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    Text('${_index + 1} / $total',
                        style: TextStyle(
                            fontSize: 14.sp, color: AppColors.lavender)),
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
                            gradient: _showEnglish
                                ? AppColors.primaryButton
                                : null,
                            color: _showEnglish ? null : Colors.white,
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: AppColors.softShadow(),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showEnglish ? '영어' : '뜻',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: _showEnglish
                                      ? Colors.white70
                                      : AppColors.lavender,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                _showEnglish ? word.english : word.korean,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30.sp,
                                  color: _showEnglish
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                _showEnglish ? '카드를 탭하면 뜻으로' : '카드를 탭하면 영어로',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: _showEnglish
                                      ? Colors.white70
                                      : AppColors.lavender,
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
                          child: OutlinedButton(
                            onPressed: _index > 0 ? _prev : null,
                            style: OutlinedButton.styleFrom(
                              shape: const StadiumBorder(),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              side: BorderSide(color: AppColors.pinkSoft),
                            ),
                            child: const Text('이전'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: _index < total - 1
                              ? GradientButton(
                                  label: '다음',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: _next,
                                )
                              : GradientButton(
                                  label: '완료',
                                  icon: Icons.check_rounded,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
