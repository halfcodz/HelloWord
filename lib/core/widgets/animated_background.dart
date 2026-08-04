import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 앱 전체 뒤에 깔리는, 천천히 움직이는 배경.
///
/// 단어 앱답게 알파벳 조각과 동글동글한 방울이 아주 느리게 떠다닌다.
/// 읽기를 방해하지 않도록 투명도를 낮게 유지하고, 프레임마다 다시 그리는
/// 범위는 [RepaintBoundary]로 배경에만 가둔다.
/// 시스템의 '동작 줄이기'가 켜져 있으면 움직임 없이 한 장면만 그린다.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // 한 바퀴 도는 데 60초. 시선을 끌지 않을 만큼 느리게.
    duration: const Duration(seconds: 60),
  );

  /// 글자는 한 번만 레이아웃해 두고 매 프레임 위치만 옮긴다.
  final List<TextPainter> _glyphs = [];
  bool _glyphsBuilt = false;

  @override
  void initState() {
    super.initState();
    _controller.repeat();
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
    _buildGlyphs();
  }

  void _buildGlyphs() {
    // 색이 모드에 따라 바뀌므로 다크/라이트 전환 때 다시 만든다.
    if (_glyphsBuilt && _glyphs.isNotEmpty) return;
    _glyphs.clear();
    const letters = ['A', 'B', 'C', 'W', 'o', 'r', 'd', '?'];
    for (var i = 0; i < letters.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: AppTheme.display(
            fontSize: 26 + (i % 3) * 6,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _glyphs.add(painter);
    }
    _glyphsBuilt = true;
  }

  @override
  void dispose() {
    _controller.dispose();
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
    // 배경이 매 프레임 다시 그려져도 화면 내용은 다시 그리지 않는다.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.background),
      child: AnimatedBuilder(
        animation: _controller,
        child: RepaintBoundary(
          child: widget.child ?? const SizedBox.shrink(),
        ),
        builder: (context, child) => CustomPaint(
          painter: _BackgroundPainter(
            t: _controller.value,
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

  /// 위로 흐르는 속도(한 바퀴에 화면 몇 배를 지나는지).
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
  _Floater(x: 0.14, y: 0.18, size: 120, speed: 0.35, drift: 0.05, phase: 0.0, tone: 0),
  _Floater(x: 0.82, y: 0.32, size: 150, speed: 0.28, drift: 0.06, phase: 0.35, tone: 1),
  _Floater(x: 0.30, y: 0.72, size: 130, speed: 0.32, drift: 0.04, phase: 0.6, tone: 2),
  _Floater(x: 0.72, y: 0.88, size: 110, speed: 0.4, drift: 0.05, phase: 0.15, tone: 0),
];

const List<_Floater> _bubbles = [
  _Floater(x: 0.08, y: 0.9, size: 7, speed: 1.0, drift: 0.03, phase: 0.05, tone: 0),
  _Floater(x: 0.22, y: 0.5, size: 5, speed: 1.3, drift: 0.04, phase: 0.4, tone: 1),
  _Floater(x: 0.42, y: 0.95, size: 9, speed: 0.9, drift: 0.02, phase: 0.7, tone: 2),
  _Floater(x: 0.58, y: 0.6, size: 6, speed: 1.15, drift: 0.05, phase: 0.2, tone: 0),
  _Floater(x: 0.76, y: 0.82, size: 8, speed: 1.05, drift: 0.03, phase: 0.55, tone: 1),
  _Floater(x: 0.9, y: 0.45, size: 5, speed: 1.35, drift: 0.04, phase: 0.85, tone: 2),
  _Floater(x: 0.5, y: 0.25, size: 6, speed: 1.2, drift: 0.03, phase: 0.3, tone: 0),
];

const List<_Floater> _letters = [
  _Floater(x: 0.12, y: 0.62, size: 1, speed: 0.55, drift: 0.03, phase: 0.1, tone: 0),
  _Floater(x: 0.86, y: 0.2, size: 1, speed: 0.5, drift: 0.04, phase: 0.45, tone: 1),
  _Floater(x: 0.34, y: 0.35, size: 1, speed: 0.6, drift: 0.02, phase: 0.75, tone: 2),
  _Floater(x: 0.68, y: 0.7, size: 1, speed: 0.52, drift: 0.03, phase: 0.25, tone: 0),
  _Floater(x: 0.2, y: 0.05, size: 1, speed: 0.58, drift: 0.04, phase: 0.9, tone: 1),
  _Floater(x: 0.55, y: 0.5, size: 1, speed: 0.48, drift: 0.03, phase: 0.6, tone: 2),
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
    for (final f in _blobs) {
      final center = _positionOf(f, size);
      final paint = Paint()
        // 다크에서는 색이 탁해 보이므로 라이트보다 더 옅게 깐다.
        ..color = _tone(f.tone).withValues(alpha: dark ? 0.09 : 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
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
    if (glyphs.isEmpty) return;
    for (var i = 0; i < _letters.length; i++) {
      final f = _letters[i];
      final glyph = glyphs[i % glyphs.length];
      final center = _positionOf(f, size);
      final fade = math.sin((center.dy / size.height) * math.pi).clamp(0.0, 1.0);
      final angle = math.sin((t + f.phase) * 2 * math.pi) * 0.2;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      // 글자는 흰색으로 그려 두고 여기서 색·투명도를 입힌다.
      canvas.saveLayer(
        Rect.fromCenter(
          center: Offset.zero,
          width: glyph.width * 2,
          height: glyph.height * 2,
        ),
        Paint(),
      );
      glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height / 2));
      canvas.drawColor(
        _tone(f.tone).withValues(alpha: (dark ? 0.28 : 0.2) * fade),
        BlendMode.srcIn,
      );
      canvas.restore();
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
