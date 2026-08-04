import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 누르면 살짝 작아졌다 통통 돌아오는 탭 애니메이션 래퍼.
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    // 0.96보다 작게 누르면 과장돼 보인다.
    this.scale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 투명한 여백까지 탭이 잡히도록 opaque로 히트 영역을 넓힌다.
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
