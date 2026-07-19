import 'package:flutter/painting.dart';
import 'package:web/web.dart' as web;

/// 웹: 상태바(다이나믹 아일랜드 주변) 색을 테마에 맞게 바꾼다.
/// body 배경색과 theme-color 메타를 갱신한다.
void applyWebThemeColor(Color color) {
  final argb = color.toARGB32();
  final hex = '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  final body = web.document.body;
  if (body != null) body.style.backgroundColor = hex;

  final meta = web.document.querySelector('meta[name="theme-color"]');
  if (meta != null) meta.setAttribute('content', hex);
}
