import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// 화면 가장자리에서 비워 두어야 하는 여백(노치·다이나믹 아일랜드·홈 인디케이터).
///
/// Flutter 웹 엔진은 CSS의 `env(safe-area-inset-*)`를 읽지 않아
/// `MediaQuery.padding`이 항상 0으로 온다. 사파리에서 그냥 열면 위아래를
/// 브라우저 막대가 차지하므로 티가 안 나지만, **홈 화면에 추가해서 쓰면**
/// 그 막대가 없어 화면 맨 아래까지 내용이 내려간다. 그 자리는 iOS가 홈
/// 인디케이터 제스처용으로 잡아 두는 구역이라, 거기 놓인 버튼은 눌러도
/// 반응하지 않거나 두 번 눌러야 한다(하단 탭바가 딱 이 경우였다).
///
/// 그래서 실제 값을 브라우저에서 직접 읽어 온다. 눈에 보이지 않는 0×0 요소에
/// `env(...)`를 padding으로 걸어 두고, 브라우저가 계산해 준 값을 읽는 방식이다.
EdgeInsets readSafeAreaInsets() {
  try {
    final style = web.window.getComputedStyle(_ensureProbe());
    return EdgeInsets.fromLTRB(
      _px(style.paddingLeft),
      _px(style.paddingTop),
      _px(style.paddingRight),
      _px(style.paddingBottom),
    );
  } catch (_) {
    // 읽지 못하면 여백 없이 두는 편이 안전하다(예전과 같은 화면).
    return EdgeInsets.zero;
  }
}

web.HTMLDivElement? _probe;

web.HTMLDivElement _ensureProbe() {
  final existing = _probe;
  if (existing != null && existing.isConnected) return existing;

  final div = web.HTMLDivElement()..id = 'safe-area-probe';
  div.style
    ..position = 'fixed'
    ..top = '0'
    ..left = '0'
    ..width = '0'
    ..height = '0'
    ..visibility = 'hidden'
    // 터치를 가로채지 않도록 확실히 빼 둔다.
    ..pointerEvents = 'none'
    ..paddingTop = 'env(safe-area-inset-top, 0px)'
    ..paddingRight = 'env(safe-area-inset-right, 0px)'
    ..paddingBottom = 'env(safe-area-inset-bottom, 0px)'
    ..paddingLeft = 'env(safe-area-inset-left, 0px)';
  web.document.body?.appendChild(div);
  _probe = div;
  return div;
}

/// "44px" → 44.0. 이상한 값이 오면 0으로 둔다.
double _px(String value) {
  final parsed = double.tryParse(value.replaceAll('px', '').trim());
  if (parsed == null || !parsed.isFinite || parsed <= 0) return 0;
  // 정상적인 기기라면 60을 넘지 않는다. 말도 안 되는 값이면 무시한다.
  return parsed > 200 ? 0 : parsed;
}
