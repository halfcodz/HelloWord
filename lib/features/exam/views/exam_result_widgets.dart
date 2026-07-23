import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../word_sets/models/word_pair.dart';
import '../models/exam_answer.dart';

/// 맞은/틀린 개수와 점수를 크고 또렷하게 보여주는 배너. (언니·동생 공통)
class ExamScoreBanner extends StatelessWidget {
  const ExamScoreBanner({
    super.key,
    required this.score,
    required this.total,
    this.name,
  });

  final int score;
  final int total;
  final String? name;

  int get _wrong => (total - score).clamp(0, total);
  int get _points => total == 0 ? 0 : ((score / total) * 100).round();

  @override
  Widget build(BuildContext context) {
    final accent = _points >= 60 ? AppColors.mint : AppColors.danger;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: AppColors.softShadow(),
      ),
      child: Row(
        children: [
          ScoreRing(percent: _points, accent: accent, size: 92),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name != null) ...[
                  Text(name!,
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grayText)),
                  SizedBox(height: 10.h),
                ],
                _StatLine(
                    label: '맞음', value: score, color: AppColors.mint),
                SizedBox(height: 8.h),
                _StatLine(label: '틀림', value: _wrong, color: AppColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 시험 결과 카드 왼쪽에 놓는 점수 이모지 뱃지.
/// 점수에 따라 이모지와 배경색이 달라진다. (초록 네모 대체)
class ResultEmojiBadge extends StatelessWidget {
  const ResultEmojiBadge({super.key, required this.percent, this.size = 52});

  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String emoji;
    final Color bg;
    if (percent == 100) {
      emoji = '💯';
      bg = AppColors.blueSoft;
    } else if (percent >= 80) {
      emoji = '🎉';
      bg = AppColors.greenSoft;
    } else if (percent >= 60) {
      emoji = '😊';
      bg = AppColors.greenSoft;
    } else {
      emoji = '💪';
      bg = AppColors.dangerSoft;
    }
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(emoji, style: TextStyle(fontSize: (size * 0.46).sp)),
    );
  }
}

/// 말해보카풍 점수 링(민트 원형 게이지 + 가운데 점수).
class ScoreRing extends StatelessWidget {
  const ScoreRing(
      {super.key,
      required this.percent,
      required this.accent,
      this.size = 92});

  final int percent;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.w,
      height: size.w,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (percent / 100).clamp(0, 1).toDouble(),
          accent: accent,
          track: AppColors.border,
          stroke: size * 0.12,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$percent',
                  style: TextStyle(
                      fontSize: (size * 0.3).sp,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              Text('점',
                  style: TextStyle(
                      fontSize: (size * 0.13).sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color accent;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = LinearGradient(
        colors: [AppColors.mint, AppColors.mintEnd],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    if (progress < 1) {
      arcPaint.color = accent;
      arcPaint.shader = null;
      if (progress >= 0.6) {
        arcPaint.shader = LinearGradient(colors: [AppColors.mint, AppColors.mintEnd])
            .createShader(Rect.fromCircle(center: center, radius: radius));
      }
    }
    canvas.drawCircle(center, radius, trackPaint);
    const start = -1.5707963267948966; // -90도
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
        6.283185307179586 * progress, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _StatLine extends StatelessWidget {
  const _StatLine(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Text(label,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.grayText)),
        SizedBox(width: 8.w),
        Text('$value개',
            style: TextStyle(
                fontSize: 20.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// 문항별 정오답 복기 리스트. 틀린 문항을 위로 모아 먼저 보여준다. (언니·동생 공통)
class ExamReviewList extends StatelessWidget {
  const ExamReviewList({
    super.key,
    required this.words,
    required this.resolve,
    this.sourceTitle,
    this.padding,
  });

  final List<WordPair> words;
  final ExamAnswer? Function(int index) resolve;

  /// 이 시험(단어 세트)의 이름. 틀린 문항에 '어디서 틀렸는지'로 표시.
  final String? sourceTitle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    // (문항, 정오답)으로 묶어 틀린 것 먼저 → 맞은 것 순으로 정렬.
    final entries = <_ReviewEntry>[];
    for (var i = 0; i < words.length; i++) {
      final a = resolve(i);
      entries.add(_ReviewEntry(
        number: i + 1,
        word: words[i],
        submitted: a?.submitted ?? '',
        correct: a?.correct == true,
      ));
    }
    entries.sort((x, y) {
      if (x.correct == y.correct) return x.number.compareTo(y.number);
      return x.correct ? 1 : -1; // 틀린 것(false)이 먼저
    });

    final wrongCount = entries.where((e) => !e.correct).length;
    final children = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      // 틀린 그룹과 맞은 그룹 사이에 구분 라벨.
      if (i == 0 && wrongCount > 0) {
        children.add(_GroupLabel(text: '틀린 문제 $wrongCount개', color: AppColors.danger));
      }
      if (i == wrongCount && wrongCount < entries.length) {
        children.add(_GroupLabel(
            text: '맞은 문제 ${entries.length - wrongCount}개',
            color: AppColors.green));
      }
      children.add(ExamReviewRow(
        number: e.number,
        word: e.word,
        submitted: e.submitted,
        correct: e.correct,
        source: e.correct ? null : sourceTitle,
      ));
      children.add(SizedBox(height: 8.h));
    }

    return ListView(
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
      children: children,
    );
  }
}

class _ReviewEntry {
  _ReviewEntry({
    required this.number,
    required this.word,
    required this.submitted,
    required this.correct,
  });
  final int number;
  final WordPair word;
  final String submitted;
  final bool correct;
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 2.h, left: 2.w),
      child: Text(text,
          style: TextStyle(
              fontSize: 13.sp, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class ExamReviewRow extends StatelessWidget {
  const ExamReviewRow({
    super.key,
    required this.number,
    required this.word,
    required this.submitted,
    required this.correct,
    this.source,
  });

  final int number;
  final WordPair word;
  final String submitted;
  final bool correct;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.green : AppColors.danger;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
            color: correct ? AppColors.border : AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel,
              color: color, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${word.korean}  ·  ${word.english}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                SizedBox(height: 3.h),
                if (correct)
                  Text('입력한 답: $submitted',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.gray))
                else
                  AnswerDiffText(
                      correct: word.quizAnswer, submitted: submitted),
                if (source != null && source!.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 12.sp, color: AppColors.hint),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text('출처: $source',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.sp, color: AppColors.hint)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 제출한 답을 정답과 글자 단위로 비교해, 틀린(어긋난) 글자만 빨간색으로 보여준다.
/// 한 줄 인라인 표시. (실시간 감독 화면·결과 화면 공통)
/// 예) 정답 apple, 입력 appre → 'r'만 빨간색.
class SpellDiffText extends StatelessWidget {
  const SpellDiffText({
    super.key,
    required this.correct,
    required this.submitted,
    this.fontSize,
    this.baseColor,
  });

  final String correct;
  final String submitted;
  final double? fontSize;

  /// 맞은 글자 색(기본: grayText).
  final Color? baseColor;

  @override
  Widget build(BuildContext context) {
    final size = fontSize ?? 14.sp;
    if (submitted.isEmpty) {
      return Text('(빈칸)',
          style: TextStyle(
              fontSize: size,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              color: AppColors.danger));
    }
    final matched = matchedChars(correct, submitted);
    final base = baseColor ?? AppColors.grayText;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        for (var i = 0; i < submitted.length; i++)
          TextSpan(
            text: submitted[i],
            style: TextStyle(
              fontSize: size,
              fontWeight: matched[i] ? FontWeight.w600 : FontWeight.w800,
              color: matched[i] ? base : AppColors.danger,
            ),
          ),
      ]),
    );
  }
}

/// 제출한 답을 정답과 비교해 '내 답(틀린 글자 빨강) / 정답' 두 줄로 보여준다.
class AnswerDiffText extends StatelessWidget {
  const AnswerDiffText({
    super.key,
    required this.correct,
    required this.submitted,
  });

  final String correct;
  final String submitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('내 답 ',
                style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
            Flexible(
              child: SpellDiffText(
                  correct: correct, submitted: submitted, fontSize: 13.sp),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Text('정답 ',
                style: TextStyle(fontSize: 13.sp, color: AppColors.gray)),
            Flexible(
              child: Text(correct,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green)),
            ),
          ],
        ),
      ],
    );
  }
}

/// 제출한 각 글자가 정답과 맞아떨어지는지(LCS 기준) 여부.
/// 대소문자는 무시하고 위치가 아닌 최장공통부분수열로 정렬해 비교한다.
List<bool> matchedChars(String correct, String submitted) {
  final a = correct.toLowerCase();
  final b = submitted.toLowerCase();
  final n = a.length, m = b.length;
  final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      if (a[i] == b[j]) {
        dp[i][j] = dp[i + 1][j + 1] + 1;
      } else {
        dp[i][j] = dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
      }
    }
  }
  final matched = List.filled(m, false);
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      matched[j] = true;
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return matched;
}
