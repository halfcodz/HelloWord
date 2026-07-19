import 'package:flutter/painting.dart';
import 'package:web/web.dart' as web;

/// 웹: 상태바(다이나믹 아일랜드 주변) 색을 테마에 맞게 바꾼다.
/// body 배경색과 theme-color 메타를 갱신한다.
void applyWebThemeColor(Color color) {
  final argb = color.toARGB32();
  final hex = '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  // html/body 배경(노치·카메라 영역이 이 색을 보여준다).
  (web.document.documentElement as web.HTMLElement?)?.style.backgroundColor =
      hex;
  web.document.body?.style.backgroundColor = hex;

  // theme-color 메타(iOS 상태바 틴트). 없으면 새로 만든다.
  var meta = web.document.querySelector('meta[name="theme-color"]');
  if (meta == null) {
    meta = web.document.createElement('meta');
    meta.setAttribute('name', 'theme-color');
    web.document.head?.appendChild(meta);
  }
  meta.setAttribute('content', hex);
}
