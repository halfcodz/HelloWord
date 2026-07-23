import 'package:flutter/material.dart';

/// 테두리·배경 없이 X를 직접 그리는 위젯.
/// (웹에서 Icons.close 계열 글리프가 비어 보이는 문제를 피하기 위함)
class XMark extends StatelessWidget {
  const XMark({
    super.key,
    required this.color,
    required this.size,
    this.strokeWidth = 2.6,
  });

  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _XPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _XPainter extends CustomPainter {
  _XPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w * 0.25, h * 0.25), Offset(w * 0.75, h * 0.75), p);
    canvas.drawLine(Offset(w * 0.75, h * 0.25), Offset(w * 0.25, h * 0.75), p);
  }

  @override
  bool shouldRepaint(_XPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
