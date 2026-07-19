import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../word_sets/models/word_pair.dart';
import '../../word_sets/models/word_set.dart';

/// 혼자 보는 연습 시험. 뜻을 보고 영어를 직접 입력해 스스로 채점한다.
class SelfQuizView extends StatefulWidget {
  const SelfQuizView({super.key, required this.set});

  final WordSet set;

  @override
  State<SelfQuizView> createState() => _SelfQuizViewState();
}

class _SelfQuizViewState extends State<SelfQuizView> {
  final _controller = TextEditingController();
  late final List<WordPair> _words = List.of(widget.set.words)..shuffle();
  int _index = 0;
  bool _checked = false;
  bool _correct = false;
  int _score = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_checked || _controller.text.trim().isEmpty) return;
    final answer = _controller.text.trim().toLowerCase();
    final expected = _words[_index].english.trim().toLowerCase();
    setState(() {
      _correct = answer == expected;
      if (_correct) _score++;
      _checked = true;
    });
  }

  void _next() {
    if (_index < _words.length - 1) {
      setState(() {
        _index++;
        _checked = false;
        _correct = false;
        _controller.clear();
      });
    } else {
      setState(() => _index = _words.length); // 결과 화면으로
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _words.length) {
      return _ResultScaffold(score: _score, total: _words.length);
    }

    final word = _words[_index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.set.title)),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / _words.length),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    Text('${_index + 1} / ${_words.length}',
                        style: TextStyle(
                            fontSize: 14.sp, color: AppColors.lavender)),
                    SizedBox(height: 24.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 36.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: AppColors.softShadow(),
                      ),
                      child: Column(
                        children: [
                          Text('이 뜻의 영어 단어는?',
                              style: TextStyle(
                                  fontSize: 13.sp, color: AppColors.lavender)),
                          SizedBox(height: 14.h),
                          Text(word.korean,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 30.sp, color: AppColors.ink)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      enabled: !_checked,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _check(),
                      decoration: const InputDecoration(
                        labelText: '영어로 입력',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_checked) ...[
                      SizedBox(height: 16.h),
                      _Feedback(correct: _correct, answer: word.english),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: _checked
                    ? GradientButton(
                        label: _index < _words.length - 1 ? '다음' : '결과 보기',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _next,
                      )
                    : GradientButton(
                        label: '확인',
                        icon: Icons.check_rounded,
                        onPressed: _check,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.answer});

  final bool correct;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final color =
        correct ? AppColors.green : Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              correct ? '정답이에요! 🎉' : '정답: $answer',
              style: TextStyle(fontSize: 15.sp, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultScaffold extends StatelessWidget {
  const _ResultScaffold({required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: TextStyle(fontSize: 72.sp)),
                SizedBox(height: 16.h),
                Text('연습 완료!',
                    style: TextStyle(fontSize: 24.sp, color: AppColors.ink)),
                SizedBox(height: 16.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButton,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: AppColors.softShadow(),
                  ),
                  child: Text('$score / $total 개 맞았어요',
                      style: TextStyle(fontSize: 22.sp, color: Colors.white)),
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  width: 200.w,
                  child: GradientButton(
                    label: '완료',
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
