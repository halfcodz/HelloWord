// 색을 AppColors에서 읽으므로 const로 만들지 않는다(테마 전환 시 다시 그리기 위해).
// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// HelloWord 마스코트: 몽실몽실 털 빵빵한 스케치 고양이(걷는 옆모습).
///
/// 먹색 선만 쓴다. 웹 로딩 화면(web/index.html)과
/// assets/images/cat.svg 의 그림과 같은 좌표(120 x 100)로 그린다.
/// [running]이면 네 다리로 실제로 걷는다.
class CatMascot extends StatefulWidget {
  CatMascot({super.key, this.size = 96, this.running = false});

  /// 가로 크기(세로는 100/120 비율).
  final double size;
  final bool running;

  @override
  State<CatMascot> createState() => _CatMascotState();
}

class _CatMascotState extends State<CatMascot>
    with SingleTickerProviderStateMixin {
  // 한 걸음(네 발을 한 번씩 딛는) 시간. 웹 로딩 화면(STEP)과 같다.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    if (widget.running) _c.repeat();
  }

  @override
  void didUpdateWidget(CatMascot old) {
    super.didUpdateWidget(old);
    if (widget.running && !_reduce && !_c.isAnimating) _c.repeat();
    if (!widget.running && _c.isAnimating) _c.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduce) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final walking = widget.running && !_reduce;
          return CustomPaint(
            size: Size(widget.size, widget.size * 100 / 120),
            painter: CatPainter(phase: walking ? _c.value : 0.1),
          );
        },
      ),
    );
  }
}

/// 고양이 그림 자체. 마스코트·로고·로딩에서 같이 쓴다.
///
/// 몽실몽실 털 빵빵한 스케치 고양이(걷는 옆모습). 털처럼 오돌토돌한 외곽선은
/// 아래 숫자 목록(시작점 + 2차 곡선 조각들)으로 그리고, 다리 네 개는
/// [phase](한 걸음 진행도 0~1)로 매번 계산해 실제로 걷는다.
/// 좌표·계산은 assets/images/cat.svg, web/index.html 과 같다(120 x 100).
class CatPainter extends CustomPainter {
  CatPainter({this.phase = 0.1});

  final double phase;

  // 마스코트는 모드와 상관없이 같은 색으로 그린다(로고처럼 보이도록).
  static const Color _ink = AppColors.onAccent;

  static const double _ground = 82;
  static const double _stride = 6;
  static const double _lift = 4;

  // 털 외곽선: [시작 x, 시작 y, (조절점 x, 조절점 y, 끝 x, 끝 y) ...].
  static const List<double> _tail = [
    34.6,
    47.0,
    32.0,
    45.4,
    30.3,
    46.9,
    28.7,
    44.7,
    26.9,
    45.8,
    26.1,
    43.4,
    24.2,
    44.0,
    24.2,
    41.5,
    22.2,
    41.5,
    22.9,
    38.9,
    21.0,
    38.3,
    22.5,
    35.7,
    21.0,
    34.4,
    23.3,
    31.4,
    22.6,
    29.3,
    22.9,
    25.5,
    20.6,
    23.4,
    17.5,
    23.6,
    15.4,
    26.7,
    12.9,
    29.7,
    13.5,
    31.8,
    11.6,
    35.4,
    12.8,
    37.7,
    12.0,
    41.6,
    13.8,
    43.5,
    14.2,
    47.3,
    16.5,
    48.7,
    18.1,
    52.3,
    20.8,
    52.9,
    23.6,
    55.9,
    26.6,
    55.7,
    30.4,
    57.9,
    33.4,
    57.0,
  ];
  static const List<double> _body = [
    82.0,
    55.0,
    83.4,
    58.4,
    80.0,
    61.1,
    79.4,
    64.6,
    74.4,
    66.3,
    71.9,
    69.7,
    65.9,
    69.8,
    61.7,
    72.7,
    56.0,
    71.0,
    50.3,
    72.7,
    46.1,
    69.8,
    40.1,
    69.7,
    37.6,
    66.3,
    32.6,
    64.6,
    32.0,
    61.1,
    28.6,
    58.4,
    30.0,
    55.0,
    28.6,
    51.6,
    32.0,
    48.9,
    32.6,
    45.4,
    37.6,
    43.7,
    40.1,
    40.3,
    46.1,
    40.2,
    50.3,
    37.3,
    56.0,
    39.0,
    61.7,
    37.3,
    65.9,
    40.2,
    71.9,
    40.3,
    74.4,
    43.7,
    79.4,
    45.4,
    80.0,
    48.9,
    83.4,
    51.6,
    82.0,
    55.0,
  ];
  static const List<double> _head = [
    99.3,
    31.7,
    102.6,
    33.7,
    102.4,
    37.5,
    104.6,
    40.6,
    102.9,
    44.0,
    103.7,
    47.8,
    100.7,
    50.2,
    100.0,
    54.0,
    96.3,
    55.0,
    94.1,
    58.2,
    90.3,
    57.7,
    87.0,
    59.7,
    83.7,
    57.7,
    79.9,
    58.2,
    77.7,
    55.0,
    74.0,
    54.0,
    73.3,
    50.2,
    70.3,
    47.8,
    71.1,
    44.0,
    69.4,
    40.6,
    71.6,
    37.5,
    71.4,
    33.7,
    74.7,
    31.7,
    75.4,
    24.4,
    76,
    17,
    79.0,
    21.9,
    82.1,
    26.8,
    87,
    23.5,
    91.9,
    26.8,
    95.0,
    21.6,
    98,
    16.5,
    98.6,
    24.1,
    99.3,
    31.7,
  ];

  static Path _fur(List<double> v) {
    final path = Path()..moveTo(v[0], v[1]);
    for (var i = 2; i + 3 < v.length; i += 4) {
      path.quadraticBezierTo(v[i], v[i + 1], v[i + 2], v[i + 3]);
    }
    return path..close();
  }

  static final Path _tailPath = _fur(_tail);
  static final Path _bodyPath = _fur(_body);
  static final Path _headPath = _fur(_head);

  /// 다리 하나: 엉덩이에서 발까지 살짝 굽은 짧은 선 + 앞으로 꺾인 발끝.
  static Path _leg(double hx, double hy, double p, bool front) {
    final s = p * 2 * math.pi;
    final fx = hx - _stride * math.cos(s); // 들린 동안 앞으로 나간다
    final fy = _ground - _lift * math.max(0, math.sin(s));
    final cx = (hx + fx) / 2 + (front ? -2 : 2);
    final cy = (hy + fy) / 2;
    return Path()
      ..moveTo(hx, hy)
      ..quadraticBezierTo(cx, cy, fx, fy)
      ..relativeLineTo(2.5, 0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120);

    Paint pen(double w, [double alpha = 1]) => Paint()
      ..color = _ink.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final main = pen(2.1);
    final fine = pen(1.5);
    final white = Paint()..color = Colors.white;
    final dot = Paint()..color = _ink;

    // 한 걸음에 두 번 살짝 들썩.
    final bob = 1.2 * math.sin(phase * 2 * math.pi).abs();
    final hy = 66 - bob;

    // 건너편 다리(옅게, 몸 뒤).
    final far = pen(2.4, 0.45);
    canvas.drawPath(_leg(47, hy, (phase + 0.5) % 1, false), far);
    canvas.drawPath(_leg(75, hy, (phase + 0.75) % 1, true), far);

    canvas.save();
    canvas.translate(0, -bob);
    for (final fur in [_tailPath, _bodyPath]) {
      canvas.drawPath(fur, white);
      canvas.drawPath(fur, main);
    }
    // 등 줄무늬(작은 ^ 세 개).
    final stripe = pen(1.7);
    for (final x in const [48.0, 56.0, 64.0]) {
      final y = x == 56 ? 42.0 : (x == 48 ? 44.0 : 43.0);
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..relativeQuadraticBezierTo(2, -3, 4, 0),
        stripe,
      );
    }
    canvas.drawPath(_headPath, white);
    canvas.drawPath(_headPath, main);
    // 이마 줄무늬.
    canvas.drawLine(const Offset(84.5, 29), const Offset(84.5, 32), fine);
    canvas.drawLine(const Offset(87.5, 28.5), const Offset(87.5, 31.5), fine);
    canvas.drawLine(const Offset(90.5, 29), const Offset(90.5, 32), fine);
    // 점 눈.
    canvas.drawCircle(const Offset(82.5, 40), 1.7, dot);
    canvas.drawCircle(const Offset(93.5, 39.5), 1.7, dot);
    // 코 + 입.
    canvas.drawPath(
      Path()
        ..moveTo(88, 43.5)
        ..relativeLineTo(-1.4, 1.4)
        ..relativeLineTo(2.8, 0)
        ..close(),
      dot,
    );
    canvas.drawPath(
      Path()
        ..moveTo(88, 45.2)
        ..relativeQuadraticBezierTo(-1.4, 2.2, -3, 1)
        ..moveTo(88, 45.2)
        ..relativeQuadraticBezierTo(1.4, 2.2, 3, 1),
      fine,
    );
    // 수염.
    canvas.drawLine(const Offset(103, 42), const Offset(109, 42), fine);
    canvas.drawLine(const Offset(103, 45.5), const Offset(108, 47.1), fine);
    canvas.restore();

    // 이쪽 다리(진하게, 몸 앞).
    final near = pen(2.4);
    canvas.drawPath(_leg(44, hy, phase, false), near);
    canvas.drawPath(_leg(72, hy, (phase + 0.25) % 1, true), near);

    canvas.restore();
  }

  @override
  bool shouldRepaint(CatPainter old) => old.phase != phase;
}

/// 고양이가 가운데 빈 곳을 입체적으로 뱅글뱅글 뛰어다니는 로딩 표시.
///
/// 가로로 긴 타원을 돌며 앞(아래)에선 크고 오른쪽을, 뒤(위)에선 작고
/// 왼쪽을 본다. 웹 로딩 화면(web/index.html)과 같은 계산이라
/// 넘어가도 이어져 보인다.
class CatLoader extends StatefulWidget {
  CatLoader({super.key, this.width = 130});

  /// 궤도 전체 폭(높이는 비율대로).
  final double width;

  @override
  State<CatLoader> createState() => _CatLoaderState();
}

class _CatLoaderState extends State<CatLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  )..repeat();

  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduce) _orbit.stop();
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * 90 / 130;
    final k = w / 130; // 웹 기준(130px)과의 배율
    final catW = 76 * k;
    return Semantics(
      label: '불러오는 중',
      child: SizedBox(
        width: w,
        height: h,
        child: AnimatedBuilder(
          animation: _orbit,
          builder: (context, _) {
            final th = _reduce
                ? math.pi / 2
                : -_orbit.value * 2 * math.pi + math.pi / 2;
            final sin = math.sin(th), cos = math.cos(th);
            final scale = 0.8 + 0.2 * sin; // 앞일수록 크게
            final facing = sin >= 0 ? 1.0 : -1.0; // 앞은 오른쪽, 뒤는 왼쪽
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: w / 2 + 22 * k * cos,
                  top: h / 2 + 7 * k * sin,
                  child: Opacity(
                    opacity: 0.75 + 0.25 * sin,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 0,
                        height: 0,
                        child: OverflowBox(
                          maxWidth: double.infinity,
                          maxHeight: double.infinity,
                          alignment: Alignment.topLeft,
                          child: Transform.translate(
                            offset: Offset(-catW / 2, -42 * k),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.flip(
                                  flipX: facing < 0,
                                  child: CatMascot(
                                    size: catW,
                                    running: !_reduce,
                                  ),
                                ),
                                // 발밑 그림자(웹: top 8px, 44 x 9).
                                Transform.translate(
                                  offset: Offset(0, -catW * 100 / 120 + 50 * k),
                                  child: Container(
                                    width: 44 * k,
                                    height: 9 * k,
                                    decoration: BoxDecoration(
                                      color: AppColors.onAccent.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 앱 로고: 버터 동그라미 안의 고양이.
class CatLogo extends StatelessWidget {
  CatLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: size * 0.06),
        child: CatMascot(size: size * 0.78),
      ),
    );
  }
}
