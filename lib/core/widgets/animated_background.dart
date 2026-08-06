import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 앱 전체 뒤에 깔리는, 천천히 움직이는 배경.
///
/// 단어 앱답게 알파벳 조각과 동글동글한 방울이 아주 느리게 떠다닌다.
/// 읽기를 방해하지 않도록 투명도를 낮게 유지하고, 다시 그리는 범위는
/// [RepaintBoundary]로 배경에만 가둔다.
/// 시스템의 '동작 줄이기'가 켜져 있으면 움직임 없이 한 장면만 그린다.
///
/// 폰(특히 아이폰 사파리)에서 버벅이지 않도록 그리는 비용을 낮게 유지한다.
/// - 한 바퀴가 180초인 아주 느린 움직임이라 매 프레임 다시 그릴 이유가 없다.
///   초당 [_fps]번만 다시 그린다(눈으로는 차이가 없다).
/// - 큰 방울은 흐리기 필터(MaskFilter.blur) 대신 방사형 그라데이션으로 그린다.
///   흐리기는 화면 밖 버퍼를 한 번 더 만들기 때문에 훨씬 비싸다.
/// - 알파벳은 색을 미리 입혀 두고 그대로 찍는다. 예전에는 흰 글자를 그린 뒤
///   saveLayer로 색을 덮었는데, saveLayer도 매번 버퍼를 만드는 비싼 작업이다.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

/// 배경을 1초에 몇 번 다시 그릴지. 한 바퀴가 180초라 이 정도면 충분하다.
const int _fps = 10;

/// 한 바퀴(180초)를 이 개수로 쪼개 그 눈금에서만 다시 그린다.
const int _steps = 180 * _fps;

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // 한 바퀴 = 180초. 아래 요소들의 speed를 모두 정수로 두어
    // 한 바퀴가 끝나는 순간의 위치가 시작 위치와 정확히 같아진다.
    // (예전엔 speed가 소수라 한 바퀴마다 위치가 튀면서 뚝 끊겨 보였다.)
    duration: const Duration(seconds: 180),
  );

  /// 눈금으로 끊은 진행도. 값이 실제로 바뀔 때만 배경을 다시 그린다.
  /// (컨트롤러를 그대로 구독하면 초당 60번 다시 그리게 된다.)
  final ValueNotifier<double> _step = ValueNotifier(0);

  /// 글자는 한 번만 레이아웃해 두고 위치만 옮긴다.
  final List<TextPainter> _glyphs = [];
  bool _glyphsBuilt = false;
  bool _builtDark = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTick);
    _controller.repeat();
  }

  void _onTick() {
    final value = (_controller.value * _steps).floor() / _steps;
    if (value != _step.value) _step.value = value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 동작 줄이기 설정에 따라 애니메이션을 켜고 끈다.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
    _buildGlyphs(AppColors.isDark);
  }

  /// 글자에 색까지 미리 입혀 둔다. 그리는 쪽에서는 그대로 찍기만 하면 된다.
  /// 색이 모드에 따라 바뀌므로 다크/라이트가 바뀌면 다시 만든다.
  void _buildGlyphs(bool dark) {
    if (_glyphsBuilt && _builtDark == dark && _glyphs.isNotEmpty) return;
    _glyphs.clear();
    const letters = ['A', 'B', 'C', 'W', 'o', 'r', 'd', '?'];
    for (var i = 0; i < _letters.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: letters[i % letters.length],
          style: AppTheme.display(
            fontSize: 26 + (i % 3) * 6,
            fontWeight: FontWeight.w600,
            color: _toneOf(_letters[i].tone)
                .withValues(alpha: dark ? 0.24 : 0.17),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _glyphs.add(painter);
    }
    _glyphsBuilt = true;
    _builtDark = dark;
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    _step.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    // Stack이 아니라 CustomPaint에 자식을 물린다.
    // (Stack은 자식이 전부 Positioned면 '제약의 최대 크기'로 커져서, 높이가
    //  무한인 자리에 놓이면 그대로 터진다. CustomPaint는 예전 DecoratedBox처럼
    //  자식 크기에 맞춰지므로 어디에 놓아도 안전하다.)
    // painter는 자식보다 뒤에 그려지고, 자식은 RepaintBoundary로 감싸 두어
    // 배경이 다시 그려져도 화면 내용은 다시 그리지 않는다.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.background),
      child: AnimatedBuilder(
        animation: _step,
        child: RepaintBoundary(
          child: widget.child ?? const SizedBox.shrink(),
        ),
        builder: (context, child) => CustomPaint(
          painter: _BackgroundPainter(
            t: _step.value,
            dark: dark,
            primary: AppColors.pink,
            secondary: AppColors.purple,
            accent: AppColors.gold,
            glyphs: _glyphs,
          ),
          child: child,
        ),
      ),
    );
  }
}

Color _toneOf(int tone) => switch (tone) {
      1 => AppColors.purple,
      2 => AppColors.gold,
      _ => AppColors.pink,
    };

/// 배경에 떠다니는 요소 하나의 궤도 정보.
class _Floater {
  const _Floater({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.tone,
  });

  /// 화면 폭·높이 대비 기준 위치(0~1).
  final double x;
  final double y;

  /// 반지름(논리 픽셀 기준 배율).
  final double size;

  /// 위로 흐르는 속도. 한 바퀴(180초)에 화면을 몇 번 지나갈지.
  /// 반드시 정수로 둔다 — 그래야 한 바퀴가 끝날 때 위치가 딱 맞아
  /// 이어지는 지점이 보이지 않는다.
  final double speed;

  /// 좌우로 흔들리는 폭.
  final double drift;

  /// 시작 위상(요소끼리 겹치지 않게).
  final double phase;

  /// 0=파랑, 1=보라, 2=골드.
  final int tone;
}

// 손으로 배치한 궤도들. 난수를 쓰지 않아 매번 같은 화면이 나온다.
const List<_Floater> _blobs = [
  _Floater(x: 0.14, y: 0.18, size: 120, speed: 1, drift: 0.05, phase: 0.0, tone: 0),
  _Floater(x: 0.82, y: 0.32, size: 150, speed: 1, drift: 0.06, phase: 0.35, tone: 1),
  _Floater(x: 0.30, y: 0.72, size: 130, speed: 1, drift: 0.04, phase: 0.6, tone: 2),
  _Floater(x: 0.72, y: 0.88, size: 110, speed: 2, drift: 0.05, phase: 0.15, tone: 0),
];

const List<_Floater> _bubbles = [
  _Floater(x: 0.08, y: 0.9, size: 7, speed: 3, drift: 0.03, phase: 0.05, tone: 0),
  _Floater(x: 0.22, y: 0.5, size: 5, speed: 4, drift: 0.04, phase: 0.4, tone: 1),
  _Floater(x: 0.42, y: 0.95, size: 9, speed: 3, drift: 0.02, phase: 0.7, tone: 2),
  _Floater(x: 0.58, y: 0.6, size: 6, speed: 4, drift: 0.05, phase: 0.2, tone: 0),
  _Floater(x: 0.76, y: 0.82, size: 8, speed: 3, drift: 0.03, phase: 0.55, tone: 1),
  _Floater(x: 0.9, y: 0.45, size: 5, speed: 5, drift: 0.04, phase: 0.85, tone: 2),
  _Floater(x: 0.5, y: 0.25, size: 6, speed: 4, drift: 0.03, phase: 0.3, tone: 0),
];

const List<_Floater> _letters = [
  _Floater(x: 0.12, y: 0.62, size: 1, speed: 2, drift: 0.03, phase: 0.1, tone: 0),
  _Floater(x: 0.86, y: 0.2, size: 1, speed: 1, drift: 0.04, phase: 0.45, tone: 1),
  _Floater(x: 0.34, y: 0.35, size: 1, speed: 2, drift: 0.02, phase: 0.75, tone: 2),
  _Floater(x: 0.68, y: 0.7, size: 1, speed: 1, drift: 0.03, phase: 0.25, tone: 0),
  _Floater(x: 0.2, y: 0.05, size: 1, speed: 2, drift: 0.04, phase: 0.9, tone: 1),
  _Floater(x: 0.55, y: 0.5, size: 1, speed: 1, drift: 0.03, phase: 0.6, tone: 2),
];

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.t,
    required this.dark,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.glyphs,
  });

  final double t;
  final bool dark;
  final Color primary;
  final Color secondary;
  final Color accent;
  final List<TextPainter> glyphs;

  Color _tone(int tone) => switch (tone) {
        1 => secondary,
        2 => accent,
        _ => primary,
      };

  /// 요소가 아래에서 위로 흐르는 현재 위치(화면 밖으로 나가면 아래로 되돌아온다).
  Offset _positionOf(_Floater f, Size size) {
    final progress = (f.y - (t * f.speed) + f.phase) % 1.0;
    final wobble = math.sin((t + f.phase) * 2 * math.pi) * f.drift;
    return Offset((f.x + wobble) * size.width, progress * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1) 큰 방울: 아주 흐릿하게 깔아 배경에 색감만 남긴다.
    // 가장자리로 갈수록 투명해지는 방사형 그라데이션으로 흐린 느낌을 낸다.
    // (흐리기 필터는 그릴 때마다 화면 밖 버퍼를 만들어 폰에서 특히 비싸다.)
    for (final f in _blobs) {
      final center = _positionOf(f, size);
      // 다크에서는 색이 탁해 보이므로 라이트보다 더 옅게 깐다.
      final color = _tone(f.tone).withValues(alpha: dark ? 0.09 : 0.10);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.35, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: f.size));
      canvas.drawCircle(center, f.size, paint);
    }

    // 2) 작은 방울: 또렷하지만 아주 옅게.
    for (final f in _bubbles) {
      final center = _positionOf(f, size);
      // 위로 갈수록 사라지도록 투명도를 조절한다.
      final fade = math.sin((center.dy / size.height) * math.pi).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = _tone(f.tone)
            .withValues(alpha: (dark ? 0.3 : 0.22) * fade);
      canvas.drawCircle(center, f.size, paint);
    }

    // 3) 알파벳 조각: 단어 앱다운 장식. 살짝 기울여 떠다닌다.
    // 색은 글자를 만들 때 이미 입혀 두었으므로 그대로 찍기만 한다.
    if (glyphs.isEmpty) return;
    for (var i = 0; i < _letters.length && i < glyphs.length; i++) {
      final f = _letters[i];
      final glyph = glyphs[i];
      final center = _positionOf(f, size);
      final angle = math.sin((t + f.phase) * 2 * math.pi) * 0.2;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.t != t ||
      old.dark != dark ||
      old.primary != primary ||
      old.glyphs != glyphs;
}
