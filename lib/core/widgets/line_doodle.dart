// 색을 AppColors에서 읽으므로 const로 만들지 않는다(테마 전환 시 다시 그리기 위해).
// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 버터노트의 라인 드로잉: 펼친 노트 + 연필 + 말풍선 속 "A".
///
/// 먹색 선(끝 둥글게)과 버터 채움 한 덩어리로만 그린다.
/// 그림 자체는 정보가 없으므로 스크린리더에서는 숨긴다.
class LineDoodle extends StatelessWidget {
  LineDoodle({super.key, this.size = 88, this.onAccent = false});

  /// 가로 크기(세로는 비율대로).
  final double size;

  /// 버터 블록 위에 놓일 때 true. 선은 먹색, 채움은 흰색으로 바꾼다.
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size, size * 0.82),
        painter: _DoodlePainter(
          line: onAccent ? AppColors.onAccent : AppColors.ink,
          fill: onAccent ? Colors.white : AppColors.accent,
          paper: onAccent ? Colors.white : AppColors.cream,
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter({required this.line, required this.fill, required this.paper});

  final Color line;
  final Color fill;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    // 100 x 82 좌표계로 그리고 크기에 맞춰 늘린다.
    final s = size.width / 100;
    canvas.scale(s);
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..color = fill;
    final paperPaint = Paint()..color = paper;

    // 뒤에 깔리는 둥근 방울(채움 한 덩어리).
    canvas.drawCircle(const Offset(36, 50), 26, fillPaint);

    // 펼친 노트.
    final book = Path()
      ..moveTo(10, 46)
      ..quadraticBezierTo(26, 40, 46, 48)
      ..lineTo(46, 76)
      ..quadraticBezierTo(26, 68, 10, 74)
      ..close()
      ..moveTo(46, 48)
      ..quadraticBezierTo(66, 40, 82, 46)
      ..lineTo(82, 74)
      ..quadraticBezierTo(66, 68, 46, 76)
      ..close();
    canvas.drawPath(book, paperPaint);
    canvas.drawPath(book, stroke);
    // 노트 줄.
    for (final y in [54.0, 61.0]) {
      canvas.drawLine(Offset(16, y), Offset(39, y + 1.5), stroke);
      canvas.drawLine(Offset(53, y + 1.5), Offset(76, y), stroke);
    }

    // 말풍선 + "A".
    final bubble = RRect.fromRectAndRadius(
      const Rect.fromLTWH(54, 6, 30, 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(bubble, paperPaint);
    canvas.drawRRect(bubble, stroke);
    canvas.drawLine(const Offset(60, 29), const Offset(56, 36), stroke);
    final a = Path()
      ..moveTo(63, 24)
      ..lineTo(69, 11)
      ..lineTo(75, 24)
      ..moveTo(65.5, 19)
      ..lineTo(72.5, 19);
    canvas.drawPath(a, stroke);

    // 연필(비스듬히).
    canvas.save();
    canvas.translate(88, 36);
    canvas.rotate(math.pi / 5);
    final pencil = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-4, 0, 8, 26),
      const Radius.circular(2),
    );
    canvas.drawRRect(pencil, fillPaint);
    canvas.drawRRect(pencil, stroke);
    final tip = Path()
      ..moveTo(-4, 26)
      ..lineTo(0, 33)
      ..lineTo(4, 26);
    canvas.drawPath(tip, stroke);
    canvas.drawLine(const Offset(-4, 5), const Offset(4, 5), stroke);
    canvas.restore();

    // 반짝이 두 개.
    canvas.drawLine(const Offset(14, 22), const Offset(14, 30), stroke);
    canvas.drawLine(const Offset(10, 26), const Offset(18, 26), stroke);
    canvas.drawCircle(const Offset(28, 14), 1.6, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_DoodlePainter old) =>
      old.line != line || old.fill != fill || old.paper != paper;
}
